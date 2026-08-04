# Read-only home-lab readiness orchestration and its Markdown report.
# Routine maintenance remains owned by the separately deployed Hermes runner.

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
    local remote_content remote_date remote_report
    ssh_capture "$MAC_HOST" 'date +%F'
    remote_date="$LAST_OUTPUT"
    [[ "$remote_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || remote_date="$report_date"
    remote_report="/Users/h/Desktop/Home Lab Readiness Briefs/home-lab-readiness-${remote_date}-manual.md"
    ssh_capture "$MAC_HOST" 'mkdir -p "/Users/h/Desktop/Home Lab Readiness Briefs"'
    if ((LAST_STATUS == 0)); then
      # The local and remote copies need paths that are valid on their own host.
      remote_content="$(/usr/bin/sed \
        "s|^- Report: .*|- Report: $remote_report|" "$report")"
      capture_with_input "$remote_content" "$SSH_BIN" "${SSH_OPTIONS[@]}" "$MAC_HOST" \
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
  home_lab_is_ready
}
