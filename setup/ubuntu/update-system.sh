#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
OS_RELEASE_FILE="${DOTFILES_OS_RELEASE_FILE:-/etc/os-release}"
NEOVIM_SETUP_SCRIPT="${DOTFILES_NEOVIM_SETUP_SCRIPT:-$SCRIPT_DIR/setup-neovim.sh}"

print_usage() {
  cat <<'EOF'
Usage: update-system.sh

Update the lean Ubuntu workstation through APT and refresh the pinned mise and
Neovim daily-driver setup.
EOF
}

log() {
  printf '\n==> %s\n' "$1"
}

require_ubuntu() {
  [[ -r "$OS_RELEASE_FILE" ]] || {
    printf 'Cannot read %s.\n' "$OS_RELEASE_FILE" >&2
    exit 1
  }

  # shellcheck disable=SC1090
  source "$OS_RELEASE_FILE"
  if [[ "${ID:-}" != "ubuntu" ]]; then
    printf 'This updater supports Ubuntu only (detected: %s).\n' "${ID:-unknown}" >&2
    exit 1
  fi
}

main() {
  if (($# > 1)); then
    print_usage >&2
    exit 2
  fi

  if (($# > 0)); then
    case "$1" in
      -h | --help)
        print_usage
        exit 0
        ;;
      *)
        print_usage >&2
        exit 2
        ;;
    esac
  fi

  require_ubuntu
  sudo -v

  log "Updating Ubuntu packages"
  sudo env DEBIAN_FRONTEND=noninteractive apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
  sudo env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
  sudo apt-get autoclean

  log "Refreshing the pinned Neovim setup"
  bash "$NEOVIM_SETUP_SCRIPT"

  printf '\nUbuntu update complete.\n'
  if [[ -f /var/run/reboot-required ]]; then
    printf 'A reboot is required.\n'
  fi
}

main "$@"
