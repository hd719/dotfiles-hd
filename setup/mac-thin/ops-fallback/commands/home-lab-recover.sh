# Approved no-agent recovery branches.
# Recovery stays surgical: PostgreSQL ownership, stopped Cortana services, and
# stopped Hermes gateways only. Unknown states are reported, never improvised.

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
  home_lab_is_ready
}
