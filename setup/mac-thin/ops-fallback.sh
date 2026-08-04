#!/usr/bin/env bash
set -uo pipefail

# Manual, no-agent fallback for Hamel's personal Mac and home lab.
# Keep this file aligned with the personal-mac-ops, home-lab-readiness, and
# home-lab-outage-recovery skills when their operational contracts change.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_ROOT="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
OPS_REPORT_ROOT="${OPS_FALLBACK_REPORT_DIR:-$HOME/Desktop/Ops Fallback Reports}"
SSH_BIN="${OPS_FALLBACK_SSH_BIN:-/usr/bin/ssh}"
ZSH_BIN="${OPS_FALLBACK_ZSH_BIN:-/bin/zsh}"
BREW_BIN="${OPS_FALLBACK_BREW_BIN:-/opt/homebrew/bin/brew}"
PYTHON_BIN="${OPS_FALLBACK_PYTHON_BIN:-/usr/bin/python3}"
SSH_OPTIONS=(-o BatchMode=yes -o ConnectTimeout=8 -o ServerAliveInterval=5 -o ServerAliveCountMax=2)

LAST_STATUS=0
LAST_OUTPUT=""
MAC_HOST=""
RESULT_STATUS=()
RESULT_SCOPE=()
RESULT_AREA=()
RESULT_EVIDENCE=()
RESULT_NEXT=()
ADVISORIES=()
RECOVERY_ACTIONS=()
POSTGRES_OWNERSHIP_OK=0

usage() {
  printf '%s\n' \
    'Usage:' \
    '  ops-fallback.sh personal-ready' \
    '  ops-fallback.sh home-lab-ready [AWAY_START AWAY_END]' \
    '  ops-fallback.sh home-lab-recover' \
    '' \
    'Runs unattended. Known safe work is automatic; risky or unknown states' \
    'stop with an exact next action in the saved Markdown report.'
}

capture() {
  local output_file

  output_file="$(mktemp -t ops-fallback-output.XXXXXX)" || return 1
  "$@" >"$output_file" 2>&1
  LAST_STATUS=$?
  LAST_OUTPUT="$(<"$output_file")"
  /bin/rm -f "$output_file"
}

capture_with_input() {
  local input="$1"
  shift
  local input_file output_file

  input_file="$(mktemp -t ops-fallback-input.XXXXXX)" || return 1
  output_file="$(mktemp -t ops-fallback-output.XXXXXX)" || {
    /bin/rm -f "$input_file"
    return 1
  }
  printf '%s\n' "$input" >"$input_file"
  "$@" <"$input_file" >"$output_file" 2>&1
  LAST_STATUS=$?
  LAST_OUTPUT="$(<"$output_file")"
  /bin/rm -f "$input_file" "$output_file"
}

ssh_capture() {
  local host="$1"
  local payload="$2"
  capture "$SSH_BIN" "${SSH_OPTIONS[@]}" "$host" "$payload"
}

ssh_bash_capture() {
  local host="$1"
  local output_file

  output_file="$(mktemp -t ops-fallback-output.XXXXXX)" || return 1
  "$SSH_BIN" "${SSH_OPTIONS[@]}" "$host" /bin/bash -s >"$output_file" 2>&1
  LAST_STATUS=$?
  LAST_OUTPUT="$(<"$output_file")"
  /bin/rm -f "$output_file"
}

ssh_python_capture() {
  local host="$1"
  local program="$2"
  capture_with_input "$program" "$SSH_BIN" "${SSH_OPTIONS[@]}" "$host" /usr/bin/python3 -
}

reset_results() {
  RESULT_STATUS=()
  RESULT_SCOPE=()
  RESULT_AREA=()
  RESULT_EVIDENCE=()
  RESULT_NEXT=()
  ADVISORIES=()
  RECOVERY_ACTIONS=()
  POSTGRES_OWNERSHIP_OK=0
}

add_result() {
  local index="${#RESULT_STATUS[@]}"
  RESULT_STATUS[$index]="$1"
  RESULT_SCOPE[$index]="$2"
  RESULT_AREA[$index]="$3"
  RESULT_EVIDENCE[$index]="$4"
  RESULT_NEXT[$index]="$5"
}

add_advisory() {
  ADVISORIES[${#ADVISORIES[@]}]="$1"
}

add_recovery_action() {
  RECOVERY_ACTIONS[${#RECOVERY_ACTIONS[@]}]="$1"
}

count_status() {
  local wanted="$1"
  local count=0 status
  for status in "${RESULT_STATUS[@]}"; do
    [[ "$status" == "$wanted" ]] && count=$((count + 1))
  done
  printf '%s\n' "$count"
}

count_core_failures() {
  local count=0 index
  for ((index = 0; index < ${#RESULT_STATUS[@]}; index++)); do
    if [[ "${RESULT_SCOPE[$index]}" == "core" && "${RESULT_STATUS[$index]}" == "FAIL" ]]; then
      count=$((count + 1))
    fi
  done
  printf '%s\n' "$count"
}

count_readiness_warnings() {
  local count=0 index
  for ((index = 0; index < ${#RESULT_STATUS[@]}; index++)); do
    if [[ "${RESULT_STATUS[$index]}" == "WARN" ]] \
      || [[ "${RESULT_SCOPE[$index]}" == "secondary" && "${RESULT_STATUS[$index]}" == "FAIL" ]]; then
      count=$((count + 1))
    fi
  done
  printf '%s\n' "$count"
}

home_lab_overall() {
  local core_failures warnings failures
  core_failures="$(count_core_failures)"
  warnings="$(count_status WARN)"
  failures="$(count_status FAIL)"

  if ((core_failures > 0)); then
    printf 'NOT READY\n'
  elif ((warnings > 0 || failures > 0)); then
    printf 'READY WITH WARNINGS\n'
  else
    printf 'READY\n'
  fi
}

personal_verdict() {
  local scope="$1"
  local failures=0 warnings=0 user_actions=0 index
  for ((index = 0; index < ${#RESULT_STATUS[@]}; index++)); do
    [[ "${RESULT_SCOPE[$index]}" == "$scope" ]] || continue
    [[ "${RESULT_STATUS[$index]}" == "FAIL" ]] && failures=$((failures + 1))
    [[ "${RESULT_STATUS[$index]}" == "WARN" ]] && warnings=$((warnings + 1))
    if [[ "${RESULT_STATUS[$index]}" == "WARN" && "${RESULT_AREA[$index]}" == "Ubuntu reboot" ]]; then
      user_actions=$((user_actions + 1))
    fi
  done
  if ((failures > 0)); then
    printf 'Not ready yet\n'
  elif ((user_actions > 0)); then
    printf 'Need one user action\n'
  elif ((warnings > 0)); then
    printf 'Ready, with notes\n'
  else
    printf 'Ready\n'
  fi
}

safe_cell() {
  printf '%s' "$1" | /usr/bin/tr '\n\r\t|' '    '
}

write_results_table() {
  local report="$1"
  local index status area evidence next
  {
    printf '| Status | Area | Evidence | Next step |\n'
    printf '| --- | --- | --- | --- |\n'
    for ((index = 0; index < ${#RESULT_STATUS[@]}; index++)); do
      status="$(safe_cell "${RESULT_STATUS[$index]}")"
      area="$(safe_cell "${RESULT_AREA[$index]}")"
      evidence="$(safe_cell "${RESULT_EVIDENCE[$index]}")"
      next="$(safe_cell "${RESULT_NEXT[$index]}")"
      printf '| %s | %s | %s | %s |\n' "$status" "$area" "$evidence" "$next"
    done
  } >>"$report"
}

prepare_report_path() {
  local basename="$1"
  /bin/mkdir -p "$OPS_REPORT_ROOT"
  printf '%s/%s\n' "$OPS_REPORT_ROOT" "$basename"
}

exact_reply() {
  local output="$1"
  local expected="$2"
  [[ "$output" == "$expected" ]]
}

validate_away_window() {
  local start="${1:-}"
  local end="${2:-}"

  if [[ -z "$start" && -z "$end" ]]; then
    return 0
  fi
  [[ -n "$start" && -n "$end" ]] || return 1
  "$PYTHON_BIN" - "$start" "$end" <<'PY' >/dev/null 2>&1
from datetime import date
import sys

start = date.fromisoformat(sys.argv[1])
end = date.fromisoformat(sys.argv[2])
raise SystemExit(0 if start <= end else 1)
PY
}

select_mac_host() {
  MAC_HOST=""
  ssh_capture mac-mini-ts 'hostname; uptime'
  if ((LAST_STATUS == 0)); then
    MAC_HOST="mac-mini-ts"
    add_result PASS core "Tailscale SSH" "mac-mini-ts reachable" "None"
    return 0
  fi

  ssh_capture mac-mini-lan 'hostname; uptime'
  if ((LAST_STATUS == 0)); then
    MAC_HOST="mac-mini-lan"
    add_result FAIL core "Tailscale SSH" "mac-mini-ts unavailable; LAN fallback works" \
      "https://login.tailscale.com/admin/machines then ssh mac-mini-ts"
    return 0
  fi

  add_result FAIL core "Mac mini access" "Tailscale and LAN SSH both unavailable" \
    "https://login.tailscale.com/admin/machines"
  return 1
}

record_command_result() {
  local success_status="$1"
  local failure_status="$2"
  local scope="$3"
  local area="$4"
  local pass_evidence="$5"
  local fail_evidence="$6"
  local next_step="$7"

  if ((LAST_STATUS == 0)); then
    add_result "$success_status" "$scope" "$area" "$pass_evidence" "None"
  else
    add_result "$failure_status" "$scope" "$area" "$fail_evidence" "$next_step"
  fi
}

write_personal_report() {
  local report_date report thin_verdict ubuntu_verdict
  report_date="$(/bin/date +%F)"
  report="$(prepare_report_path "personal-readiness-${report_date}-manual.md")"
  thin_verdict="$(personal_verdict thin-mac)"
  ubuntu_verdict="$(personal_verdict ubuntu-vm)"

  {
    printf '# Personal Readiness - %s\n\n' "$report_date"
    printf '## Summary\n\n'
    printf -- '- Invocation: Manual fallback CLI\n'
    printf -- '- Thin Mac: %s\n' "$thin_verdict"
    printf -- '- Ubuntu development VM: %s\n' "$ubuntu_verdict"
    printf -- '- Report: %s\n\n' "$report"
    printf '## Checks\n\n'
  } >"$report"
  write_results_table "$report"
  {
    printf '\n## Notes\n\n'
    printf -- '- Automatic work was limited to the personal-mac-ops standing approvals.\n'
    printf -- '- VM restart or recreation was not attempted.\n'
  } >>"$report"

  printf '\nPERSONAL READINESS\n\nThin Mac: %s\nUbuntu VM: %s\n\nReport:\n%s\n' \
    "$thin_verdict" "$ubuntu_verdict" "$report"
}

check_ubuntu_forgejo_routes() {
  local vm_host="$1"

  ssh_capture "$vm_host" \
    'ssh -n -o BatchMode=yes -o ConnectTimeout=8 -T forgejo-truenas-ts'
  if ((LAST_STATUS == 0)); then
    add_result PASS ubuntu-vm "Forgejo Tailscale Git" \
      "Tailscale route authenticates" "None"
    return 0
  fi

  ssh_capture "$vm_host" \
    'ssh -n -o BatchMode=yes -o ConnectTimeout=8 -T forgejo-truenas-lan'
  if ((LAST_STATUS == 0)); then
    add_result FAIL ubuntu-vm "Forgejo Tailscale Git" \
      "LAN authenticates; Tailscale route is blocked" \
      "Allow tag:ubuntu-dev to tag:truenas-scale TCP 30143 at https://login.tailscale.com/admin/acls"
    return 1
  fi

  add_result FAIL ubuntu-vm "Forgejo Git" \
    "Tailscale and LAN Forgejo routes both failed" \
    "Run: ssh -T forgejo-truenas-ts; ssh -T forgejo-truenas-lan"
  return 1
}

run_personal_ready() {
  local vm_output vm_host="ubuntu-vm-ts"
  reset_results

  capture "$DOTFILES_ROOT/setup/mac-thin/doctor.sh"
  record_command_result PASS FAIL thin-mac "Thin-Mac doctor" \
    "doctor passed" "doctor reported failures" \
    "$DOTFILES_ROOT/setup/mac-thin/doctor.sh"

  capture /bin/df -Pk /
  if ((LAST_STATUS == 0)); then
    local available_kib
    available_kib="$(printf '%s\n' "$LAST_OUTPUT" | /usr/bin/awk 'NR == 2 {print $4}')"
    if [[ "$available_kib" =~ ^[0-9]+$ ]] && ((available_kib < 5242880)); then
      add_result FAIL thin-mac "Thin-Mac disk" "less than 5 GiB available" "Review storage before continuing"
    elif [[ "$available_kib" =~ ^[0-9]+$ ]] && ((available_kib < 20971520)); then
      add_result WARN thin-mac "Thin-Mac disk" "less than 20 GiB available" "Review storage soon"
    else
      add_result PASS thin-mac "Thin-Mac disk" "filesystem headroom is available" "None"
    fi
  else
    add_result FAIL thin-mac "Thin-Mac disk" "df failed" "/bin/df -h /"
  fi

  if [[ -x "$BREW_BIN" ]]; then
    capture "$BREW_BIN" trust --json=v1
    if ((LAST_STATUS == 0)); then
      add_result PASS thin-mac "Homebrew tap trust" "trust state inspected; unchanged" "None"
    else
      add_result WARN thin-mac "Homebrew tap trust" "trust inspection unavailable" \
        "Run: brew trust --json=v1"
    fi

    capture "$BREW_BIN" update
    if ((LAST_STATUS != 0)); then
      add_result FAIL thin-mac "Homebrew updates" "brew update failed; upgrade not attempted" \
        "Review the Homebrew error and do not change trust automatically"
    else
      capture /usr/bin/env HOMEBREW_NO_AUTO_UPDATE=1 "$BREW_BIN" upgrade
      if ((LAST_STATUS == 0)); then
        capture /usr/bin/env HOMEBREW_NO_AUTO_UPDATE=1 "$BREW_BIN" outdated
        if ((LAST_STATUS == 0)) && [[ -z "$LAST_OUTPUT" ]]; then
          add_result PASS thin-mac "Homebrew updates" "metadata refreshed and packages upgraded" "None"
        else
          add_result WARN thin-mac "Homebrew updates" "upgrade completed; packages remain outdated" \
            "HOMEBREW_NO_AUTO_UPDATE=1 brew outdated"
        fi
      else
        add_result FAIL thin-mac "Homebrew updates" "brew upgrade failed; tap trust was not changed" \
          "Review the Homebrew error and do not change trust automatically"
      fi
    fi
  else
    add_result FAIL thin-mac "Homebrew" "Homebrew missing" \
      "Install Homebrew through the supported thin-Mac bootstrap"
  fi

  capture "$ZSH_BIN" -c "source '$DOTFILES_ROOT/setup/mac-thin/vm.zsh'; uvm-status"
  vm_output="$LAST_OUTPUT"
  if ((LAST_STATUS != 0)); then
    add_result FAIL ubuntu-vm "Ubuntu VM state" "uvm-status failed" \
      "Inspect VMware Fusion and run uvm-status"
    write_personal_report
    return 1
  fi

  if [[ "$vm_output" == *"running"* ]]; then
    add_result PASS ubuntu-vm "Ubuntu VM state" "running" "None"
  elif [[ "$vm_output" == *"powered off"* || "$vm_output" == *"suspended"* ]]; then
    capture "$ZSH_BIN" -c "source '$DOTFILES_ROOT/setup/mac-thin/vm.zsh'; uvm-up"
    if ((LAST_STATUS == 0)); then
      capture "$ZSH_BIN" -c "source '$DOTFILES_ROOT/setup/mac-thin/vm.zsh'; uvm-status"
    fi
    if ((LAST_STATUS == 0)) && [[ "$LAST_OUTPUT" == *"running"* ]]; then
      add_result PASS ubuntu-vm "Ubuntu VM state" "started through uvm-up" "None"
    else
      add_result FAIL ubuntu-vm "Ubuntu VM state" "uvm-up did not reach running" \
        "Keep VMware Fusion open and run uvm-status"
      write_personal_report
      return 1
    fi
  else
    add_result FAIL ubuntu-vm "Ubuntu VM state" "missing, aborted, or unknown state; not started" \
      "Inspect VMware Fusion and run uvm-status"
    write_personal_report
    return 1
  fi

  ssh_capture ubuntu-vm-ts 'true'
  if ((LAST_STATUS != 0)); then
    ssh_capture ubuntu-vm 'true'
    if ((LAST_STATUS == 0)); then
      vm_host="ubuntu-vm"
      add_result WARN ubuntu-vm "Ubuntu SSH" "Tailscale unavailable; local Vagrant fallback works" \
        "Inspect Tailscale after readiness completes"
    else
      add_result FAIL ubuntu-vm "Ubuntu SSH" "Tailscale and local Vagrant SSH unavailable" \
        "Inspect VMware NAT, DNS, and the VM network adapter"
      write_personal_report
      return 1
    fi
  else
    add_result PASS ubuntu-vm "Ubuntu SSH" "ubuntu-vm-ts reachable" "None"
  fi

  ssh_capture "$vm_host" 'cd /home/hamel/Developer/dotfiles-hd && bash setup/ubuntu/update-system.sh'
  record_command_result PASS FAIL ubuntu-vm "Ubuntu updater" \
    "supported updater completed" "supported updater failed" \
    "Verify narrow unattended sudo and rerun setup/ubuntu/update-system.sh"

  ssh_capture "$vm_host" 'cd /home/hamel/Developer/dotfiles-hd && bash setup/ubuntu/doctor.sh'
  record_command_result PASS FAIL ubuntu-vm "Ubuntu doctor" \
    "doctor passed" "doctor reported failures" \
    "cd /home/hamel/Developer/dotfiles-hd && bash setup/ubuntu/doctor.sh"

  check_ubuntu_forgejo_routes "$vm_host" || true

  ssh_capture "$vm_host" 'zsh -lic "command -v codex >/dev/null && codex login status 2>&1 | grep -q '\''Logged in'\'' && mise doctor >/dev/null"'
  record_command_result PASS FAIL ubuntu-vm "Codex and mise" \
    "Codex login and mise passed" "Codex login or mise failed" \
    "zsh -lic 'codex login status; mise doctor'"

  ssh_capture "$vm_host" 'docker info >/dev/null 2>&1'
  record_command_result PASS FAIL ubuntu-vm "Docker" \
    "Docker ready without sudo" "Docker not ready" "docker info"

  ssh_capture "$vm_host" 'test ! -f /var/run/reboot-required'
  if ((LAST_STATUS == 0)); then
    add_result PASS ubuntu-vm "Ubuntu reboot" "no reboot required" "None"
  else
    add_result WARN ubuntu-vm "Ubuntu reboot" "reboot required; not restarted automatically" \
      "Run uvm-stop, then uvm-up"
  fi

  capture "$DOTFILES_ROOT/setup/mac-thin/doctor.sh"
  if ((LAST_STATUS != 0)); then
    add_result FAIL thin-mac "Thin-Mac post-update doctor" "doctor failed after updates" \
      "$DOTFILES_ROOT/setup/mac-thin/doctor.sh"
  else
    add_result PASS thin-mac "Thin-Mac post-update doctor" "doctor passed after updates" "None"
  fi

  write_personal_report
}

check_runtime() {
  local payload
  [[ -n "$MAC_HOST" ]] || return
  payload="MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0 MISE_NOT_FOUND_AUTO_INSTALL=0 /bin/zsh -lc 'cd ~/Developer/cortana-services && node --version && pnpm --version && pnpm runtime:status && pnpm runtime:doctor && pnpm runtime:tokens'"
  ssh_capture "$MAC_HOST" "$payload"
  if ((LAST_STATUS != 0)) || [[ "$LAST_OUTPUT" != *"v24.18.0"* ]] \
    || [[ "$LAST_OUTPUT" != *"11.2.2"* ]] \
    || [[ "$LAST_OUTPUT" == *"[ERROR]"* || "$LAST_OUTPUT" == *"version mismatch"* ]]; then
    add_result FAIL core "Cortana Services" "runtime checks or pinned tool versions failed" \
      "ssh mac-mini-ts \"MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0 MISE_NOT_FOUND_AUTO_INSTALL=0 /bin/zsh -lc 'cd ~/Developer/cortana-services && pnpm runtime:status && pnpm runtime:doctor'\""
  elif [[ "$LAST_OUTPUT" == *"[WARN]"* ]]; then
    add_result WARN core "Cortana Services" "runtime passed with warnings" \
      "Inspect pnpm runtime:doctor"
  else
    add_result PASS core "Cortana Services" "runtime status, doctor, tokens, and pinned tools passed" "None"
  fi

  ssh_capture "$MAC_HOST" 'for url in http://127.0.0.1:3000/api/health http://127.0.0.1:3001/api/health http://127.0.0.1:3033/health http://127.0.0.1:3034/health http://127.0.0.1:9130/health http://127.0.0.1:9120/api/status; do curl -fsS --max-time 8 "$url" >/dev/null || exit 1; done'
  record_command_result PASS FAIL core "Cortana health surfaces" \
    "all required local HTTP surfaces passed" "one or more required HTTP surfaces failed" \
    "Inspect Mission Control at http://100.101.48.55:3000"
}

classify_postgres_ownership() {
  local output="$1"
  [[ "$output" == *"postgresql@17"* && "$output" == *"started"* \
    && "$output" == *"accepting connections"* \
    && "$output" == *"/opt/homebrew/var/postgresql@17"* \
    && "$output" != *".pg0/instances/"* ]]
}

postgres_ownership_probe() {
  printf '%s' 'brew services list | grep "^postgresql@17[[:space:]]" || true; /opt/homebrew/opt/postgresql@17/bin/pg_isready -h 127.0.0.1 -p 5432 || true; pid="$(lsof -nP -t -iTCP:5432 -sTCP:LISTEN | head -n 1)"; test -n "$pid" && ps -ww -p "$pid" -o pid=,command= || true'
}

check_postgres() {
  local backup_payload
  [[ -n "$MAC_HOST" ]] || return

  ssh_capture "$MAC_HOST" "$(postgres_ownership_probe)"
  if classify_postgres_ownership "$LAST_OUTPUT"; then
    POSTGRES_OWNERSHIP_OK=1
    add_result PASS core "PostgreSQL ownership" "Homebrew PostgreSQL owns 127.0.0.1:5432" "None"
  else
    add_result FAIL core "PostgreSQL ownership" "canonical PostgreSQL ownership gate failed" \
      "Run ops-fallback.sh home-lab-recover"
  fi

  backup_payload='dir=/Users/h/Desktop/cortana-postgres-backups; latest="$(find "$dir" -type f -name "*.dump" -print 2>/dev/null | while IFS= read -r file; do printf "%s %s\n" "$(stat -f %m "$file")" "$file"; done | sort -nr | head -n 1 | cut -d" " -f2-)"; test -n "$latest" || exit 2; mode="$(stat -f %Lp "$latest")"; test "$mode" = 600 || exit 3; /opt/homebrew/opt/postgresql@17/bin/pg_restore --list "$latest" >/dev/null || exit 4; age_days="$((($(date +%s)-$(stat -f %m "$latest"))/86400))"; test "$age_days" -lt 30 || exit 5; HERMES_HOME=/Users/h/.hermes /Users/h/.local/bin/hermes cron list | grep -F "Home Lab Weekly Maintenance" | grep -E "enabled|success|succeeded" >/dev/null || exit 6; printf "age_days=%s mode=%s valid=yes\n" "$age_days" "$mode"'
  ssh_capture "$MAC_HOST" "$backup_payload"
  case "$LAST_STATUS" in
    0)
      add_result PASS core "PostgreSQL backup" \
        "canonical dump is under 30 days, mode 0600, readable, and scheduled" "None"
      ;;
    2 | 5 | 6)
      add_result WARN core "PostgreSQL backup" "canonical dump or weekly cadence is missing/stale" \
        "Use home-lab-maintenance"
      ;;
    *)
      add_result FAIL core "PostgreSQL backup" "canonical dump is unreadable, insecure, or invalid" \
        "Inspect /Users/h/Desktop/cortana-postgres-backups on the Mac mini"
      ;;
  esac
  add_advisory "PostgreSQL Desktop dumps are same-host rollback protection, not off-device disaster recovery."
}

check_hermes_release_pin() {
  ssh_bash_capture "$MAC_HOST" <<'BASH'
manifest=/Users/h/.hermes/skills/home-lab-maintenance/references/hermes-reviewed-stable.json
repo=/Users/h/.hermes/hermes-agent
test -r "$manifest" || exit 10
jq -e '.schema_version == 1
  and (.tag | type == "string")
  and (.commit | test("^[0-9a-f]{40}$"))
  and (.version_string | type == "string")' "$manifest" >/dev/null || exit 11
reviewed_tag="$(jq -r .tag "$manifest")"
reviewed_commit="$(jq -r .commit "$manifest")"
reviewed_version="$(jq -r .version_string "$manifest")"
test -z "$(git -C "$repo" status --short)" || exit 12
test "$(git -C "$repo" rev-parse HEAD)" = "$reviewed_commit" || exit 13
test "$(git -C "$repo" rev-list -n 1 "$reviewed_tag")" = "$reviewed_commit" || exit 14
test "$(git -C "$repo" describe --tags --exact-match HEAD)" = "$reviewed_tag" || exit 15
/Users/h/.local/bin/hermes --version | grep -Fq "$reviewed_version" || exit 16
official_json="$(
  curl -fsSL --max-time 20 \
    https://api.github.com/repos/NousResearch/hermes-agent/releases/latest \
    2>/dev/null || true
)"
official_tag="$(
  printf '%s' "$official_json" | jq -r '.tag_name // empty' 2>/dev/null || true
)"
if test -z "$official_tag"; then
  official_tag=unavailable
  report_only=unknown
elif test "$official_tag" = "$reviewed_tag"; then
  report_only=no
else
  report_only=yes
fi
printf 'reviewed=%s installed=%s official_latest=%s report_only=%s\n' \
  "$reviewed_tag" "$reviewed_tag" "$official_tag" "$report_only"
BASH
  if ((LAST_STATUS == 0)); then
    add_result PASS secondary "Hermes release pin" "$LAST_OUTPUT" "None"
  else
    add_result WARN secondary "Hermes release pin" \
      "checkout does not exactly match the deployed reviewed release manifest" \
      "Route review to home-lab-maintenance"
  fi
}

check_hermes() {
  local profile reply
  [[ -n "$MAC_HOST" ]] || return

  ssh_capture "$MAC_HOST" '/Users/h/.local/bin/hermes gateway status >/dev/null && /Users/h/.local/bin/hermes -p monitor gateway status >/dev/null && /Users/h/.local/bin/hermes -p spartan gateway status >/dev/null && HERMES_HOME=/Users/h/.hermes/profiles/monitor /Users/h/.local/bin/hermes cron list | grep -F "Cortana Services watchdog" | grep -E "enabled|every 5|5m" >/dev/null'
  record_command_result PASS FAIL core "Hermes gateways and Monitor" \
    "default, Monitor, Spartan, and watchdog passed" "gateway or watchdog check failed" \
    "ssh mac-mini-ts '/Users/h/.local/bin/hermes gateway list'"

  ssh_capture "$MAC_HOST" 'mise_node_bin="$(/opt/homebrew/bin/mise where node@24.18.0)/bin"; for plist_file in /Users/h/Library/LaunchAgents/ai.hermes.gateway{,-spartan,-monitor}.plist; do child_path="$(/usr/libexec/PlistBuddy -c "Print :EnvironmentVariables:PATH" "$plist_file")"; executable="$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:0" "$plist_file")"; test "$executable" = "/Users/h/.hermes/hermes-agent/venv/bin/python" || exit 1; case ":$child_path:" in *":$mise_node_bin:"*) ;; *) exit 1;; esac; test "$(PATH="$child_path" node --version)" = "v24.18.0" || exit 1; done'
  if ((LAST_STATUS == 0)); then
    add_result PASS core "Hermes child toolchain" "all gateway plists resolve mise Node v24.18.0" "None"
  else
    add_result WARN core "Hermes child toolchain" "gateway child PATH drifted" \
      "Route the update to home-lab-maintenance"
  fi

  for profile in default monitor spartan; do
    if [[ "$profile" == "spartan" && "$POSTGRES_OWNERSHIP_OK" != 1 ]]; then
      add_result FAIL core "Hermes model smoke: spartan" "blocked by the PostgreSQL ownership gate" \
        "Recover canonical PostgreSQL ownership before running Spartan"
      continue
    fi
    if [[ "$profile" == "default" ]]; then
      ssh_capture "$MAC_HOST" 'cd /Users/h/.hermes/hermes-agent && timeout 120 ./venv/bin/hermes -m gpt-5.6-sol --provider openai-codex -z "Reply exactly OK."'
    else
      ssh_capture "$MAC_HOST" "cd /Users/h/.hermes/hermes-agent && timeout 120 ./venv/bin/hermes -p $profile -m gpt-5.6-sol --provider openai-codex -z 'Reply exactly OK.'"
    fi
    reply="$LAST_OUTPUT"
    if ((LAST_STATUS == 0)) && exact_reply "$reply" OK; then
      add_result PASS core "Hermes model smoke: $profile" "exact OK reply" "None"
    else
      add_result FAIL core "Hermes model smoke: $profile" "model call failed or reply was not exact" \
        "Inspect redacted auth state and reauthorize manually if required"
    fi
  done

  check_hermes_release_pin
}

check_queues_and_delivery() {
  local queue_program
  [[ -n "$MAC_HOST" ]] || return

  IFS= read -r -d '' queue_program <<'PY' || true
import json
from datetime import datetime, timezone, timedelta
from urllib.request import urlopen

BASE = "http://127.0.0.1:3033"

def get(path):
    with urlopen(BASE + path, timeout=10) as response:
        return json.load(response)

pending = 0
actionable_failed = 0
delivery = {"monitor": False, "spartan": False}
now = datetime.now(timezone.utc)

for target in ("monitor", "spartan"):
    completed = get(f"/agent-events?target={target}&status=completed&limit=40").get("events", [])
    completed_keys = {}
    for event in completed:
        key = (event.get("eventType"), event.get("summary"))
        completed_keys[key] = max(completed_keys.get(key, ""), event.get("completedAt") or event.get("updatedAt") or "")
        result = event.get("result") or {}
        if isinstance(result, dict) and str(result.get("stage", "")).lower() in ("webhook_deliver", "telegram", "delivered"):
            delivery[target] = True
    for status in ("pending", "failed"):
        events = get(f"/agent-events?target={target}&status={status}&limit=40").get("events", [])
        for event in events:
            if status == "pending":
                pending += 1
                continue
            created = event.get("createdAt") or event.get("updatedAt") or ""
            replacement = completed_keys.get((event.get("eventType"), event.get("summary")), "")
            priority = str(event.get("priority", "")).lower()
            event_type = str(event.get("eventType", "")).lower()
            actionable = priority in ("high", "critical") or any(word in event_type for word in ("warning", "action_required"))
            if actionable and not (replacement and replacement > created):
                actionable_failed += 1
    outputs = get(f"/agent-outputs?agent={target}&limit=20").get("outputs", [])
    if any(str(item.get("channel", "")).lower() == "telegram" and item.get("providerMessageId") for item in outputs):
        delivery[target] = True

print(json.dumps({"pending": pending, "actionable_failed": actionable_failed, "delivery": delivery}, separators=(",", ":")))
PY
  ssh_python_capture "$MAC_HOST" "$queue_program"
  if ((LAST_STATUS != 0)) || ! printf '%s' "$LAST_OUTPUT" | /usr/bin/jq -e . >/dev/null 2>&1; then
    add_result FAIL core "Monitor and Spartan queues" "queue surface or parser failed" \
      "Inspect Service API agent-events and agent-outputs"
    return
  fi

  local pending failed monitor_delivery spartan_delivery
  pending="$(printf '%s' "$LAST_OUTPUT" | /usr/bin/jq -r '.pending')"
  failed="$(printf '%s' "$LAST_OUTPUT" | /usr/bin/jq -r '.actionable_failed')"
  monitor_delivery="$(printf '%s' "$LAST_OUTPUT" | /usr/bin/jq -r '.delivery.monitor')"
  spartan_delivery="$(printf '%s' "$LAST_OUTPUT" | /usr/bin/jq -r '.delivery.spartan')"
  if ((pending == 0 && failed == 0)); then
    add_result PASS core "Monitor and Spartan queues" "no pending or unsuperseded actionable failed rows" "None"
  else
    add_result FAIL core "Monitor and Spartan queues" "pending=$pending actionable_failed=$failed" \
      "Inspect current agent-events; do not send synthetic events automatically"
  fi
  if [[ "$monitor_delivery" == true && "$spartan_delivery" == true ]]; then
    add_result PASS core "Telegram-backed delivery" "Monitor and Spartan delivery evidence exists" "None"
  else
    add_result WARN core "Telegram-backed delivery" "recent retained delivery evidence is incomplete" \
      "Inspect agent-events and agent-outputs"
  fi
}

check_tailscale() {
  [[ -n "$MAC_HOST" ]] || return
  ssh_capture "$MAC_HOST" 'tailscale status --self >/dev/null && tailscale ping -c 1 100.65.26.87 >/dev/null && tailscale serve status >/dev/null'
  record_command_result PASS FAIL core "Tailscale" \
    "self status, TrueNAS peer ping, and Serve passed" "status, peer ping, or Serve failed" \
    "https://login.tailscale.com/admin/machines"
}

check_truenas() {
  local payload truenas_host="truenas-ts"
  payload='apps_bad="$(midclt call app.query | jq "[.[] | select(.state != \"RUNNING\")] | length")"; pool_bad="$(midclt call pool.query | jq "[.[] | select((.healthy != true) or (.status != \"ONLINE\"))] | length")"; repl_bad="$(midclt call replication.query | jq "[.[] | select(.enabled != true or ((.state.state? // .state? // \"unknown\") | tostring | test(\"ERROR|FAILED\"; \"i\")))] | length")"; alerts_bad="$(midclt call alert.list | jq "[.[] | select((.level | ascii_upcase) == \"CRITICAL\" or (.level | ascii_upcase) == \"ALERT\")] | length")"; midclt call docker.status >/dev/null || exit 1; printf "apps_bad=%s pool_bad=%s repl_bad=%s alerts_bad=%s\n" "$apps_bad" "$pool_bad" "$repl_bad" "$alerts_bad"; test "$apps_bad" -eq 0 -a "$pool_bad" -eq 0 -a "$repl_bad" -eq 0 -a "$alerts_bad" -eq 0'
  ssh_capture truenas-ts "$payload"
  if ((LAST_STATUS != 0)); then
    ssh_capture truenas-lan "$payload"
    ((LAST_STATUS == 0)) && truenas_host="truenas-lan"
  fi
  if ((LAST_STATUS == 0)); then
    add_result PASS core "TrueNAS middleware" "$LAST_OUTPUT via $truenas_host" "None"
  else
    add_result FAIL core "TrueNAS middleware" "app, pool, replication, Docker, or critical-alert check failed" \
      "ssh truenas-ts 'midclt call alert.list'"
  fi

  [[ -n "$MAC_HOST" ]] || return
  ssh_capture "$MAC_HOST" 'events="$(curl -fsS "http://127.0.0.1:3033/agent-events?target=monitor&status=completed&limit=40")" || exit 1; health="$(curl -fsS "http://127.0.0.1:3033/infra/artifacts?source=hermes-truenas-health-monitor&node=truenas-primary&artifactKind=health&environment=prod&limit=20")" || exit 1; printf "%s" "$events" | jq -e "([.events[] | select(.eventType == \"truenas.snapshot.reported\")] | length > 0) and ([.events[] | select(.eventType == \"truenas.backup.reported\")] | length > 0)" >/dev/null || exit 1; artifact_id="$(printf "%s" "$health" | jq -r "(if type == \"array\" then . elif (.artifacts | type) == \"array\" then .artifacts elif (.data | type) == \"array\" then .data else [] end) | sort_by(.updatedAt // .observedAt // \"\") | last | .id // empty")"; test -n "$artifact_id" || exit 1; curl -fsS "http://127.0.0.1:3033/artifacts/infra/$artifact_id" | jq -e . >/dev/null'
  record_command_result PASS FAIL core "TrueNAS production evidence" \
    "Monitor events and infra artifacts are inspectable" "production evidence path failed" \
    "Inspect Service API TrueNAS events and infra artifacts"
}

check_home_assistant() {
  local integration_program
  ssh_capture homeassistant-ts 'ha core info >/dev/null && ha resolution info >/dev/null'
  record_command_result PASS FAIL core "Home Assistant host" \
    "core and resolution surfaces passed" "Home Assistant CLI checks failed" \
    "ssh homeassistant-ts 'ha core info'"

  [[ -n "$MAC_HOST" ]] || return
  IFS= read -r -d '' integration_program <<'PY' || true
import json
import os
import subprocess
import tempfile
from pathlib import Path

def clean(value):
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
        return value[1:-1]
    return value

env = {}
for raw in Path('/Users/h/.hermes/.env').read_text(errors='ignore').splitlines():
    line = raw.strip()
    if line and not line.startswith('#') and '=' in line:
        key, value = line.split('=', 1)
        env[key.strip()] = clean(value)
url = (env.get('HASS_URL') or env.get('HOME_ASSISTANT_URL') or '').rstrip('/')
token = env.get('HASS_TOKEN') or env.get('HOME_ASSISTANT_TOKEN') or ''
print('url=present' if url else 'url=missing')
print('token=present' if token else 'token=missing')
if not url or not token:
    raise SystemExit(2)
with tempfile.TemporaryDirectory(prefix='ha_fallback_') as directory:
    config = Path(directory) / 'curl.conf'
    config.write_text('\n'.join([
        f'url = "{url}/api/states"',
        'request = "GET"',
        'connect-timeout = 8',
        'max-time = 12',
        'silent',
        'show-error',
        'fail-with-body',
        f'header = "Authorization: Bearer {token}"',
        'header = "Content-Type: application/json"',
        '',
    ]))
    os.chmod(config, 0o600)
    result = subprocess.run(['/usr/bin/curl', '--config', str(config)], capture_output=True, text=True, timeout=15)
if result.returncode:
    raise SystemExit(result.returncode)
states = json.loads(result.stdout)
if not isinstance(states, list):
    raise SystemExit(3)
print(f'states_count={len(states)}')
PY
  ssh_python_capture "$MAC_HOST" "$integration_program"
  if ((LAST_STATUS == 0)); then
    add_result PASS core "Hermes Home Assistant integration" "$LAST_OUTPUT" "None"
  else
    add_result FAIL core "Hermes Home Assistant integration" "configured read-only API check failed" \
      "Repair URL/token manually; do not print credentials"
  fi
}

check_secondary_providers() {
  local away_end="$1"
  local providers_program google_payload
  [[ -n "$MAC_HOST" ]] || return

  IFS= read -r -d '' providers_program <<'PY' || true
import json
from datetime import datetime, timezone, timedelta
from urllib.error import HTTPError
from urllib.request import Request, urlopen

def get(url, headers=None):
    request = Request(url, headers=headers or {})
    try:
        with urlopen(request, timeout=12) as response:
            return response.status, json.load(response)
    except HTTPError as error:
        try:
            body = json.load(error)
        except Exception:
            body = {}
        return error.code, body

def provider_matches(value, provider):
    matches = []
    if isinstance(value, dict):
        current_name = str(value.get('provider') or value.get('providerId') or value.get('name') or value.get('displayName') or '').lower()
        if current_name == provider:
            matches.append(value)
        for key, child in value.items():
            if str(key).lower() == provider:
                matches.append(child)
            if isinstance(child, dict):
                name = str(child.get('provider') or child.get('providerId') or child.get('name') or child.get('displayName') or '').lower()
                if name == provider:
                    matches.append(child)
            matches.extend(provider_matches(child, provider))
    elif isinstance(value, list):
        for child in value:
            matches.extend(provider_matches(child, provider))
    return matches

code, readiness = get('http://127.0.0.1:3033/provider-readiness')
print(f'readiness_http={code}')
for provider in ('whoop', 'tonal'):
    matches = provider_matches(readiness, provider)
    text = json.dumps(matches).lower()
    if not matches:
        status = 'FAIL'
    elif any(word in text for word in ('reauth', 'rejected', 'missing_token', 'manual_action')):
        status = 'FAIL'
    elif any(word in text for word in ('stale', 'delay', 'waiting')):
        status = 'WARN'
    else:
        status = 'PASS'
    print(f'provider={provider}|status={status}')

for name, path in (('schwab-rest', 'auth/schwab/status'), ('schwab-streamer', 'auth/schwab/streamer/status')):
    code, data = get('http://127.0.0.1:9130/' + path)
    issued = data.get('refreshTokenIssuedAt') or (data.get('data') or {}).get('refreshTokenIssuedAt')
    state = str(data.get('status') or (data.get('data') or {}).get('status') or '').lower()
    print(f'provider={name}|http={code}|state={state}|issued={issued or "missing"}')

headers = {
    'x-cortana-caller': 'home-lab-readiness:manual-fallback',
    'x-cortana-source-route': 'home-lab-readiness',
}
polymarket_auth_failure = False
polymarket_failure = False
polymarket_critical = False
polymarket_waiting = False
polymarket_readiness = json.dumps(provider_matches(readiness, 'polymarket')).lower()
if '"status": "waiting"' in polymarket_readiness or '"action": "wait"' in polymarket_readiness:
    polymarket_waiting = True
for path in ('health', 'balances', 'positions', 'orders'):
    code, data = get('http://127.0.0.1:9130/polymarket/' + path, headers)
    if code in (401, 403):
        polymarket_auth_failure = True
    if code >= 500:
        polymarket_failure = True
for url in (
    'http://127.0.0.1:9130/polymarket/live?seedPrivateAccount=false',
    'http://127.0.0.1:3033/polymarket/operator-state',
    'http://127.0.0.1:3000/api/polymarket/live',
):
    code, data = get(url, headers)
    text = json.dumps(data).lower()
    if code in (401, 403) or 'reauth' in text:
        polymarket_auth_failure = True
    if 'restart_provider_gateway' in text:
        polymarket_critical = True
    if '"status": "waiting"' in text or '"action": "wait"' in text:
        polymarket_waiting = True
    if code >= 500:
        polymarket_failure = True
print(f'provider=polymarket|auth_failure={str(polymarket_auth_failure).lower()}|critical={str(polymarket_critical).lower()}|waiting={str(polymarket_waiting).lower()}|upstream_failure={str(polymarket_failure).lower()}')
PY
  ssh_python_capture "$MAC_HOST" "$providers_program"
  if ((LAST_STATUS != 0)); then
    add_result FAIL secondary "Secondary providers" "provider readiness probe failed" \
      "Inspect /provider-readiness on the Service API"
  else
    local provider_line provider status
    while IFS= read -r provider_line; do
      [[ "$provider_line" == provider=*"|status="* ]] || continue
      provider="${provider_line#provider=}"
      provider="${provider%%|*}"
      status="${provider_line##*|status=}"
      add_result "$status" secondary "Provider: $provider" "live readiness=$status" \
        "$([[ "$status" == PASS ]] && printf None || printf 'Inspect provider readiness; reauthorization is manual')"
    done <<<"$LAST_OUTPUT"

    local schwab_line issued mark state
    while IFS= read -r schwab_line; do
      [[ "$schwab_line" == provider=schwab-* ]] || continue
      provider="${schwab_line#provider=}"
      provider="${provider%%|*}"
      state="${schwab_line#*|state=}"
      state="${state%%|*}"
      issued="${schwab_line##*|issued=}"
      if [[ "$issued" == missing || "$state" == *"reauth"* || "$state" == *"rejected"* \
        || "$state" == *"missing"* || "$state" == *"manual"* ]]; then
        add_result FAIL secondary "Provider: $provider" "refresh token missing or requires manual action" \
          "Reauthorize Schwab manually"
        continue
      fi
      mark="$($PYTHON_BIN - "$issued" <<'PY' 2>/dev/null
from datetime import datetime, timedelta
import sys
value = sys.argv[1].replace('Z', '+00:00')
print((datetime.fromisoformat(value) + timedelta(days=7)).isoformat())
PY
)"
      if [[ -z "$mark" ]]; then
        add_result FAIL secondary "Provider: $provider" "refresh-token date was invalid" \
          "Reauthorize Schwab manually"
      elif ! "$PYTHON_BIN" - "$mark" <<'PY' >/dev/null 2>&1
from datetime import datetime, timezone, timedelta
import sys
mark = datetime.fromisoformat(sys.argv[1])
if mark.tzinfo is None:
    mark = mark.replace(tzinfo=timezone.utc)
raise SystemExit(0 if mark - datetime.now(timezone.utc) >= timedelta(hours=72) else 1)
PY
      then
        add_result FAIL secondary "Provider: $provider" "refresh-token 7-day mark $mark is under 72 hours" \
          "Reauthorize Schwab manually"
      elif [[ -n "$away_end" ]] && ! "$PYTHON_BIN" - "$mark" "$away_end" <<'PY' >/dev/null 2>&1
from datetime import date, datetime
import sys
mark = datetime.fromisoformat(sys.argv[1]).date()
end = date.fromisoformat(sys.argv[2])
raise SystemExit(0 if mark >= end else 1)
PY
      then
        add_result WARN secondary "Provider: $provider" "7-day mark $mark is before return" \
          "Reauthorize before the away window"
      else
        add_result PASS secondary "Provider: $provider" "refresh-token 7-day mark $mark" "None"
        [[ -z "$away_end" ]] && add_advisory "$provider refresh-token 7-day mark: $mark"
      fi
    done <<<"$LAST_OUTPUT"

    if [[ "$LAST_OUTPUT" == *"provider=polymarket|auth_failure=true"* \
      || "$LAST_OUTPUT" == *"|critical=true|"* ]]; then
      add_result FAIL secondary "Provider: Polymarket" "auth failed or live diagnostics require a gateway restart" \
        "Repair credentials manually"
    elif [[ "$LAST_OUTPUT" == *"provider=polymarket"*"waiting=true"* \
      || "$LAST_OUTPUT" == *"provider=polymarket"*"upstream_failure=true"* ]]; then
      add_result WARN secondary "Provider: Polymarket" "auth passed; live state is waiting or upstream-delayed" \
        "Retry after the upstream recovers"
    else
      add_result PASS secondary "Provider: Polymarket" "bounded private REST did not auth-fail" "None"
    fi
  fi

  google_payload='HERMES_PY=/Users/h/.hermes/hermes-agent/venv/bin/python; HERMES_HOME=/Users/h/.hermes "$HERMES_PY" -c "import googleapiclient, google_auth_oauthlib" && HERMES_HOME=/Users/h/.hermes "$HERMES_PY" /Users/h/.hermes/skills/productivity/google-workspace/scripts/setup.py --check-live >/dev/null'
  ssh_capture "$MAC_HOST" "$google_payload"
  record_command_result PASS FAIL secondary "Google Workspace" \
    "live Gmail/Calendar check passed" "live check or dependency import failed" \
    "Run the Google Workspace setup check manually"
}

write_home_lab_report() {
  local away_start="$1"
  local away_end="$2"
  local report_date report overall pass_count warn_count fail_count core_failures index
  report_date="$(/bin/date +%F)"
  report="$(prepare_report_path "home-lab-readiness-${report_date}-manual.md")"
  overall="$(home_lab_overall)"
  pass_count="$(count_status PASS)"
  warn_count="$(count_readiness_warnings)"
  fail_count="$(count_status FAIL)"
  core_failures="$(count_core_failures)"

  {
    printf '# Home Lab Readiness Brief - %s\n\n' "$report_date"
    printf '## Summary\n\n'
    printf -- '- Overall: %s\n' "$overall"
    printf -- '- Invocation: Manual fallback CLI\n'
    printf -- '- Core blockers: %s\n' "$core_failures"
    printf -- '- Warnings: %s\n' "$warn_count"
    printf -- '- Advisories: %s\n' "${#ADVISORIES[@]}"
    if [[ -n "$away_start" ]]; then
      printf -- '- Away window: %s to %s\n' "$away_start" "$away_end"
    else
      printf -- '- Away window: window not provided\n'
    fi
    printf -- '- Report: %s\n\n' "$report"
    printf '## What Is Wrong\n\n'
    local wrote_wrong=0
    for ((index = 0; index < ${#RESULT_STATUS[@]}; index++)); do
      if [[ "${RESULT_STATUS[$index]}" == FAIL ]]; then
        printf -- '- %s - %s - %s\n' "${RESULT_AREA[$index]}" "${RESULT_EVIDENCE[$index]}" "${RESULT_NEXT[$index]}"
        wrote_wrong=1
      fi
    done
    ((wrote_wrong == 0)) && printf 'None\n'
    printf '\n## Warnings\n\n'
    local wrote_warning=0
    for ((index = 0; index < ${#RESULT_STATUS[@]}; index++)); do
      if [[ "${RESULT_STATUS[$index]}" == WARN ]] \
        || [[ "${RESULT_SCOPE[$index]}" == secondary && "${RESULT_STATUS[$index]}" == FAIL ]]; then
        printf -- '- %s - %s\n' "${RESULT_AREA[$index]}" "${RESULT_EVIDENCE[$index]}"
        wrote_warning=1
      fi
    done
    ((wrote_warning == 0)) && printf 'None\n'
    printf '\n## Advisories\n\n'
    if ((${#ADVISORIES[@]} == 0)); then
      printf 'None\n'
    else
      for index in "${!ADVISORIES[@]}"; do
        printf -- '- %s\n' "${ADVISORIES[$index]}"
      done
    fi
    printf '\n## Checks\n\n'
  } >"$report"
  write_results_table "$report"
  {
    printf '\n## Routing\n\n'
    printf -- '- Updates or routine maintenance: `home-lab-maintenance`\n'
    printf -- '- Broken core services: `%s home-lab-recover`\n' "$DOTFILES_ROOT/setup/mac-thin/ops-fallback.sh"
    printf -- '- OAuth, credentials, router, HomeKit pairing, ACLs, and firmware: manual follow-up\n'
    printf '\n## Notes\n\n'
    printf -- '- Curated evidence only. No raw secrets or token payloads included.\n'
    printf -- '- This readiness command performed no fixes, restarts, or configuration changes.\n'
  } >>"$report"

  if [[ -n "$MAC_HOST" ]]; then
    local remote_date remote_report
    ssh_capture "$MAC_HOST" 'date +%F'
    remote_date="$LAST_OUTPUT"
    [[ "$remote_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || remote_date="$report_date"
    remote_report="/Users/h/Desktop/Home Lab Readiness Briefs/home-lab-readiness-${remote_date}-manual.md"
    ssh_capture "$MAC_HOST" 'mkdir -p "/Users/h/Desktop/Home Lab Readiness Briefs"'
    if ((LAST_STATUS == 0)); then
      capture_with_input "$(<"$report")" "$SSH_BIN" "${SSH_OPTIONS[@]}" "$MAC_HOST" \
        "umask 077; /bin/cat > '$remote_report'"
      if ((LAST_STATUS != 0)); then
        printf 'Warning: local report saved, but Mac mini report copy failed.\n' >&2
      fi
    fi
  fi

  printf '\nHOME LAB READINESS: %s\n\nCore blockers: %s\nWarnings: %s\nAdvisories: %s\n\nReport:\n%s\n' \
    "$overall" "$core_failures" "$warn_count" "${#ADVISORIES[@]}" "$report"
}

run_home_lab_ready() {
  local away_start="${1:-}"
  local away_end="${2:-}"
  reset_results
  if ! validate_away_window "$away_start" "$away_end"; then
    printf 'Away dates must be valid YYYY-MM-DD values with start on or before end.\n' >&2
    return 2
  fi

  select_mac_host || true
  check_runtime
  check_postgres
  check_hermes
  check_queues_and_delivery
  check_tailscale
  check_truenas
  check_home_assistant
  check_secondary_providers "$away_end"
  write_home_lab_report "$away_start" "$away_end"
}

recover_postgres_if_needed() {
  local ownership lock_probe
  [[ -n "$MAC_HOST" ]] || return 1
  ssh_capture "$MAC_HOST" "$(postgres_ownership_probe)"
  ownership="$LAST_OUTPUT"
  if classify_postgres_ownership "$ownership"; then
    POSTGRES_OWNERSHIP_OK=1
    add_result PASS core "PostgreSQL recovery" "canonical PostgreSQL already owns 5432" "None"
    return 0
  fi

  if [[ "$ownership" == *".pg0/instances/"* ]]; then
    ssh_capture "$MAC_HOST" '/Users/h/.local/bin/hermes -p spartan gateway stop && /Users/h/.hermes/hermes-agent/venv/bin/hindsight-embed -p spartan daemon stop'
    if ((LAST_STATUS != 0)); then
      add_result FAIL core "PostgreSQL recovery" "could not stop Spartan/Hindsight through supported CLIs" \
        "Inspect Spartan and Hindsight status manually"
      return 1
    fi
    add_recovery_action "Stopped Spartan and Hindsight through supported CLIs."
  fi

  ssh_capture "$MAC_HOST" 'pid="$(lsof -nP -t -iTCP:5432 -sTCP:LISTEN | head -n 1)"; test -z "$pid"'
  if ((LAST_STATUS != 0)); then
    add_result FAIL core "PostgreSQL recovery" "5432 remains occupied after supported stops" \
      "Inspect the exact listener; no process was killed"
    return 1
  fi

  ssh_capture "$MAC_HOST" 'brew services stop postgresql@17 >/dev/null 2>&1 || true; brew services start postgresql@17'
  if ((LAST_STATUS != 0)); then
    lock_probe='lock=/opt/homebrew/var/postgresql@17/postmaster.pid; test -f "$lock" || exit 2; pid="$(sed -n "1p" "$lock")"; test -n "$pid" || exit 3; ps -p "$pid" >/dev/null 2>&1 && exit 4; lsof -nP "$lock" >/dev/null 2>&1 && exit 5; ps -ww -axo command= | grep -E "(^|/)postgres .*\/opt\/homebrew\/var\/postgresql@17" | grep -v grep >/dev/null && exit 6; lsof -nP -iTCP:5432 -sTCP:LISTEN >/dev/null 2>&1 && exit 7'
    ssh_capture "$MAC_HOST" "$lock_probe"
    if ((LAST_STATUS == 0)); then
      ssh_capture "$MAC_HOST" 'lock=/opt/homebrew/var/postgresql@17/postmaster.pid; mv "$lock" "${lock}.stale.$(date +%Y%m%d-%H%M%S)" && brew services start postgresql@17'
      if ((LAST_STATUS == 0)); then
        add_recovery_action "Preserved a proven stale PostgreSQL PID file and restarted the service."
      fi
    fi
  else
    add_recovery_action "Started canonical Homebrew PostgreSQL."
  fi

  ssh_capture "$MAC_HOST" "$(postgres_ownership_probe)"
  if ! classify_postgres_ownership "$LAST_OUTPUT"; then
    add_result FAIL core "PostgreSQL recovery" "canonical ownership gate still fails" \
      "Inspect Homebrew PostgreSQL and the 5432 listener manually"
    return 1
  fi
  POSTGRES_OWNERSHIP_OK=1

  ssh_capture "$MAC_HOST" '/Users/h/.hermes/hermes-agent/venv/bin/hindsight-embed -p spartan daemon start && /Users/h/.local/bin/hermes -p spartan gateway start'
  if ((LAST_STATUS == 0)); then
    add_recovery_action "Started Hindsight and Spartan after PostgreSQL passed its ownership gate."
  fi
  POSTGRES_OWNERSHIP_OK=0
  ssh_capture "$MAC_HOST" "$(postgres_ownership_probe)"
  if classify_postgres_ownership "$LAST_OUTPUT"; then
    POSTGRES_OWNERSHIP_OK=1
    add_result PASS core "PostgreSQL recovery" "Homebrew PostgreSQL owns 5432 after recovery" "None"
    return 0
  fi
  add_result FAIL core "PostgreSQL recovery" "Spartan restart displaced canonical PostgreSQL" \
    "Stop and inspect pg0/Hindsight; do not pin an internal port"
  return 1
}

recover_cortana_if_needed() {
  local status_payload start_payload
  [[ -n "$MAC_HOST" ]] || return 1
  status_payload="MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0 MISE_NOT_FOUND_AUTO_INSTALL=0 /bin/zsh -lc 'cd ~/Developer/cortana-services && pnpm runtime:status && pnpm runtime:doctor'"
  ssh_capture "$MAC_HOST" "$status_payload"
  if ((LAST_STATUS == 0)) && [[ "$LAST_OUTPUT" != *"[ERROR]"* ]]; then
    add_result PASS core "Cortana recovery" "runtime already healthy" "None"
    return 0
  fi

  start_payload='test "$(/opt/homebrew/bin/mise exec node@24.18.0 -- node --version)" = "v24.18.0" && test "$(/opt/homebrew/bin/mise exec node@24.18.0 -- corepack --version)" = "0.35.0" && test "$(/opt/homebrew/bin/mise exec -C /Users/h/Developer/cortana-services node@24.18.0 -- corepack pnpm --version)" = "11.2.2" && /opt/homebrew/bin/mise exec -C /Users/h/Developer/cortana-services node@24.18.0 -- corepack pnpm runtime:start'
  ssh_capture "$MAC_HOST" "$start_payload"
  if ((LAST_STATUS != 0)); then
    add_result FAIL core "Cortana recovery" "runtime:start failed its toolchain gate or service start" \
      "Inspect runtime:status and runtime:doctor manually"
    return 1
  fi
  add_recovery_action "Started stopped Cortana services with runtime:start."
  ssh_capture "$MAC_HOST" "$status_payload"
  if ((LAST_STATUS == 0)) && [[ "$LAST_OUTPUT" != *"[ERROR]"* ]]; then
    add_result PASS core "Cortana recovery" "runtime doctor passed after runtime:start" "None"
    return 0
  fi
  add_result FAIL core "Cortana recovery" "runtime doctor still fails after runtime:start" \
    "A full runtime restart was not attempted; inspect the failed service"
  return 1
}

recover_hermes_if_needed() {
  local profile started
  [[ -n "$MAC_HOST" ]] || return 1
  for profile in default monitor spartan; do
    started=0
    if [[ "$profile" == default ]]; then
      ssh_capture "$MAC_HOST" '/Users/h/.local/bin/hermes gateway status'
      if ((LAST_STATUS != 0)); then
        ssh_capture "$MAC_HOST" '/Users/h/.local/bin/hermes gateway start'
        ((LAST_STATUS == 0)) && started=1
      fi
    else
      ssh_capture "$MAC_HOST" "/Users/h/.local/bin/hermes -p $profile gateway status"
      if ((LAST_STATUS != 0)); then
        ssh_capture "$MAC_HOST" "/Users/h/.local/bin/hermes -p $profile gateway start"
        ((LAST_STATUS == 0)) && started=1
      fi
    fi
    if ((LAST_STATUS == 0)); then
      ((started == 1)) && add_recovery_action "Started the $profile Hermes gateway."
      add_result PASS core "Hermes recovery: $profile" "gateway is running" "None"
    else
      add_result FAIL core "Hermes recovery: $profile" "gateway start/status failed" \
        "Inspect redacted auth state; reauthorization is manual"
    fi
  done
}

write_recovery_report() {
  local report_date report overall index
  report_date="$(/bin/date +%F-%H%M%S)"
  report="$(prepare_report_path "home-lab-recovery-${report_date}-manual.md")"
  overall="$(home_lab_overall)"
  {
    printf '# Home Lab Recovery - %s\n\n' "$report_date"
    printf '## Summary\n\n'
    printf -- '- Invocation: Manual fallback CLI\n'
    printf -- '- Current status: %s\n' "$overall"
    printf -- '- Report: %s\n\n' "$report"
    printf '## Fixes Applied\n\n'
    if ((${#RECOVERY_ACTIONS[@]} == 0)); then
      printf 'None\n'
    else
      for index in "${!RECOVERY_ACTIONS[@]}"; do
        printf -- '- %s\n' "${RECOVERY_ACTIONS[$index]}"
      done
    fi
    printf '\n## Current Status\n\n'
  } >"$report"
  write_results_table "$report"
  {
    printf '\n## URLs To Test\n\n'
    printf -- '- Mission Control: http://100.101.48.55:3000\n'
    printf -- '- Tailscale machines: https://login.tailscale.com/admin/machines\n'
    printf '\n## Safety Boundary\n\n'
    printf -- '- No credentials, router settings, HomeKit pairing, ACLs, firmware, or destructive storage actions were changed.\n'
  } >>"$report"
  printf '\nHOME LAB RECOVERY: %s\n\nFixes applied: %s\nReport:\n%s\n' \
    "$overall" "${#RECOVERY_ACTIONS[@]}" "$report"
}

run_home_lab_recover() {
  reset_results
  select_mac_host || true
  if [[ -n "$MAC_HOST" ]]; then
    recover_postgres_if_needed || true
    recover_cortana_if_needed || true
    recover_hermes_if_needed || true
    check_runtime
    check_hermes
    check_queues_and_delivery
  fi

  check_tailscale
  check_truenas
  check_home_assistant
  write_recovery_report
}

main() {
  local command="${1:-}"
  case "$command" in
    personal-ready)
      (($# == 1)) || {
        usage >&2
        return 2
      }
      run_personal_ready
      ;;
    home-lab-ready)
      (($# == 1 || $# == 3)) || {
        usage >&2
        return 2
      }
      run_home_lab_ready "${2:-}" "${3:-}"
      ;;
    home-lab-recover)
      (($# == 1)) || {
        usage >&2
        return 2
      }
      run_home_lab_recover
      ;;
    -h | --help | help)
      usage
      ;;
    *)
      usage >&2
      return 2
      ;;
  esac
}

if [[ "${OPS_FALLBACK_SOURCE_ONLY:-0}" != 1 ]]; then
  main "$@"
fi
