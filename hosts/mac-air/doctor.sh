#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
CHEZMOI_DOCTOR="${DOTFILES_CHEZMOI_DOCTOR:-$DOTFILES_DIR/chezmoi/doctor.sh}"
APPLICATIONS_DIR="${DOTFILES_APPLICATIONS_DIR:-/Applications}"
FAILURES=0
pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*" >&2; FAILURES=$((FAILURES + 1)); }

[[ "$(uname -s)" == Darwin ]] && pass macOS || fail 'macOS required'
if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade \
  --file "$DOTFILES_DIR/hosts/mac-air/Brewfile"; then
  pass 'remote client packages'
else
  fail 'remote client packages missing'
fi
if "$CHEZMOI_DOCTOR" mac-air; then
  pass 'Air client configuration'
else
  fail 'Air client configuration'
fi
for app in ChatGPT Ghostty Obsidian Tailscale; do
  [[ -d "$APPLICATIONS_DIR/$app.app" ]] \
    && pass "$app installed" || fail "$app missing"
done
printf 'MANUAL  Verify Studio SSH, Screen Sharing and remote execution over Tailscale.\n'
((FAILURES == 0))
