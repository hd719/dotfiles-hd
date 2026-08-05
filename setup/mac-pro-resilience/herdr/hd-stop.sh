#!/usr/bin/env bash
#
# hd-stop.sh - Free dev-server ports, reset Herdr to one home workspace, and
# stop its server. Docker is never touched (run res-plat-down to stop the
# backend stack).
#
# Herdr cleanup runs as a launchd job so it survives closing the workspace that
# launched hd-stop. Set HD_DRY_RUN=1 to preview every action.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESET_SCRIPT="$REPO_DIR/config/herdr/reset-server.sh"

# shellcheck source=lib/hd-lib.sh
source "$SCRIPT_DIR/lib/hd-lib.sh"

hd_require
command -v launchctl >/dev/null 2>&1 || {
  echo "hd-stop: 'launchctl' not found" >&2
  exit 1
}
[[ -x "$RESET_SCRIPT" ]] || {
  echo "hd-stop: reset helper is missing or not executable: $RESET_SCRIPT" >&2
  exit 1
}

HERDR_BIN="$(command -v herdr)"
JQ_BIN="$(command -v jq)"
if [[ -n "${HERDR_CONFIG_PATH:-}" ]]; then
  STATE_DIR="$(dirname "$HERDR_CONFIG_PATH")"
else
  STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/herdr"
fi

# Dev-server ports used by the platform + pargasite apps. Docker-served ports
# are omitted, and hd_free_port also guards against Docker-owned listeners.
PORTS=(3000 3001 3003 4004 9001 9002 9695)

echo "freeing dev-server ports:"
for port in "${PORTS[@]}"; do
  hd_free_port "$port"
done

if ! "$HERDR_BIN" api snapshot >/dev/null 2>&1; then
  if [[ -n "${HD_DRY_RUN:-}" ]]; then
    echo "would remove saved Herdr workspace state"
  else
    rm -f "$STATE_DIR/session.json" "$STATE_DIR/session-history.json"
    echo "Herdr already stopped; saved workspace state removed."
  fi
  echo "Docker containers left running (run res-plat-down to stop the backend stack)."
  exit 0
fi

if [[ -n "${HD_DRY_RUN:-}" ]]; then
  HOME="$HOME" HERDR_BIN="$HERDR_BIN" JQ_BIN="$JQ_BIN" \
    "$RESET_SCRIPT" --allow-inside-herdr --dry-run
else
  teardown_log="${TMPDIR:-/tmp}/hd-stop-$$.log"
  launchctl submit \
    -l "com.hd.herdr-reset.$$" \
    -o "$teardown_log" \
    -e "$teardown_log" \
    -- /usr/bin/env \
      "HOME=$HOME" \
      "HERDR_BIN=$HERDR_BIN" \
      "JQ_BIN=$JQ_BIN" \
      "$RESET_SCRIPT" \
      --allow-inside-herdr
  echo "Herdr reset started; details: $teardown_log"
fi

echo "Docker containers left running (run res-plat-down to stop the backend stack)."
