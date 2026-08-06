# Infrastructure checks for Tailscale, TrueNAS, and Home Assistant.
# Keep host-specific SSH payloads here so the command modules remain readable.

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
  ssh_capture homeassistant-ts 'ha core info >/dev/null && ha resolution info >/dev/null'
  record_command_result PASS FAIL core "Home Assistant host" \
    "core and resolution surfaces passed" "Home Assistant CLI checks failed" \
    "ssh homeassistant-ts 'ha core info'"

  [[ -n "$MAC_HOST" ]] || return
  # Read only the two required settings. Never source the whole environment
  # file, and keep the bearer token out of the process list and captured output.
  ssh_bash_capture "$MAC_HOST" <<'BASH'
set -euo pipefail

env_file=/Users/h/.hermes/.env
test -r "$env_file" || exit 2

env_value() {
  key="$1"
  /usr/bin/awk -v wanted="$key" '
    /^[[:space:]]*#/ { next }
    index($0, "=") {
      name = substr($0, 1, index($0, "=") - 1)
      value = substr($0, index($0, "=") + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (name == wanted) found = value
    }
    END { if (found != "") print found }
  ' "$env_file"
}

strip_quotes() {
  value="$1"
  case "$value" in
    \"*\") value="${value#\"}"; value="${value%\"}" ;;
    \'*\') value="${value#\'}"; value="${value%\'}" ;;
  esac
  printf '%s' "$value"
}

url="$(strip_quotes "$(env_value HASS_URL)")"
test -n "$url" || url="$(strip_quotes "$(env_value HOME_ASSISTANT_URL)")"
token="$(strip_quotes "$(env_value HASS_TOKEN)")"
test -n "$token" || token="$(strip_quotes "$(env_value HOME_ASSISTANT_TOKEN)")"
url="${url%/}"

if test -n "$url"; then printf 'url=present\n'; else printf 'url=missing\n'; fi
if test -n "$token"; then printf 'token=present\n'; else printf 'token=missing\n'; fi
test -n "$url" -a -n "$token" || exit 2

tmp_dir="$(mktemp -d -t ha-fallback.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT
chmod 700 "$tmp_dir"
config="$tmp_dir/curl.conf"
states="$tmp_dir/states.json"

curl_escape() {
  printf '%s' "$1" | /usr/bin/sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

umask 077
{
  printf 'url = "%s/api/states"\n' "$(curl_escape "$url")"
  printf 'request = "GET"\n'
  printf 'connect-timeout = 8\n'
  printf 'max-time = 12\n'
  printf 'silent\nshow-error\nfail\n'
  printf 'header = "Authorization: Bearer %s"\n' "$(curl_escape "$token")"
  printf 'header = "Content-Type: application/json"\n'
} >"$config"
chmod 600 "$config"

/usr/bin/curl --config "$config" >"$states"
/usr/bin/jq -e 'type == "array"' "$states" >/dev/null
printf 'states_count=%s\n' "$(/usr/bin/jq 'length' "$states")"
BASH
  if ((LAST_STATUS == 0)); then
    add_result PASS core "Hermes Home Assistant integration" "$LAST_OUTPUT" "None"
  else
    add_result FAIL core "Hermes Home Assistant integration" "configured read-only API check failed" \
      "Repair URL/token manually; do not print credentials"
  fi
}
