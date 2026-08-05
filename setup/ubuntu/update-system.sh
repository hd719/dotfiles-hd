#!/usr/bin/env bash
set -Eeuo pipefail

UPDATE_STAGE="initialization"

report_update_failure() {
  local status=$?

  trap - ERR
  printf '\nUbuntu update failed during: %s (exit %d).\n' \
    "$UPDATE_STAGE" "$status" >&2
  exit "$status"
}

trap report_update_failure ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
OS_RELEASE_FILE="${DOTFILES_OS_RELEASE_FILE:-/etc/os-release}"
NEOVIM_SETUP_SCRIPT="${DOTFILES_NEOVIM_SETUP_SCRIPT:-$SCRIPT_DIR/setup-neovim.sh}"
MISE_BIN="${DOTFILES_MISE_BIN:-$HOME/.local/bin/mise}"
EXPECTED_DOTFILES_ORIGIN="git@github.com:hd719/dotfiles-hd.git"

print_usage() {
  cat <<'EOF'
Usage: update-system.sh

Update all declared Ubuntu workstation dependencies through APT and mise,
refresh locked Neovim plugins, and reconcile remote client binaries.
EOF
}

log() {
  printf '\n==> %s\n' "$1"
}

require_ubuntu() {
  [[ -r "$OS_RELEASE_FILE" ]] || {
    printf 'Cannot read %s.\n' "$OS_RELEASE_FILE" >&2
    return 1
  }

  # shellcheck disable=SC1090
  source "$OS_RELEASE_FILE"
  if [[ "${ID:-}" != "ubuntu" ]]; then
    printf 'This updater supports Ubuntu only (detected: %s).\n' "${ID:-unknown}" >&2
    return 1
  fi
}

sync_dotfiles() {
  local origin_url

  if ! command -v git >/dev/null 2>&1; then
    printf 'Git not found; skipping dotfiles sync.\n' >&2
    return 1
  fi

  if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    printf 'Dotfiles checkout not found at: %s\n' "$DOTFILES_DIR" >&2
    return 1
  fi

  origin_url="$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null)" || {
    printf 'Dotfiles origin is unavailable; skipping sync.\n' >&2
    return 1
  }

  if [[ "$origin_url" != "$EXPECTED_DOTFILES_ORIGIN" ]]; then
    printf 'Dotfiles origin is not hd719/dotfiles-hd; skipping sync: %s\n' "$origin_url" >&2
    return 1
  fi

  git -C "$DOTFILES_DIR" pull --ff-only origin master
}

refresh_remote_clients() {
  local herdr_source herdr_target="$HOME/.local/bin/herdr"

  herdr_source="$("$MISE_BIN" which herdr)" || {
    printf 'mise could not resolve Herdr.\n' >&2
    return 1
  }
  if [[ ! -x "$herdr_source" ]]; then
    printf 'mise Herdr binary is not executable: %s\n' "$herdr_source" >&2
    return 1
  fi

  mkdir -p "$(dirname "$herdr_target")"
  install -m 0755 "$herdr_source" "$herdr_target"
  printf 'Refreshed remote Herdr client: %s\n' "$herdr_target"
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

  UPDATE_STAGE="Ubuntu environment validation"
  require_ubuntu

  log "Syncing hd719 dotfiles"
  if sync_dotfiles; then
    printf 'Dotfiles are current.\n'
  else
    printf 'Dotfiles sync failed; continuing without resetting local changes.\n' >&2
  fi

  log "Updating Ubuntu packages"
  UPDATE_STAGE="APT package index update"
  sudo -n /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    /usr/bin/apt-get update
  UPDATE_STAGE="APT full upgrade"
  sudo -n /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    /usr/bin/apt-get full-upgrade -y
  UPDATE_STAGE="APT autoremove"
  sudo -n /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    /usr/bin/apt-get autoremove -y
  UPDATE_STAGE="APT autoclean"
  sudo -n /usr/bin/apt-get autoclean

  log "Refreshing workstation-managed mise and Neovim dependencies"
  UPDATE_STAGE="mise and Neovim dependency refresh"
  bash "$NEOVIM_SETUP_SCRIPT"

  log "Refreshing remote workstation clients"
  UPDATE_STAGE="remote Herdr client refresh"
  refresh_remote_clients

  printf '\nUbuntu update complete.\n'
  if [[ -f /var/run/reboot-required ]]; then
    printf 'A reboot is required.\n'
  fi
}

main "$@"
