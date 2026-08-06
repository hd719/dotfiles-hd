#!/usr/bin/env bash
#
# hd-lib.sh - shared helpers for the Herdr launch scripts (hd-*.sh).
#
# These mirror the tmux tm-*.sh launchers but drive Herdr's socket API instead
# of tmux. The mapping is:
#
#   tmux session   -> Herdr workspace
#   tmux window    -> Herdr tab (each tab has one root pane)
#   send-keys ... C-m -> herdr pane run <pane_id> "<cmd>"
#   attach -t X    -> focus the workspace, then attach the Herdr client
#
# Commands are typed into each pane's interactive zsh, so the existing res-*
# aliases in ~/.zshrc resolve exactly like they do under tmux.
#
# Requires: herdr, jq.

# Fail fast if the tools we depend on are missing.
hd_require() {
  command -v herdr >/dev/null 2>&1 || {
    echo "hd-lib: 'herdr' not found on PATH" >&2
    exit 1
  }
  command -v jq >/dev/null 2>&1 || {
    echo "hd-lib: 'jq' not found on PATH (brew install jq)" >&2
    exit 1
  }
}

# Ensure a Herdr server is running so the socket API calls below succeed.
# `herdr api snapshot` only succeeds against a live server, so we use it as the
# readiness probe and start a headless server if none is up.
hd_ensure_server() {
  if herdr api snapshot >/dev/null 2>&1; then
    return 0
  fi

  (herdr server >/dev/null 2>&1 &)

  local i
  for i in $(seq 1 50); do
    if herdr api snapshot >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.2
  done

  echo "hd-lib: Herdr server did not become ready" >&2
  exit 1
}

# Close any workspace(s) with the given label, then create a fresh one.
# Echoes: "<workspace_id> <root_tab_id> <root_pane_id>"
# Usage: read -r WS TAB PANE <<< "$(hd_workspace_reset <label> [cwd])"
hd_workspace_reset() {
  local label="$1"
  local cwd="${2:-}"

  local existing
  existing="$(herdr workspace list 2>/dev/null \
    | jq -r --arg l "$label" '.result.workspaces[] | select(.label == $l) | .workspace_id')"

  local id
  for id in $existing; do
    herdr workspace close "$id" >/dev/null 2>&1 || true
  done

  local out
  if [ -n "$cwd" ]; then
    out="$(herdr workspace create --label "$label" --cwd "$cwd" --no-focus)"
  else
    out="$(herdr workspace create --label "$label" --no-focus)"
  fi

  echo "$out" | jq -r \
    '[.result.workspace.workspace_id, .result.root_pane.tab_id, .result.root_pane.pane_id] | join(" ")'
}

# Create a new tab in a workspace. Echoes the tab's root pane id.
# Usage: PANE="$(hd_tab <workspace_id> <label> [cwd])"
hd_tab() {
  local ws="$1"
  local label="$2"
  local cwd="${3:-}"

  local out
  if [ -n "$cwd" ]; then
    out="$(herdr tab create --workspace "$ws" --label "$label" --cwd "$cwd" --no-focus)"
  else
    out="$(herdr tab create --workspace "$ws" --label "$label" --no-focus)"
  fi

  echo "$out" | jq -r '.result.root_pane.pane_id'
}

# Rename a tab (cosmetic; never fatal).
# Usage: hd_rename_tab <tab_id> <label>
hd_rename_tab() {
  herdr tab rename "$1" "$2" >/dev/null 2>&1 || true
}

# Run a command in a pane (types the text and presses Enter).
# Usage: hd_run <pane_id> "<command>"
hd_run() {
  herdr pane run "$1" "$2" >/dev/null
}

# Block until a pane prints matching text (replacement for `until curl; sleep`).
# Usage: hd_wait <pane_id> "<match>" [timeout_ms] [--regex]
hd_wait() {
  local pane="$1"
  local match="$2"
  local timeout="${3:-300000}"
  shift 3 2>/dev/null || shift $#
  herdr wait output "$pane" --match "$match" --timeout "$timeout" "$@" >/dev/null
}

# Focus the workspace and attach the Herdr client, mirroring `tmux attach`.
# - Skips attaching when HD_NO_ATTACH is set (useful for scripted setup/tests).
# - When already inside a Herdr pane (HERDR_ENV set) it only focuses, since
#   nesting a client would not make sense.
# Usage: hd_focus_attach <workspace_id>
hd_focus_attach() {
  local ws="$1"
  herdr workspace focus "$ws" >/dev/null 2>&1 || true

  if [ -n "${HD_NO_ATTACH:-}" ] || [ -n "${HERDR_ENV:-}" ]; then
    return 0
  fi

  exec herdr
}

# Free a TCP port by killing its LISTEN process, unless that process is
# Docker-owned (so containers and their published ports are never touched).
# Honors HD_DRY_RUN=1 (report only, no kill).
# Usage: hd_free_port <port>
hd_free_port() {
  local port="$1"

  local pids
  pids="$(lsof -ti tcp:"$port" -sTCP:LISTEN 2>/dev/null || true)"
  if [ -z "$pids" ]; then
    echo "  :$port already free"
    return 0
  fi

  local pid cmd
  for pid in $pids; do
    cmd="$(ps -p "$pid" -o comm= 2>/dev/null | xargs || true)"
    case "$cmd" in
      *docker*|*Docker*|*com.docker*|*vpnkit*|*colima*)
        echo "  :$port skipped (docker-owned: ${cmd:-pid $pid})"
        ;;
      *)
        if [ -n "${HD_DRY_RUN:-}" ]; then
          echo "  :$port would kill ${cmd:-pid} (pid $pid)"
        elif kill -9 "$pid" 2>/dev/null; then
          echo "  :$port freed (killed ${cmd:-pid}, pid $pid)"
        else
          echo "  :$port kill failed (pid $pid)"
        fi
        ;;
    esac
  done
}
