# Bash-only date helpers for the thin Mac's BSD date implementation.
#
# Keep all date parsing here. That makes the provider checks readable and
# avoids embedding a second programming language in the fallback.

date_only_to_epoch() {
  local value="$1"
  local normalized=""

  normalized="$(/bin/date -j -f '%Y-%m-%d' "$value" '+%Y-%m-%d' 2>/dev/null)" \
    || return 1
  [[ "$normalized" == "$value" ]] || return 1
  /bin/date -j -f '%Y-%m-%d' "$value" '+%s' 2>/dev/null
}

iso8601_to_epoch() {
  local value="$1"
  local normalized=""

  # BSD date cannot parse fractional seconds or a colon in a numeric offset.
  normalized="$(printf '%s\n' "$value" \
    | /usr/bin/sed -E \
      -e 's/\.[0-9]+(Z|[+-][0-9]{2}:[0-9]{2})$/\1/' \
      -e 's/([+-][0-9]{2}):([0-9]{2})$/\1\2/')"

  case "$normalized" in
    *Z)
      TZ=UTC0 /bin/date -j -f '%Y-%m-%dT%H:%M:%SZ' "$normalized" '+%s' 2>/dev/null
      ;;
    *[+-][0-9][0-9][0-9][0-9])
      /bin/date -j -f '%Y-%m-%dT%H:%M:%S%z' "$normalized" '+%s' 2>/dev/null
      ;;
    *)
      TZ=UTC0 /bin/date -j -f '%Y-%m-%dT%H:%M:%S' "$normalized" '+%s' 2>/dev/null
      ;;
  esac
}

epoch_to_iso8601() {
  TZ=UTC0 /bin/date -u -r "$1" '+%Y-%m-%dT%H:%M:%S+00:00' 2>/dev/null
}

validate_away_window() {
  local start="${1:-}"
  local end="${2:-}"
  local start_epoch=""
  local end_epoch=""

  if [[ -z "$start" && -z "$end" ]]; then
    return 0
  fi
  [[ -n "$start" && -n "$end" ]] || return 1
  start_epoch="$(date_only_to_epoch "$start")" || return 1
  end_epoch="$(date_only_to_epoch "$end")" || return 1
  ((start_epoch <= end_epoch))
}
