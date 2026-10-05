#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
BREWFILE="$DOTFILES_DIR/hosts/mac-air/Brewfile"
CHEZMOI_BOOTSTRAP="${DOTFILES_CHEZMOI_BOOTSTRAP:-$DOTFILES_DIR/chezmoi/bootstrap.sh}"
CHEZMOI_PREVIEW="${DOTFILES_CHEZMOI_PREVIEW:-$DOTFILES_DIR/chezmoi/preview.sh}"
HOST_DOCTOR="${DOTFILES_AIR_DOCTOR:-$SCRIPT_DIR/doctor.sh}"
MODE="dry-run"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

say() {
  printf '%s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--dry-run|--check|--apply]

  --dry-run  Preview host provisioning and Chezmoi delivery.
  --check    Audit packages, applications, and managed configuration.
  --apply    Provision the control plane and apply the mac-air profile.
EOF
}

while (($# > 0)); do
  case "$1" in
    --dry-run|--check|--apply)
      MODE="${1#--}"
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

[[ "$(uname -s)" == Darwin ]] || die "mac-air requires macOS"
[[ "$(uname -m)" == arm64 ]] || die "mac-air currently supports Apple Silicon only"
xcode-select -p >/dev/null 2>&1 \
  || die "install Xcode Command Line Tools first: xcode-select --install"
command -v brew >/dev/null 2>&1 || die "install Homebrew first: https://brew.sh"
git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "not a Git checkout: $DOTFILES_DIR"
[[ -f "$BREWFILE" ]] || die "missing Brewfile: $BREWFILE"
[[ -x "$CHEZMOI_BOOTSTRAP" ]] || die "missing Chezmoi bootstrap: $CHEZMOI_BOOTSTRAP"
[[ -f "$CHEZMOI_PREVIEW" ]] || die "missing Chezmoi preview: $CHEZMOI_PREVIEW"
[[ -x "$HOST_DOCTOR" ]] || die "missing thin-Mac doctor: $HOST_DOCTOR"

if [[ "$MODE" == apply ]]; then
  [[ "$DOTFILES_DIR" == "$HOME/Developer/dotfiles-hd" \
    || "${DOTFILES_ALLOW_NONCANONICAL:-0}" == 1 ]] \
    || die "--apply requires the canonical clone at $HOME/Developer/dotfiles-hd"
  if [[ "${DOTFILES_ALLOW_DIRTY:-0}" != 1 ]]; then
    [[ -z "$(git -C "$DOTFILES_DIR" status --porcelain)" ]] \
      || die "dotfiles checkout must be clean before --apply"
  fi
fi

if [[ "$MODE" == dry-run ]]; then
  say "profile: mac-air"
  say "mode: dry-run (no package-manager calls or writes)"
  say "would apply configuration and packages through Chezmoi: $BREWFILE"
  say "ChatGPT and Hermes Desktop remain manual installs"
  if [[ -x "${CHEZMOI_BIN:-$HOME/.local/bin/chezmoi}" ]]; then
    DOTFILES_CHEZMOI_CONFIG_ONLY_PREVIEW=1 \
      bash "$CHEZMOI_PREVIEW" mac-air
  else
    say "would install pinned Chezmoi, then render the configuration preview"
  fi
  exit 0
fi

if [[ "$MODE" == check ]]; then
  status=0
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file "$BREWFILE" \
    || status=1
  "$HOST_DOCTOR" || status=1
  exit "$status"
fi

DOTFILES_CHEZMOI_CONFIG_ONLY_PREVIEW=1 \
  DOTFILES_CHEZMOI_REQUIRE_REVIEWED=1 \
  "$CHEZMOI_BOOTSTRAP" mac-air --preview >/dev/null

DOTFILES_CHEZMOI_APPROVED=1 "$CHEZMOI_BOOTSTRAP" mac-air --apply

"$HOST_DOCTOR"
say "MacBook Air bootstrap complete. Start a fresh login shell."
