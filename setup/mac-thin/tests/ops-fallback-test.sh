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

module_files=(
  "$REPO_ROOT/setup/mac-thin/ops-fallback.sh"
  "$REPO_ROOT/setup/mac-thin/ops-fallback/lib/"*.sh
  "$REPO_ROOT/setup/mac-thin/ops-fallback/commands/"*.sh
  "$REPO_ROOT/setup/mac-thin/ops-fallback/checks/"*.sh
)
for module_file in "${module_files[@]}"; do
  /bin/bash -n "$module_file" || fail "Bash syntax: $module_file"
done
if /usr/bin/grep -R -E "PYTHON_BIN|ssh_python_capture|<<'PY'" \
  "$REPO_ROOT/setup/mac-thin/ops-fallback.sh" \
  "$REPO_ROOT/setup/mac-thin/ops-fallback" >/dev/null; then
  fail "fallback-owned logic must not embed Python"
fi
pass "modular Bash syntax and no embedded Python"

personal_ready_body="$(
  /usr/bin/awk '/^run_personal_ready\(\)/,/^}/' \
    "$REPO_ROOT/setup/mac-thin/ops-fallback/commands/personal-ready.sh"
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

printf '%s\n' "$personal_ready_body" \
  | /usr/bin/grep -Fq 'run_personal_mac_mini_updates' \
  || fail "personal readiness must run Mac mini goodMorning"
printf '%s\n' "$personal_ready_body" \
  | /usr/bin/grep -Fq 'personal_is_ready' \
  || fail "personal readiness must return its aggregate readiness status"
mac_mini_update_body="$(
  /usr/bin/awk '/^run_personal_mac_mini_updates\(\)/,/^}/' \
    "$REPO_ROOT/setup/mac-thin/ops-fallback/commands/personal-ready.sh"
)"
[[ "$mac_mini_update_body" == *mac-mini-ts* && "$mac_mini_update_body" == *mac-mini-lan* ]] \
  || fail "Mac mini update lane must retain Tailscale and LAN routes"
[[ "$mac_mini_update_body" == *goodMorning* ]] \
  || fail "Mac mini update lane must invoke goodMorning"
pass "Mac mini goodMorning fallback contract"

mac_mini_calls=()
ssh_capture() {
  local host="$1"
  local payload="$2"
  mac_mini_calls[${#mac_mini_calls[@]}]="$host|$payload"
  LAST_OUTPUT=""
  if [[ "$host" == "mac-mini-ts" && "$payload" == true ]]; then
    LAST_STATUS=1
  else
    LAST_STATUS=0
  fi
}
reset_results
run_personal_mac_mini_updates || fail "Mac mini LAN fallback should complete"
[[ "${mac_mini_calls[*]}" == \
  'mac-mini-ts|true mac-mini-lan|true mac-mini-lan|zsh -lic "_goodmorning_sync_dotfiles" mac-mini-lan|zsh -lic "goodMorning --updates-only"' ]] \
  || fail "Mac mini update lane should try Tailscale before LAN"
[[ "${RESULT_STATUS[0]}" == WARN && "${RESULT_STATUS[1]}" == PASS ]] \
  || fail "Mac mini LAN fallback should be a note with a passing update"
pass "Mac mini goodMorning LAN fallback"

mac_mini_calls=()
ssh_capture() {
  local host="$1"
  local payload="$2"
  mac_mini_calls[${#mac_mini_calls[@]}]="$host|$payload"
  LAST_OUTPUT=""
  if [[ "$payload" == *"goodMorning --updates-only"* ]]; then
    LAST_STATUS=1
  else
    LAST_STATUS=0
  fi
}
reset_results
if run_personal_mac_mini_updates; then
  fail "failed Mac mini maintenance should return nonzero"
fi
[[ "${mac_mini_calls[*]}" != *mac-mini-lan* ]] \
  || fail "failed maintenance must not replay through LAN"
goodmorning_calls="$(printf '%s\n' "${mac_mini_calls[@]}" | /usr/bin/grep -c 'goodMorning --updates-only')"
[[ "$goodmorning_calls" == 1 ]] || fail "Mac mini maintenance should run exactly once"
[[ "${RESULT_STATUS[0]}" == FAIL ]] || fail "failed Mac mini maintenance should be reported"
pass "Mac mini failure is not replayed"

reset_results
add_result PASS thin-mac "Thin Mac" "ready" "None"
personal_is_ready || fail "all-pass personal readiness should return success"
add_result FAIL ubuntu-vm "Ubuntu updater" "failed" "Rerun updater"
if personal_is_ready; then
  fail "a failed personal check should return nonzero"
fi
reset_results
add_result WARN ubuntu-vm "Ubuntu reboot" "required" "Restart VM"
if personal_is_ready; then
  fail "a required Ubuntu reboot should return nonzero"
fi
reset_results
add_result WARN thin-mac "Thin-Mac disk" "review soon" "Inspect storage"
personal_is_ready || fail "an ordinary personal note should stay nonblocking"
pass "personal readiness exit contract"

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

z_epoch="$(iso8601_to_epoch 2026-08-04T12:34:56.789Z)"
offset_epoch="$(iso8601_to_epoch 2026-08-04T08:34:56-04:00)"
[[ "$z_epoch" == "$offset_epoch" ]] || fail "equivalent ISO-8601 offsets should match"
[[ "$(epoch_to_iso8601 "$z_epoch")" == 2026-08-04T12:34:56+00:00 ]] \
  || fail "epoch should format as canonical UTC"
pass "Bash-only ISO-8601 helpers"

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
if home_lab_is_ready; then
  fail "core failure should return nonzero"
fi
reset_results
add_result FAIL secondary "Secondary failure" "reauth" "Repair manually"
home_lab_is_ready || fail "secondary failure should stay nonblocking"
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

remote_report_body=""
ssh_capture() {
  local payload="$2"
  LAST_STATUS=0
  if [[ "$payload" == 'date +%F' ]]; then
    LAST_OUTPUT=2026-08-04
  else
    LAST_OUTPUT=""
  fi
}
capture_with_input() {
  remote_report_body="$1"
  LAST_STATUS=0
}
reset_results
add_result PASS core "Fixture" "healthy" "None"
MAC_HOST=mac-mini-ts
write_home_lab_report "" "" >/dev/null
[[ "$remote_report_body" == *'- Report: /Users/h/Desktop/Home Lab Readiness Briefs/home-lab-readiness-2026-08-04-manual.md'* ]] \
  || fail "Mac mini report should contain its remote path"
[[ "$remote_report_body" != *'/Users/hameldesai/Desktop/Ops Fallback Reports/'* ]] \
  || fail "Mac mini report must not contain the thin-Mac report path"
pass "host-correct readiness report paths"

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
