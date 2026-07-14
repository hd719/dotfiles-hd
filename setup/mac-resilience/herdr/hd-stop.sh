#!/usr/bin/env bash
#
# hd-stop.sh - Stop Herdr and free lingering dev-server ports WITHOUT touching
# Docker. Stopping the server SIGHUPs the in-pane dev servers; the port sweep
# then clears any stragglers. Docker containers (postgres, hasura :8080, redis,
# the rsw-* containers) are left running on purpose - use res-plat-down to stop
# the backend stack.
#
# Set HD_DRY_RUN=1 to preview every action without stopping or killing anything.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/hd-lib.sh
source "$SCRIPT_DIR/lib/hd-lib.sh"

command -v herdr >/dev/null 2>&1 || {
  echo "hd-stop: 'herdr' not found on PATH" >&2
  exit 1
}

# Dev-server ports used by the platform + pargasite apps. Docker-served ports
# (e.g. Hasura :8080) are intentionally omitted here, and hd_free_port also
# guards against docker-owned listeners, so containers are never killed.
PORTS=(3000 3001 3003 4004 9001 9002 9695)

# 1. Stop the Herdr server (tears down panes -> in-pane dev servers get SIGHUP).
if herdr api snapshot >/dev/null 2>&1; then
  if [ -n "${HD_DRY_RUN:-}" ]; then
    echo "would stop herdr server"
  elif herdr server stop >/dev/null 2>&1; then
    echo "herdr server stopped"
    sleep 1
  else
    echo "herdr server stop reported an error"
  fi
else
  echo "herdr server not running"
fi

# 2. Free any lingering dev-server ports (never touches docker-owned listeners).
echo "freeing dev-server ports:"
for port in "${PORTS[@]}"; do
  hd_free_port "$port"
done

# 3. Docker is left running on purpose.
echo "Docker containers left running (run res-plat-down to stop the backend stack)."
