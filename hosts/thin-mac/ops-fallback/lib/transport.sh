# Shared command and SSH transport helpers.
#
# Every command writes its exit status and combined output into LAST_STATUS and
# LAST_OUTPUT. Workflow modules can then classify the result without repeating
# temporary-file and SSH handling.

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

# Prefer Tailscale, but retain the reviewed LAN route as a fallback.
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
