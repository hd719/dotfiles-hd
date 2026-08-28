#!/usr/bin/env bash

set -uo pipefail

# Manual, no-agent entrypoint for Hamel's home lab.
#
# The implementation is intentionally split by responsibility under
# hosts/thin-mac/ops-fallback/. Start here to see the command routing, then
# open only the module for the workflow you are trying to understand.
# Keep its allowlist aligned with home-lab-readiness and
# home-lab-outage-recovery when those skill contracts change.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_ROOT="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
OPS_REPORT_ROOT="${OPS_FALLBACK_REPORT_DIR:-$HOME/Desktop/Ops Fallback Reports}"
SSH_BIN="${OPS_FALLBACK_SSH_BIN:-/usr/bin/ssh}"
ZSH_BIN="${OPS_FALLBACK_ZSH_BIN:-/bin/zsh}"
BREW_BIN="${OPS_FALLBACK_BREW_BIN:-/opt/homebrew/bin/brew}"
SSH_OPTIONS=(-o BatchMode=yes -o ConnectTimeout=8 -o ServerAliveInterval=5 -o ServerAliveCountMax=2)

# Modules share these small state variables because macOS ships Bash 3.2,
# which has no convenient namespaced data structure for a shell application.
LAST_STATUS=0
LAST_OUTPUT=""
MAC_HOST=""
RESULT_STATUS=()
RESULT_SCOPE=()
RESULT_AREA=()
RESULT_EVIDENCE=()
RESULT_NEXT=()
ADVISORIES=()
RECOVERY_ACTIONS=()
POSTGRES_OWNERSHIP_OK=0

OPS_MODULE_ROOT="$SCRIPT_DIR/ops-fallback"
OPS_MODULES=(
  lib/transport.sh
  lib/results.sh
  lib/dates.sh
  checks/runtime.sh
  checks/infrastructure.sh
  checks/providers.sh
  commands/home-lab-ready.sh
  commands/home-lab-recover.sh
)

# Source in dependency order: shared helpers first, workflows last.
for module in "${OPS_MODULES[@]}"; do
  module_path="$OPS_MODULE_ROOT/$module"
  if [[ ! -r "$module_path" ]]; then
    printf 'Missing ops fallback module: %s\n' "$module_path" >&2
    exit 1
  fi
  # shellcheck source=/dev/null
  source "$module_path"
done
unset module module_path

usage() {
  printf '%s\n' \
    'Usage:' \
    '  ops-fallback.sh home-lab-ready [AWAY_START AWAY_END]' \
    '  ops-fallback.sh home-lab-recover' \
    '' \
    'Runs unattended. Known safe work is automatic; risky or unknown states' \
    'stop with an exact next action in the saved Markdown report.'
}

main() {
  local command="${1:-}"
  case "$command" in
    home-lab-ready)
      (($# == 1 || $# == 3)) || {
        usage >&2
        return 2
      }
      run_home_lab_ready "${2:-}" "${3:-}"
      ;;
    home-lab-recover)
      (($# == 1)) || {
        usage >&2
        return 2
      }
      run_home_lab_recover
      ;;
    -h | --help | help)
      usage
      ;;
    *)
      usage >&2
      return 2
      ;;
  esac
}

if [[ "${OPS_FALLBACK_SOURCE_ONLY:-0}" != 1 ]]; then
  main "$@"
fi
