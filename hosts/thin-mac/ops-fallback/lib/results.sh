# Shared result model and Markdown table helpers.
#
# Bash 3.2 has indexed arrays but no associative arrays. These parallel arrays
# form one result table: every index represents one readiness or recovery row.

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

# Secondary failures intentionally produce READY WITH WARNINGS. Only a core
# failure makes the readiness or recovery command fail at the shell boundary.
home_lab_is_ready() {
  local core_failures
  core_failures="$(count_core_failures)"
  ((core_failures == 0))
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
