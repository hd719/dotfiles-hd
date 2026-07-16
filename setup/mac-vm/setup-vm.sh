#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for argument in "$@"; do
  case "$argument" in
    --profile|--profile=*)
      printf 'error: setup-vm.sh always uses the mac-vm profile\n' >&2
      exit 2
      ;;
  esac
done

exec "$SCRIPT_DIR/../mac-bootstrap/bootstrap.sh" --profile mac-vm "$@"
