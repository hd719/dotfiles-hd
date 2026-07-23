#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf 'warning: setup-vm.sh is deprecated; use setup/mac-pro/setup.sh\n' >&2
exec "$SCRIPT_DIR/setup.sh" "$@"
