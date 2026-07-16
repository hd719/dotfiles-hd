#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
OS_RELEASE_FILE="${DOTFILES_OS_RELEASE_FILE:-/etc/os-release}"
NEOVIM_SETUP_SCRIPT="${DOTFILES_NEOVIM_SETUP_SCRIPT:-$SCRIPT_DIR/setup-neovim.sh}"
NERD_FONT_VERSION="3.4.0"
NERD_FONT_SHA256="e82418895a7036158baf9a425faea7de1fe332267b218341eec44c6b5071d1ad"
TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"
FONT_TMP_DIR=""
FONT_STAGING_DIR=""

print_usage() {
  cat <<'EOF'
Usage: setup.sh

Install the lean Ubuntu workstation: APT system packages, Docker, Ghostty,
Zsh, mise, and the full Neovim daily-driver setup.
EOF
}

log() {
  printf '\n==> %s\n' "$1"
}

cleanup() {
  [[ -z "$FONT_TMP_DIR" ]] || rm -rf "$FONT_TMP_DIR"
  [[ -z "$FONT_STAGING_DIR" ]] || rm -rf "$FONT_STAGING_DIR"
}
trap cleanup EXIT

require_ubuntu() {
  [[ -r "$OS_RELEASE_FILE" ]] || {
    printf 'Cannot read %s.\n' "$OS_RELEASE_FILE" >&2
    exit 1
  }

  # shellcheck disable=SC1090
  source "$OS_RELEASE_FILE"
  if [[ "${ID:-}" != "ubuntu" ]]; then
    printf 'This setup supports Ubuntu only (detected: %s).\n' "${ID:-unknown}" >&2
    exit 1
  fi
}

backup_path() {
  local target="$1"
  local backup
  local suffix=0

  backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"

  while [[ -e "$backup" || -L "$backup" ]]; do
    suffix=$((suffix + 1))
    backup="${target}.backup.$(date +%Y%m%d-%H%M%S).$suffix"
  done

  mv "$target" "$backup"
  printf 'Backed up %s to %s\n' "$target" "$backup"
}

safe_link() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_path "$target"
  fi

  ln -s "$source" "$target"
  printf 'Linked %s -> %s\n' "$target" "$source"
}

ensure_directory() {
  local directory="$1"

  if [[ -L "$directory" || (-e "$directory" && ! -d "$directory") ]]; then
    backup_path "$directory"
  fi
  mkdir -p "$directory"
}

install_apt_packages() {
  local packages=(
    build-essential
    ca-certificates
    curl
    docker-compose-v2
    docker.io
    fontconfig
    ghostscript
    ghostty
    git
    imagemagick
    libbz2-dev
    libffi-dev
    liblzma-dev
    libreadline-dev
    libsqlite3-dev
    libssl-dev
    pkg-config
    tk-dev
    unzip
    uuid-dev
    wl-clipboard
    xclip
    xz-utils
    zlib1g-dev
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
  )

  log "Installing Ubuntu packages"
  sudo env DEBIAN_FRONTEND=noninteractive apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"
}

install_nerd_font() {
  local font_dir="$HOME/.local/share/fonts/Hasklig"
  local font_parent
  local previous_dir=""
  local version_file="$font_dir/.nerd-font-version"
  local archive_path
  local archive_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VERSION}/Hasklig.tar.xz"

  if [[ -f "$version_file" ]] \
    && [[ "$(<"$version_file")" == "$NERD_FONT_VERSION" ]] \
    && command -v fc-list >/dev/null 2>&1 \
    && fc-list | grep -F "Hasklug Nerd Font" >/dev/null; then
    return
  fi

  log "Installing Hasklug Nerd Font ${NERD_FONT_VERSION}"
  FONT_TMP_DIR="$(mktemp -d)"
  archive_path="$FONT_TMP_DIR/Hasklig.tar.xz"
  curl -fsSL "$archive_url" -o "$archive_path"
  printf '%s  %s\n' "$NERD_FONT_SHA256" "$archive_path" | sha256sum -c -

  font_parent="$(dirname "$font_dir")"
  mkdir -p "$font_parent"
  FONT_STAGING_DIR="$(mktemp -d "$font_parent/.Hasklig.new.XXXXXX")"
  tar -xJf "$archive_path" -C "$FONT_STAGING_DIR"
  find "$FONT_STAGING_DIR" -type f \( -name '*.ttf' -o -name '*.otf' \) \
    -print -quit | grep -q . || {
    printf 'The verified Hasklig archive contained no font files.\n' >&2
    return 1
  }
  printf '%s\n' "$NERD_FONT_VERSION" > "$FONT_STAGING_DIR/.nerd-font-version"

  if [[ -e "$font_dir" || -L "$font_dir" ]]; then
    previous_dir="${font_dir}.previous.$$"
    rm -rf "$previous_dir"
    mv "$font_dir" "$previous_dir"
  fi
  if ! mv "$FONT_STAGING_DIR" "$font_dir"; then
    [[ -z "$previous_dir" ]] || mv "$previous_dir" "$font_dir"
    return 1
  fi
  FONT_STAGING_DIR=""
  if ! fc-cache -f "$font_dir"; then
    rm -rf "$font_dir"
    if [[ -n "$previous_dir" ]]; then
      mv "$previous_dir" "$font_dir"
      fc-cache -f "$font_dir" >/dev/null 2>&1 || true
    fi
    return 1
  fi
  [[ -z "$previous_dir" ]] || rm -rf "$previous_dir"
  rm -rf "$FONT_TMP_DIR"
  FONT_TMP_DIR=""
}

link_configs() {
  log "Linking Ubuntu configuration"
  ensure_directory "$HOME/.config/ghostty"
  safe_link "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
  safe_link "$SCRIPT_DIR/ghostty.conf" "$HOME/.config/ghostty/config"
  safe_link "$ROOT_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
  safe_link "$ROOT_DIR/config/git/.gitignore_global" "$HOME/.gitignore_global"

  git config --global core.editor nvim
  git config --global core.excludesfile "$HOME/.gitignore_global"
}

configure_services() {
  log "Enabling Docker and Zsh"
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$TARGET_USER"
  sudo chsh -s "$(command -v zsh)" "$TARGET_USER"
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
  install_apt_packages
  install_nerd_font
  link_configs
  configure_services

  log "Installing Neovim daily driver"
  bash "$NEOVIM_SETUP_SCRIPT"

  printf '\nUbuntu workstation setup complete. Log out and back in for Docker group access.\n'
}

main "$@"
