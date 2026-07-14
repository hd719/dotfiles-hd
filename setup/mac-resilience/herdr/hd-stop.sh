#!/usr/bin/env bash
#
# hd-stop.sh - Free dev-server ports and clear all Herdr spaces, leaving you in
# a single fresh space. Docker is never touched (run res-plat-down to stop the
# backend stack).
#
# Why not `herdr server stop`? With the app attached, Herdr relaunches the
# server and restores spaces from session.json, so stopping the server clears
# nothing. Closing spaces over the API actually removes them. Ports are freed
# first so the sweep still runs even when hd-stop is launched from inside a pane
# that is about to be closed.
#
# Set HD_DRY_RUN=1 to preview every action without changing anything.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/hd-lib.sh
source "$SCRIPT_DIR/lib/hd-lib.sh"

hd_require

# Dev-server ports used by the platform + pargasite apps. Docker-served ports
# (e.g. Hasura :8080) are omitted, and hd_free_port also guards against
# docker-owned listeners, so containers are never killed.
PORTS=(3000 3001 3003 4004 9001 9002 9695)

# 1. Free dev-server ports first so this always completes, even if we are about
#    to close the pane we are running in.
echo "freeing dev-server ports:"
for port in "${PORTS[@]}"; do
  hd_free_port "$port"
done

# 2. Clear spaces via the API (this is what actually defeats the persistence
#    restore). Nothing to do if no server is running.
if ! herdr api snapshot >/dev/null 2>&1; then
  echo "herdr server not running; no spaces to clear."
  echo "Docker containers left running (run res-plat-down to stop the backend stack)."
  exit 0
fi

CURRENT="${HERDR_WORKSPACE_ID:-}"

# Create a fresh landing space (and focus it) so we never end at zero spaces and
# so the app drops onto a clean slate.
if [ -n "${HD_DRY_RUN:-}" ]; then
  echo "would create a fresh 'home' space and focus it"
  LANDING="__dry_run__"
else
  LANDING="$(herdr workspace create --label home --focus | jq -r '.result.workspace.workspace_id')"
  echo "created fresh space: home ($LANDING)"
fi

# Close every space except the landing one. Close the current space (the one
# this script runs in) LAST, so all other spaces are gone before our own pane
# disappears.
echo "closing spaces:"
while read -r ws label; do
  [ "$ws" = "$LANDING" ] && continue
  [ -n "$CURRENT" ] && [ "$ws" = "$CURRENT" ] && continue
  if [ -n "${HD_DRY_RUN:-}" ]; then
    echo "  would close $ws ($label)"
  elif herdr workspace close "$ws" >/dev/null 2>&1; then
    echo "  closed $ws ($label)"
  else
    echo "  failed to close $ws ($label)"
  fi
done < <(herdr workspace list | jq -r '.result.workspaces[] | "\(.workspace_id) \(.label)"')

# Close the space we launched from, last.
if [ -n "$CURRENT" ] && [ "$CURRENT" != "$LANDING" ]; then
  if [ -n "${HD_DRY_RUN:-}" ]; then
    echo "  would close current space $CURRENT (last)"
  else
    echo "  closing current space $CURRENT (last)"
    herdr workspace close "$CURRENT" >/dev/null 2>&1 || true
  fi
fi

echo "Docker containers left running (run res-plat-down to stop the backend stack)."
