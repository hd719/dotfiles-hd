# Mac mini runtime checks: Cortana, PostgreSQL, Hermes, queues, and delivery.
# These functions inspect live state and append rows to the shared result table.

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
  [[ -n "$MAC_HOST" ]] || return

  # Run one Bash program remotely so all related API responses describe the
  # same moment. jq performs the nested JSON matching previously done in
  # embedded Python.
  ssh_bash_capture "$MAC_HOST" <<'BASH'
set -euo pipefail

base=http://127.0.0.1:3033
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
pending=0
actionable_failed=0
monitor_delivery=false
spartan_delivery=false

fetch() {
  curl -fsS --max-time 10 "$base$1" >"$2"
}

for target in monitor spartan; do
  completed="$tmp_dir/$target-completed.json"
  pending_rows="$tmp_dir/$target-pending.json"
  failed_rows="$tmp_dir/$target-failed.json"
  outputs="$tmp_dir/$target-outputs.json"
  fetch "/agent-events?target=$target&status=completed&limit=40" "$completed"
  fetch "/agent-events?target=$target&status=pending&limit=40" "$pending_rows"
  fetch "/agent-events?target=$target&status=failed&limit=40" "$failed_rows"
  fetch "/agent-outputs?agent=$target&limit=20" "$outputs"

  summary="$(jq -cn \
    --slurpfile completed "$completed" \
    --slurpfile pending "$pending_rows" \
    --slurpfile failed "$failed_rows" \
    --slurpfile outputs "$outputs" '
      def events($value): ($value[0].events // []);
      def event_key($event):
        [($event.eventType // ""), ($event.summary // "")] | @json;

      (reduce events($completed)[] as $event ({};
        (event_key($event)) as $key
        | .[$key] = ([
            .[$key] // "",
            ($event.completedAt // $event.updatedAt // "")
          ] | max)
      )) as $replacements
      | {
          pending: (events($pending) | length),
          actionable_failed: ([
            events($failed)[] as $event
            | (($event.priority // "" | tostring | ascii_downcase)) as $priority
            | (($event.eventType // "" | tostring | ascii_downcase)) as $event_type
            | select(
                ($priority == "high" or $priority == "critical")
                or ($event_type | test("warning|action_required"))
              )
            | (event_key($event)) as $key
            | ($event.createdAt // $event.updatedAt // "") as $created
            | select((($replacements[$key] // "") > $created) | not)
          ] | length),
          delivery: (
            any(events($completed)[];
              ((.result.stage? // "" | tostring | ascii_downcase)
                | test("^(webhook_deliver|telegram|delivered)$")))
            or any(($outputs[0].outputs // [])[];
              ((.channel // "" | tostring | ascii_downcase) == "telegram")
              and ((.providerMessageId? // "") != ""))
          )
        }
    ')"

  pending=$((pending + $(printf '%s' "$summary" | jq -r .pending)))
  actionable_failed=$((actionable_failed + $(printf '%s' "$summary" | jq -r .actionable_failed)))
  delivery="$(printf '%s' "$summary" | jq -r .delivery)"
  if [ "$target" = monitor ]; then
    monitor_delivery="$delivery"
  else
    spartan_delivery="$delivery"
  fi
done

jq -cn \
  --argjson pending "$pending" \
  --argjson actionable_failed "$actionable_failed" \
  --argjson monitor "$monitor_delivery" \
  --argjson spartan "$spartan_delivery" \
  '{
    pending: $pending,
    actionable_failed: $actionable_failed,
    delivery: {monitor: $monitor, spartan: $spartan}
  }'
BASH
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
