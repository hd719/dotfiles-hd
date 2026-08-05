# Portable Herdr routing and optional reset wrapper for supported hosts.

typeset -g _dotfiles_herdr_module="${${(%):-%N}:A}"
typeset -g _dotfiles_herdr_reset_script="${_dotfiles_herdr_module:h:h:h}/herdr/reset-server.sh"
typeset -gi _dotfiles_herdr_route_plain="${DOTFILES_HERDR_ROUTE_CWD:-0}"
typeset -gi _dotfiles_herdr_reset_enabled="${DOTFILES_HERDR_RESET_ENABLED:-1}"
unset _dotfiles_herdr_module

_dotfiles_herdr_route_cwd() {
  emulate -L zsh

  local current_cwd="${PWD:A}"
  local workspace_label="${${PWD:A}:t}"
  local snapshot workspace_id jq_bin
  local -i attempt

  [[ -n "$workspace_label" ]] || workspace_label=/
  jq_bin="$(command -v jq 2>/dev/null)" || {
    echo "Herdr workspace routing requires jq." >&2
    return 1
  }

  # Plain Herdr attaches to saved state, so start its server first and use the
  # API to focus or create the workspace that matches the invoking directory.
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
      | "$jq_bin" -r --arg cwd "$current_cwd" '
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

if (( _dotfiles_herdr_reset_enabled )); then
  _dotfiles_herdr_reset() {
    emulate -L zsh
    "$_dotfiles_herdr_reset_script"
  }
else
  unfunction _dotfiles_herdr_reset 2>/dev/null || true
fi

herdr() {
  emulate -L zsh

  # Current-directory routing and reset are enabled independently by profiles.
  if (( $# == 0 && _dotfiles_herdr_route_plain == 1 )) \
    && [[ -z "${HERDR_ENV:-}" ]]; then
    _dotfiles_herdr_route_cwd || return 1
    command herdr
    return
  fi

  if (( _dotfiles_herdr_reset_enabled && $# == 2 )) \
    && [[ "$1" == server && "$2" == reset ]]; then
    _dotfiles_herdr_reset
    return
  fi

  command herdr "$@"
}
