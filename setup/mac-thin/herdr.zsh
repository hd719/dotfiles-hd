# Thin-Mac local Herdr lifecycle helpers.

_thin_herdr_route_cwd() {
  emulate -L zsh

  local current_cwd="${PWD:A}"
  local workspace_label="${${PWD:A}:t}"
  local snapshot workspace_id
  local -i attempt

  [[ -n "$workspace_label" ]] || workspace_label=/

  if ! command herdr api snapshot >/dev/null 2>&1; then
    (command herdr server >/dev/null 2>&1 &)
    for attempt in {1..50}; do
      command herdr api snapshot >/dev/null 2>&1 && break
      sleep 0.1
    done
  fi

  snapshot="$(command herdr api snapshot)" || {
    echo "Herdr server did not become ready." >&2
    return 1
  }
  workspace_id="$(
    print -r -- "$snapshot" \
      | /usr/bin/jq -r --arg cwd "$current_cwd" '
          first(
            .result.snapshot.panes[]?
            | select(.cwd == $cwd or .foreground_cwd == $cwd)
            | .workspace_id
          ) // empty
        '
  )" || {
    echo "Herdr returned an invalid session snapshot." >&2
    return 1
  }

  if [[ -n "$workspace_id" ]]; then
    command herdr workspace focus "$workspace_id" >/dev/null
    return
  fi

  command herdr workspace create \
    --label "$workspace_label" \
    --cwd "$current_cwd" \
    --focus \
    >/dev/null
}

_thin_herdr_reset() {
  emulate -L zsh

  local workspace_json workspace_ids_text
  local landing_json landing_id workspace_id
  local -a workspace_ids
  local -i close_failed=0

  if [[ -n "${HERDR_ENV:-}" ]]; then
    echo "Run 'herdr server reset' from a regular terminal, not inside Herdr." >&2
    return 1
  fi

  if ! command herdr api snapshot >/dev/null 2>&1; then
    echo "Herdr server is not running; start it before resetting." >&2
    return 1
  fi

  workspace_json="$(command herdr workspace list)" || return 1
  workspace_ids_text="$(
    print -r -- "$workspace_json" \
      | /usr/bin/jq -r '.result.workspaces[]?.workspace_id'
  )" || {
    echo "Herdr returned an invalid workspace list; server was not stopped." >&2
    return 1
  }
  workspace_ids=("${(@f)workspace_ids_text}")

  landing_json="$(
    command herdr workspace create --label home --cwd "$HOME" --focus
  )" || return 1
  landing_id="$(
    print -r -- "$landing_json" \
      | /usr/bin/jq -r '.result.workspace.workspace_id // empty'
  )"
  if [[ -z "$landing_id" ]]; then
    echo "Herdr did not return the fresh home workspace ID." >&2
    return 1
  fi

  for workspace_id in "${workspace_ids[@]}"; do
    [[ -n "$workspace_id" && "$workspace_id" != "$landing_id" ]] || continue
    if command herdr workspace close "$workspace_id" >/dev/null 2>&1; then
      echo "Closed Herdr workspace: $workspace_id"
    else
      echo "Failed to close Herdr workspace: $workspace_id" >&2
      close_failed=1
    fi
  done

  if (( close_failed )); then
    echo "Herdr was left running because workspace cleanup was incomplete." >&2
    return 1
  fi

  command herdr server stop || return 1
  echo "Herdr stopped. The next start will open one fresh home workspace."
}

# Preserve the normal Herdr CLI and add one thin-Mac reset subcommand.
herdr() {
  emulate -L zsh

  if (( $# == 0 )) && [[ -z "${HERDR_ENV:-}" ]]; then
    _thin_herdr_route_cwd || return 1
    command herdr
    return
  fi

  if (( $# == 2 )) && [[ "$1" == server && "$2" == reset ]]; then
    _thin_herdr_reset
    return
  fi

  command herdr "$@"
}
