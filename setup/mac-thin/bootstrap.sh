#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
GIT_ALIASES_SCRIPT="$DOTFILES_DIR/config/git/configure-aliases.sh"
STAMP="${DOTFILES_STAMP:-$(date +%Y%m%d-%H%M%S)}"
MODE="dry-run"
VAGRANT_VMWARE_PLUGIN_VERSION="3.0.5"
PKGUTIL="${DOTFILES_PKGUTIL:-/usr/sbin/pkgutil}"
SOFTWAREUPDATE="${DOTFILES_SOFTWAREUPDATE:-/usr/sbin/softwareupdate}"
SUDO="${DOTFILES_SUDO:-/usr/bin/sudo}"

# shellcheck source=../mac-bootstrap/lib.sh
source "$DOTFILES_DIR/setup/mac-bootstrap/lib.sh"

NEOVIM_PARSERS=(markdown markdown_inline)
NEOVIM_PARSER_BINARIES=(markdown markdown_inline)

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--dry-run|--check|--apply]

Modes:
  --dry-run  Preview packages and links without package-manager calls or writes.
  --check    Audit packages, applications, and links without changing them.
  --apply    Install missing control-plane apps and apply backed-up links.

This profile never installs project runtimes, Docker, databases, project compilers,
project dependencies, or language servers other than Marksman for Markdown.
Neovim always runs the restricted thin profile.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      MODE="dry-run"
      shift
      ;;
    --check)
      MODE="check"
      shift
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

BREWFILE="$DOTFILES_DIR/setup/mac-thin/Brewfile"
NVIM_LOCKFILE="$DOTFILES_DIR/config/nvim/lazy-lock.json"
LINK_SPECS=(
  "$DOTFILES_DIR/config/bookokrat|$HOME/.config/bookokrat"
  "$DOTFILES_DIR/setup/mac-thin/.zshrc|$HOME/.zshrc"
  "$DOTFILES_DIR/config/ghostty/config|$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  "$DOTFILES_DIR/config/herdr/config.toml|$HOME/.config/herdr/config.toml"
  "$DOTFILES_DIR/config/hunk/config.toml|$HOME/.config/hunk/config.toml"
  "$DOTFILES_DIR/config/nvim|$HOME/.config/nvim"
  "$DOTFILES_DIR/config/starship/starship.toml|$HOME/.config/starship.toml"
)

[[ "$(uname -s)" == "Darwin" ]] || die "mac-thin requires macOS"
[[ "$(uname -m)" == "arm64" ]] || die "mac-thin currently supports Apple Silicon only"
xcode-select -p >/dev/null 2>&1 \
  || die "install Xcode Command Line Tools first: xcode-select --install"
command -v brew >/dev/null 2>&1 || die "install Homebrew first: https://brew.sh"
git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "not a Git checkout: $DOTFILES_DIR"

if [[ "$MODE" == "apply" ]]; then
  [[ "$DOTFILES_DIR" == "$HOME/Developer/dotfiles-hd" \
    || "${DOTFILES_ALLOW_NONCANONICAL:-0}" == "1" ]] \
    || die "--apply requires the canonical clone at $HOME/Developer/dotfiles-hd"
  if [[ "${DOTFILES_ALLOW_DIRTY:-0}" != "1" ]]; then
    [[ -z "$(git -C "$DOTFILES_DIR" status --porcelain)" ]] \
      || die "dotfiles checkout must be clean before --apply"
  fi
fi

require_source "$BREWFILE"
require_source "$DOTFILES_DIR/config/zsh/shared/aliases.zsh"
require_source "$DOTFILES_DIR/config/zsh/shared/codex-aliases.zsh"
require_source "$DOTFILES_DIR/config/zsh/shared/functions.zsh"
require_source "$DOTFILES_DIR/config/zsh/mac/aliases.zsh"
require_source "$DOTFILES_DIR/config/zsh/mac/personal/codex-functions.zsh"
require_source "$DOTFILES_DIR/config/zsh/mac/personal/aliases.zsh"
require_source "$SCRIPT_DIR/herdr.zsh"
require_source "$SCRIPT_DIR/vm.zsh"
require_source "$GIT_ALIASES_SCRIPT"
require_source "$NVIM_LOCKFILE"
require_source "$DOTFILES_DIR/config/nvim/lua/config/profile.lua"
for spec in "${LINK_SPECS[@]}"; do
  require_source "${spec%%|*}"
  reject_link_source_alias "${spec%%|*}" "${spec#*|}"
done

vagrant_vmware_plugin_current() {
  command -v vagrant >/dev/null 2>&1 || return 1
  vagrant plugin list 2>/dev/null \
    | /usr/bin/grep -Eq \
      "^vagrant-vmware-desktop \\($VAGRANT_VMWARE_PLUGIN_VERSION([,)])"
}

rosetta_installed() {
  "$PKGUTIL" --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1
}

restore_thin_neovim() {
  local lockfile_backup
  local nvim_status=0

  validate_neovim_lockfile "$NVIM_LOCKFILE" || return 1
  lockfile_backup="$(mktemp "${TMPDIR:-/tmp}/dotfiles-thin-lazy-lock.XXXXXX")"
  cp -p "$NVIM_LOCKFILE" "$lockfile_backup"

  if DOTFILES_NVIM_PROFILE=thin DOTFILES_NVIM_RESTORE_ALL=1 \
    nvim --headless '+Lazy! restore' '+qa'; then
    if DOTFILES_NVIM_PROFILE=thin nvim --headless \
      "+lua local ok=require('nvim-treesitter').install({'markdown','markdown_inline'}):wait(); if not ok then vim.cmd('cquit 1') end" \
      '+qa'; then
      if ! verify_neovim_parsers_restored; then
        nvim_status=1
      fi
    else
      nvim_status=$?
    fi
  else
    nvim_status=$?
  fi

  if ! cmp -s "$NVIM_LOCKFILE" "$lockfile_backup"; then
    cp -p "$lockfile_backup" "$NVIM_LOCKFILE"
    say "restored unchanged Neovim lockfile: $NVIM_LOCKFILE"
  fi
  rm -f "$lockfile_backup"

  [[ "$nvim_status" -eq 0 ]] || die "Thin-profile Neovim restore failed"
}

if [[ "$MODE" == "dry-run" ]]; then
  say "profile: mac-thin"
  say "mode: dry-run (no package-manager calls or writes)"
  say "would install control-plane apps from: $BREWFILE"
  say "VMware Fusion, ChatGPT, and Hermes Desktop remain manual application installs"
  say "would install Rosetta 2 when missing"
  say "would install vagrant-vmware-desktop $VAGRANT_VMWARE_PLUGIN_VERSION"
  say "would restore only thin-profile Neovim plugins and Markdown parsers"
  say "would include portable Git aliases without replacing machine-owned identity"
  for spec in "${LINK_SPECS[@]}"; do
    backup_and_link "${spec%%|*}" "${spec#*|}" "$STAMP" 1
  done
  exit 0
fi

if [[ "$MODE" == "check" ]]; then
  status=0
  if rosetta_installed; then
    say "Rosetta 2 installed"
  else
    say "Rosetta 2 missing"
    status=1
  fi
  if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file "$BREWFILE"; then
    say "Brewfile satisfied: $BREWFILE"
  else
    say "Brewfile has missing dependencies: $BREWFILE"
    status=1
  fi
  for spec in "${LINK_SPECS[@]}"; do
    if link_matches "${spec%%|*}" "${spec#*|}"; then
      say "link current: ${spec#*|}"
    else
      backup_and_link "${spec%%|*}" "${spec#*|}" "$STAMP" 1
      status=1
    fi
  done
  "$GIT_ALIASES_SCRIPT" --check || status=1
  if vagrant_vmware_plugin_current; then
    say "Vagrant VMware provider current: $VAGRANT_VMWARE_PLUGIN_VERSION"
  else
    say "Vagrant VMware provider missing or not pinned to $VAGRANT_VMWARE_PLUGIN_VERSION"
    status=1
  fi
  "$SCRIPT_DIR/doctor.sh" || status=1
  exit "$status"
fi

if ! rosetta_installed; then
  say "Installing Rosetta 2 for the Vagrant VMware utility..."
  "$SUDO" "$SOFTWAREUPDATE" --install-rosetta --agree-to-license
fi

say "Installing thin-Mac control-plane applications without broad upgrades..."
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --no-upgrade --file "$BREWFILE"

# A cancelled .pkg prompt can leave Homebrew's cask metadata without the
# Vagrant executable. Repair that partial install before adding the provider.
if ! command -v vagrant >/dev/null 2>&1; then
  say "Repairing the incomplete Vagrant package install..."
  HOMEBREW_NO_AUTO_UPDATE=1 brew reinstall --cask vagrant
  hash -r
fi

if ! vagrant_vmware_plugin_current; then
  say "Installing pinned Vagrant VMware provider..."
  vagrant plugin install vagrant-vmware-desktop \
    --plugin-version "$VAGRANT_VMWARE_PLUGIN_VERSION"
fi

for spec in "${LINK_SPECS[@]}"; do
  backup_and_link "${spec%%|*}" "${spec#*|}" "$STAMP" 0
done
DOTFILES_STAMP="$STAMP" "$GIT_ALIASES_SCRIPT" --apply

say "Restoring locked thin-profile Neovim plugins and Markdown parsers..."
restore_thin_neovim

"$SCRIPT_DIR/doctor.sh"
say "Thin Mac bootstrap complete. Start a fresh login shell."
