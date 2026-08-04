# Secondary provider readiness checks.
#
# Fallback-owned parsing is Bash plus jq. The final Google Workspace command
# invokes its existing Python-owned helper, but no Python program is embedded
# or maintained in this dotfiles workflow.

check_secondary_providers() {
  local away_end="$1"
  local google_payload
  [[ -n "$MAC_HOST" ]] || return

  # Collect one compact, secret-free summary on the Mac mini. curl captures
  # HTTP status and jq handles recursive provider JSON matching.
  ssh_bash_capture "$MAC_HOST" <<'BASH'
set -euo pipefail

tmp_dir="$(mktemp -d -t provider-fallback.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

request_json() {
  url="$1"
  body="$2"
  shift 2
  status="$(/usr/bin/curl -sS --connect-timeout 8 --max-time 12 \
    -o "$body" -w '%{http_code}' "$@" "$url")" || return 1
  if ! /usr/bin/jq -e . "$body" >/dev/null 2>&1; then
    if [ "$status" -ge 400 ] 2>/dev/null; then
      printf '{}\n' >"$body"
    else
      return 1
    fi
  fi
  printf '%s\n' "$status"
}

provider_matches() {
  document="$1"
  provider="$2"
  /usr/bin/jq -c --arg provider "$provider" '
    ([
      .. | objects
      | select(
          ((.provider // .providerId // .name // .displayName // "")
            | tostring | ascii_downcase) == $provider
        )
    ] + [
      .. | objects | to_entries[]
      | select((.key | ascii_downcase) == $provider)
      | .value
    ])
  ' "$document"
}

readiness="$tmp_dir/readiness.json"
readiness_code="$(request_json http://127.0.0.1:3033/provider-readiness "$readiness")"
printf 'readiness_http=%s\n' "$readiness_code"

for provider in whoop tonal; do
  matches="$(provider_matches "$readiness" "$provider")"
  if ! printf '%s' "$matches" | /usr/bin/jq -e 'length > 0' >/dev/null; then
    provider_status=FAIL
  elif printf '%s' "$matches" | /usr/bin/jq -e '
      tostring | ascii_downcase | test("reauth|rejected|missing_token|manual_action")
    ' >/dev/null; then
    provider_status=FAIL
  elif printf '%s' "$matches" | /usr/bin/jq -e '
      tostring | ascii_downcase | test("stale|delay|waiting")
    ' >/dev/null; then
    provider_status=WARN
  else
    provider_status=PASS
  fi
  printf 'provider=%s|status=%s\n' "$provider" "$provider_status"
done

for spec in \
  'schwab-rest|auth/schwab/status' \
  'schwab-streamer|auth/schwab/streamer/status'; do
  name="${spec%%|*}"
  path="${spec#*|}"
  body="$tmp_dir/$name.json"
  code="$(request_json "http://127.0.0.1:9130/$path" "$body")"
  state="$(/usr/bin/jq -r '(.status // .data.status // "") | tostring | ascii_downcase' "$body")"
  issued="$(/usr/bin/jq -r '.refreshTokenIssuedAt // .data.refreshTokenIssuedAt // "missing"' "$body")"
  printf 'provider=%s|http=%s|state=%s|issued=%s\n' "$name" "$code" "$state" "$issued"
done

polymarket_auth_failure=false
polymarket_failure=false
polymarket_critical=false
polymarket_waiting=false
polymarket_matches="$(provider_matches "$readiness" polymarket)"
if printf '%s' "$polymarket_matches" | /usr/bin/jq -e '
    any(.. | objects;
      ((.status? // "" | tostring | ascii_downcase) == "waiting")
      or ((.action? // "" | tostring | ascii_downcase) == "wait"))
  ' >/dev/null; then
  polymarket_waiting=true
fi

for path in health balances positions orders; do
  body="$tmp_dir/polymarket-${path}.json"
  code="$(request_json "http://127.0.0.1:9130/polymarket/$path" "$body" \
    -H 'x-cortana-caller: home-lab-readiness:manual-fallback' \
    -H 'x-cortana-source-route: home-lab-readiness')"
  case "$code" in 401 | 403) polymarket_auth_failure=true ;; esac
  if [ "$code" -ge 500 ] 2>/dev/null; then polymarket_failure=true; fi
done

live_index=0
for url in \
  'http://127.0.0.1:9130/polymarket/live?seedPrivateAccount=false' \
  'http://127.0.0.1:3033/polymarket/operator-state' \
  'http://127.0.0.1:3000/api/polymarket/live'; do
  live_index=$((live_index + 1))
  body="$tmp_dir/polymarket-live-$live_index.json"
  code="$(request_json "$url" "$body" \
    -H 'x-cortana-caller: home-lab-readiness:manual-fallback' \
    -H 'x-cortana-source-route: home-lab-readiness')"
  case "$code" in 401 | 403) polymarket_auth_failure=true ;; esac
  if [ "$code" -ge 500 ] 2>/dev/null; then polymarket_failure=true; fi
  if /usr/bin/jq -e 'tostring | ascii_downcase | contains("reauth")' "$body" >/dev/null; then
    polymarket_auth_failure=true
  fi
  if /usr/bin/jq -e 'tostring | ascii_downcase | contains("restart_provider_gateway")' "$body" >/dev/null; then
    polymarket_critical=true
  fi
  if /usr/bin/jq -e '
      any(.. | objects;
        ((.status? // "" | tostring | ascii_downcase) == "waiting")
        or ((.action? // "" | tostring | ascii_downcase) == "wait"))
    ' "$body" >/dev/null; then
    polymarket_waiting=true
  fi
done

printf 'provider=polymarket|auth_failure=%s|critical=%s|waiting=%s|upstream_failure=%s\n' \
  "$polymarket_auth_failure" "$polymarket_critical" \
  "$polymarket_waiting" "$polymarket_failure"
BASH
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

    local schwab_line issued issued_epoch mark_epoch mark mark_date state now_epoch
    now_epoch="$(/bin/date +%s)"
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

      issued_epoch="$(iso8601_to_epoch "$issued")" || issued_epoch=""
      if [[ -z "$issued_epoch" ]]; then
        add_result FAIL secondary "Provider: $provider" "refresh-token date was invalid" \
          "Reauthorize Schwab manually"
        continue
      fi
      mark_epoch=$((issued_epoch + 7 * 86400))
      mark="$(epoch_to_iso8601 "$mark_epoch")" || mark=""
      mark_date="${mark%%T*}"

      if [[ -z "$mark" ]] || ((mark_epoch - now_epoch < 72 * 3600)); then
        add_result FAIL secondary "Provider: $provider" "refresh-token 7-day mark $mark is under 72 hours" \
          "Reauthorize Schwab manually"
      elif [[ -n "$away_end" && "$mark_date" < "$away_end" ]]; then
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

  # Google Workspace owns a Python helper and dependencies in the Hermes venv.
  # We invoke that external contract as-is; this Bash fallback does not embed or
  # duplicate its implementation.
  google_payload='HERMES_PY=/Users/h/.hermes/hermes-agent/venv/bin/python; HERMES_HOME=/Users/h/.hermes "$HERMES_PY" -c "import googleapiclient, google_auth_oauthlib" && HERMES_HOME=/Users/h/.hermes "$HERMES_PY" /Users/h/.hermes/skills/productivity/google-workspace/scripts/setup.py --check-live >/dev/null'
  ssh_capture "$MAC_HOST" "$google_payload"
  record_command_result PASS FAIL secondary "Google Workspace" \
    "live Gmail/Calendar check passed" "live check or dependency import failed" \
    "Run the Google Workspace setup check manually"
}
