#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=0

usage() {
  printf 'Usage: reset-server.sh [--dry-run]\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'reset-server.sh: unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

HERDR_BIN="${HERDR_BIN:-$(command -v herdr 2>/dev/null || true)}"
JQ_BIN="${JQ_BIN:-$(command -v jq 2>/dev/null || true)}"

[[ -x "$HERDR_BIN" ]] || {
  echo "reset-server.sh: 'herdr' not found on PATH" >&2
  exit 1
}
[[ -x "$JQ_BIN" ]] || {
  echo "reset-server.sh: 'jq' not found on PATH" >&2
  exit 1
}

# Reset only a live server. A stopped server may still have saved state, which
# the profile-specific hd-stop command handles without starting Herdr.
if ! "$HERDR_BIN" api snapshot >/dev/null 2>&1; then
  echo "Herdr server is not running; start it before resetting." >&2
  exit 1
fi

# One workspace owns this shell when the reset runs inside Herdr. It has to be
# closed last, and the server has to stay up so this client keeps running.
INSIDE_WORKSPACE=""
if [[ -n "${HERDR_ENV:-}" ]]; then
  INSIDE_WORKSPACE="${HERDR_WORKSPACE_ID:-}"
  if [[ -z "$INSIDE_WORKSPACE" ]]; then
    echo "Herdr did not report which workspace owns this shell." >&2
    echo "Run the reset from a regular terminal instead." >&2
    exit 1
  fi
fi

# Capture the old IDs before creating the one workspace that must survive.
workspace_json="$("$HERDR_BIN" workspace list)" || exit 1
if ! workspace_ids="$(
  printf '%s\n' "$workspace_json" \
    | "$JQ_BIN" -r '.result.workspaces[]?.workspace_id'
)"; then
  echo "Herdr returned an invalid workspace list; nothing was closed." >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Would create one fresh home workspace at $HOME."
  while IFS= read -r workspace_id; do
    [[ -n "$workspace_id" ]] || continue
    echo "Would close Herdr workspace: $workspace_id"
  done <<< "$workspace_ids"
  if [[ -n "$INSIDE_WORKSPACE" ]]; then
    echo "Would leave the server running for this Herdr client."
  else
    echo "Would stop Herdr."
  fi
  exit 0
fi

# Create the landing workspace first so Herdr is never left with zero
# workspaces, and focus it so this client is already elsewhere before its own
# workspace closes.
landing_json="$(
  "$HERDR_BIN" workspace create --label home --cwd "$HOME" --focus
)" || exit 1
landing_id="$(
  printf '%s\n' "$landing_json" \
    | "$JQ_BIN" -r '.result.workspace.workspace_id // empty'
)"
if [[ -z "$landing_id" ]]; then
  echo "Herdr did not return the fresh home workspace ID." >&2
  exit 1
fi

close_failed=0
while IFS= read -r workspace_id; do
  [[ -n "$workspace_id" ]] || continue
  [[ "$workspace_id" != "$landing_id" ]] || continue
  [[ -z "$INSIDE_WORKSPACE" || "$workspace_id" != "$INSIDE_WORKSPACE" ]] || continue
  if "$HERDR_BIN" workspace close "$workspace_id" >/dev/null 2>&1; then
    echo "Closed Herdr workspace: $workspace_id"
  else
    echo "Failed to close Herdr workspace: $workspace_id" >&2
    close_failed=1
  fi
done <<< "$workspace_ids"

if [[ "$close_failed" -ne 0 ]]; then
  echo "Herdr was left running because workspace cleanup was incomplete." >&2
  exit 1
fi

if [[ -n "$INSIDE_WORKSPACE" ]]; then
  echo "Herdr keeps running with one fresh home workspace."
  # Closing the workspace that owns this shell can terminate this process, so
  # it must remain the final action.
  "$HERDR_BIN" workspace close "$INSIDE_WORKSPACE" >/dev/null 2>&1 || true
  exit 0
fi

"$HERDR_BIN" server stop
echo "Herdr stopped. The next start will open one fresh home workspace."
