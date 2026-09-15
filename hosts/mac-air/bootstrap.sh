#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
BREWFILE="$DOTFILES_DIR/hosts/mac-air/Brewfile"
CHEZMOI_BOOTSTRAP="${DOTFILES_CHEZMOI_BOOTSTRAP:-$DOTFILES_DIR/chezmoi/bootstrap.sh}"
CHEZMOI_PREVIEW="${DOTFILES_CHEZMOI_PREVIEW:-$DOTFILES_DIR/chezmoi/preview.sh}"
HOST_DOCTOR="${DOTFILES_AIR_DOCTOR:-$SCRIPT_DIR/doctor.sh}"
MODE="${1:---dry-run}"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
[[ $# -le 1 ]] || die "usage: bootstrap.sh [--dry-run|--check|--apply]"
case "$MODE" in
  --dry-run|--check|--apply) ;;
  *) die "usage: bootstrap.sh [--dry-run|--check|--apply]" ;;
esac

[[ "$(uname -s)" == Darwin ]] || die "mac-air requires macOS"
command -v brew >/dev/null 2>&1 || die "install Homebrew first"
git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "not a Git checkout: $DOTFILES_DIR"
[[ -f "$BREWFILE" ]] || die "missing Brewfile: $BREWFILE"

if [[ "$MODE" == --dry-run ]]; then
  printf 'profile: mac-air\nwould install thin-Mac apps and note tools from: %s\n' "$BREWFILE"
  printf 'would restore the thin Neovim profile and Markdown parsers; project execution stays on Studio\n'
  if [[ -x "${CHEZMOI_BIN:-$HOME/.local/bin/chezmoi}" ]]; then
    DOTFILES_CHEZMOI_CONFIG_ONLY_PREVIEW=1 bash "$CHEZMOI_PREVIEW" mac-air
  fi
  exit 0
fi

if [[ "$MODE" == --check ]]; then
  exec "$HOST_DOCTOR"
fi

[[ "${DOTFILES_MAC_AIR_ARRIVED:-0}" == 1 ]] \
  || die "mac-air apply requires DOTFILES_MAC_AIR_ARRIVED=1 after the hardware arrives"

# Reviewed canonical-checkout and layout validation precede package mutations.
DOTFILES_CHEZMOI_CONFIG_ONLY_PREVIEW=1 DOTFILES_CHEZMOI_REQUIRE_REVIEWED=1 \
  "$CHEZMOI_BOOTSTRAP" mac-air --preview >/dev/null
DOTFILES_CHEZMOI_APPROVED=1 "$CHEZMOI_BOOTSTRAP" mac-air --apply
"$HOST_DOCTOR"
printf 'Air client setup complete. Verify Studio access manually.\n'
