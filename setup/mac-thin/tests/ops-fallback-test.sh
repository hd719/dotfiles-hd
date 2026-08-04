#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$TEST_DIR/../../.." && pwd -P)"
TEST_REPORT_ROOT="$(mktemp -d -t ops-fallback-test.XXXXXX)"
trap '/bin/rm -rf "$TEST_REPORT_ROOT"' EXIT

export OPS_FALLBACK_SOURCE_ONLY=1
export OPS_FALLBACK_REPORT_DIR="$TEST_REPORT_ROOT"
# shellcheck source=../ops-fallback.sh
source "$REPO_ROOT/setup/mac-thin/ops-fallback.sh"

fail() {
  printf 'FAIL  %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS  %s\n' "$1"
}

python_blocks="$TEST_REPORT_ROOT/python-blocks"
/bin/mkdir -p "$python_blocks"
/usr/bin/awk -v destination="$python_blocks" '
  /<<'"'"'PY'"'"'/ { block += 1; capture = 1; next }
  capture && $0 == "PY" { capture = 0; next }
  capture { print > (destination "/block-" block ".py") }
' "$REPO_ROOT/setup/mac-thin/ops-fallback.sh"
for python_block in "$python_blocks"/*.py; do
  /usr/bin/python3 -m py_compile "$python_block" || fail "embedded Python syntax"
done
pass "embedded Python syntax"

personal_ready_body="$(
  /usr/bin/awk '/^run_personal_ready\(\)/,/^}/' \
    "$REPO_ROOT/setup/mac-thin/ops-fallback.sh"
)"
printf '%s\n' "$personal_ready_body" \
  | /usr/bin/grep -Fq 'capture "$BREW_BIN" update' \
  || fail "personal readiness must run brew update"
printf '%s\n' "$personal_ready_body" \
  | /usr/bin/grep -Fq 'HOMEBREW_NO_AUTO_UPDATE=1 "$BREW_BIN" upgrade' \
  || fail "personal readiness must run brew upgrade"
update_line="$(printf '%s\n' "$personal_ready_body" | /usr/bin/grep -nF 'capture "$BREW_BIN" update' | /usr/bin/cut -d: -f1)"
upgrade_line="$(printf '%s\n' "$personal_ready_body" | /usr/bin/grep -nF 'HOMEBREW_NO_AUTO_UPDATE=1 "$BREW_BIN" upgrade' | /usr/bin/cut -d: -f1)"
((update_line < upgrade_line)) || fail "brew update must run before brew upgrade"
[[ "$personal_ready_body" != *outdated_count* ]] \
  || fail "Homebrew upgrade must not be conditional on outdated output"
pass "unconditional Homebrew update and upgrade contract"

exact_reply OK OK || fail "exact model reply should pass"
if exact_reply 'OK ' OK; then
  fail "model reply with extra text should fail"
fi
pass "exact model reply contract"

validate_away_window '' '' || fail "empty away window should pass"
validate_away_window 2026-08-10 2026-08-17 || fail "ordered away window should pass"
if validate_away_window 2026-08-17 2026-08-10; then
  fail "reversed away window should fail"
fi
if validate_away_window 2026-02-30 2026-03-01; then
  fail "invalid calendar date should fail"
fi
pass "away-window validation"

canonical_output=$'postgresql@17 started\n127.0.0.1:5432 - accepting connections\n123 /opt/homebrew/var/postgresql@17/postgres'
classify_postgres_ownership "$canonical_output" || fail "canonical PostgreSQL owner should pass"
if classify_postgres_ownership "$canonical_output .pg0/instances/spartan"; then
  fail "pg0 owner should fail"
fi
pass "PostgreSQL ownership gate"

reset_results
add_result PASS core "Core" "ok" "None"
[[ "$(home_lab_overall)" == READY ]] || fail "all-pass readiness should be READY"
add_result WARN secondary "Secondary" "warning" "Inspect"
[[ "$(home_lab_overall)" == 'READY WITH WARNINGS' ]] || fail "warning readiness classification"
add_result FAIL core "Core failure" "down" "Recover"
[[ "$(home_lab_overall)" == 'NOT READY' ]] || fail "core failure readiness classification"
pass "readiness aggregation"

hermes_release_payload=""
ssh_bash_capture() {
  hermes_release_payload="$(/bin/cat)"
  LAST_STATUS=0
  LAST_OUTPUT='reviewed=v2026.7.30 installed=v2026.7.30 official_latest=v2026.8.3 report_only=yes'
}
reset_results
MAC_HOST=mac-mini-ts
check_hermes_release_pin
[[ "${RESULT_STATUS[0]}" == PASS ]] || fail "reviewed Hermes release should pass"
[[ "${RESULT_EVIDENCE[0]}" == *"report_only=yes"* ]] \
  || fail "newer official release should remain report-only"
[[ "$hermes_release_payload" == *"hermes-reviewed-stable.json"* ]] \
  || fail "Hermes release check should read the deployed manifest"
[[ "$hermes_release_payload" == *"rev-parse HEAD"* && "$hermes_release_payload" == *"version_string"* ]] \
  || fail "Hermes release check should verify commit and version"
pass "reviewed Hermes release manifest contract"

ssh_capture() {
  local payload="$2"
  LAST_OUTPUT=""
  if [[ "$payload" == *forgejo-truenas-ts* ]]; then
    LAST_STATUS=1
  else
    LAST_STATUS=0
  fi
}
reset_results
if check_ubuntu_forgejo_routes ubuntu-vm-ts; then
  fail "blocked Tailscale Forgejo route should fail"
fi
[[ "${RESULT_AREA[0]}" == "Forgejo Tailscale Git" ]] \
  || fail "Forgejo route failure area"
[[ "${RESULT_EVIDENCE[0]}" == *"LAN authenticates"* ]] \
  || fail "Forgejo route failure evidence"
[[ "${RESULT_NEXT[0]}" == *"tag:ubuntu-dev"* ]] \
  || fail "Forgejo route ACL guidance"
pass "Forgejo Tailscale ACL diagnosis"

# Replace live checks with deterministic fixtures and exercise report generation.
select_mac_host() {
  MAC_HOST=""
  add_result PASS core "Tailscale SSH" "fixture reachable" "None"
}
check_runtime() { add_result PASS core "Cortana Services" "fixture healthy" "None"; }
check_postgres() { add_result PASS core "PostgreSQL" "fixture healthy" "None"; }
check_hermes() { add_result PASS core "Hermes" "fixture healthy" "None"; }
check_queues_and_delivery() { add_result PASS core "Queues" "fixture empty" "None"; }
check_tailscale() { add_result PASS core "Tailscale" "fixture healthy" "None"; }
check_truenas() { add_result PASS core "TrueNAS" "fixture healthy" "None"; }
check_home_assistant() { add_result PASS core "Home Assistant" "fixture healthy" "None"; }
check_secondary_providers() { add_result PASS secondary "Providers" "fixture healthy" "None"; }

run_home_lab_ready 2026-08-10 2026-08-17 >/dev/null
report="$(find "$TEST_REPORT_ROOT" -type f -name 'home-lab-readiness-*-manual.md' -print -quit)"
[[ -n "$report" ]] || fail "manual readiness report was not created"
grep -Fq -- '- Invocation: Manual fallback CLI' "$report" || fail "manual invocation marker missing"
grep -Fq -- '- Overall: READY' "$report" || fail "fixture report should be READY"
grep -Fq -- '- Away window: 2026-08-10 to 2026-08-17' "$report" || fail "away window missing"
pass "manual readiness report"

mock_ownership_calls=0
mock_payloads=()
ssh_capture() {
  local payload="$2"
  mock_payloads[${#mock_payloads[@]}]="$payload"
  LAST_STATUS=0
  LAST_OUTPUT=""
  if [[ "$payload" == *'brew services list | grep'* ]]; then
    mock_ownership_calls=$((mock_ownership_calls + 1))
    if ((mock_ownership_calls == 1)); then
      LAST_OUTPUT=$'postgresql@17 stopped\n127.0.0.1:5432 - accepting connections\n321 /Users/h/.pg0/instances/spartan/postgres'
    else
      LAST_OUTPUT="$canonical_output"
    fi
  fi
}
reset_results
MAC_HOST=mac-mini-ts
recover_postgres_if_needed || fail "known pg0 conflict should recover"
[[ "$POSTGRES_OWNERSHIP_OK" == 1 ]] || fail "PostgreSQL gate should pass after recovery"
[[ "${#RECOVERY_ACTIONS[@]}" == 3 ]] || fail "known pg0 recovery should record three actions"
printf '%s\n' "${mock_payloads[@]}" | grep -Fq 'hindsight-embed -p spartan daemon stop' \
  || fail "pg0 recovery should use the supported Hindsight stop"
printf '%s\n' "${mock_payloads[@]}" | grep -Fq 'brew services start postgresql@17' \
  || fail "pg0 recovery should start canonical PostgreSQL"
pass "known PostgreSQL/pg0 recovery branch"

mock_runtime_status_calls=0
ssh_capture() {
  local payload="$2"
  LAST_STATUS=0
  LAST_OUTPUT=""
  if [[ "$payload" == *'runtime:status'* ]]; then
    mock_runtime_status_calls=$((mock_runtime_status_calls + 1))
    if ((mock_runtime_status_calls == 1)); then
      LAST_OUTPUT='[ERROR] service stopped'
    else
      LAST_OUTPUT='Doctor passed'
    fi
  fi
}
reset_results
MAC_HOST=mac-mini-ts
recover_cortana_if_needed || fail "stopped Cortana runtime should recover"
[[ "${#RECOVERY_ACTIONS[@]}" == 1 ]] || fail "Cortana recovery should record runtime:start"
pass "known Cortana start branch"

ssh_capture() {
  local payload="$2"
  LAST_OUTPUT=""
  if [[ "$payload" == *'gateway status' ]]; then
    LAST_STATUS=1
  else
    LAST_STATUS=0
  fi
}
reset_results
MAC_HOST=mac-mini-ts
recover_hermes_if_needed || fail "stopped Hermes gateways should recover"
[[ "${#RECOVERY_ACTIONS[@]}" == 3 ]] || fail "Hermes recovery should record each gateway start"
pass "known Hermes start branches"

printf 'ops-fallback tests passed.\n'
