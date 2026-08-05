#!/usr/bin/env bash
#
# hd-stop.sh - Free dev-server ports, then stop Herdr through its native command.
# Docker is never touched (run res-plat-down to stop the backend stack).
#
# No workspaces or saved session files are created, closed, or removed.
# Set HD_DRY_RUN=1 to preview every action.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/hd-lib.sh
source "$SCRIPT_DIR/lib/hd-lib.sh"

command -v herdr >/dev/null 2>&1 || {
  echo "hd-stop: 'herdr' not found on PATH" >&2
  exit 1
}

# Dev-server ports used by the platform + pargasite apps. Docker-served ports
# are omitted, and hd_free_port also guards against Docker-owned listeners.
PORTS=(3000 3001 3003 4004 9001 9002 9695)

echo "freeing dev-server ports:"
for port in "${PORTS[@]}"; do
  hd_free_port "$port"
done

if herdr api snapshot >/dev/null 2>&1; then
  if [[ -n "${HD_DRY_RUN:-}" ]]; then
    echo "would stop Herdr through its native server stop command"
  elif herdr server stop >/dev/null 2>&1; then
    echo "Herdr server stopped."
  else
    echo "Herdr server stop reported an error." >&2
  fi
else
  echo "Herdr server not running."
fi

echo "Docker containers left running (run res-plat-down to stop the backend stack)."
