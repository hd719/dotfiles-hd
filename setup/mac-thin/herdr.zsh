# Thin-Mac local Herdr lifecycle helpers.

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

  if (( $# == 2 )) && [[ "$1" == server && "$2" == reset ]]; then
    _thin_herdr_reset
    return
  fi

  command herdr "$@"
}
