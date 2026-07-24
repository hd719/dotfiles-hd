#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
APPLICATIONS_DIR="${DOTFILES_APPLICATIONS_DIR:-/Applications}"
BREWFILE="$DOTFILES_DIR/setup/mac-thin/Brewfile"
FAILURES=0

# shellcheck source=../mac-bootstrap/lib.sh
source "$DOTFILES_DIR/setup/mac-bootstrap/lib.sh"

pass() {
  printf 'PASS  %s\n' "$*"
}

fail() {
  printf 'FAIL  %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
  pass "Apple Silicon macOS"
else
  fail "Apple Silicon macOS required"
fi

if command -v brew >/dev/null 2>&1; then
  pass "Homebrew available"
else
  fail "Homebrew missing"
fi

if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file "$BREWFILE" >/dev/null; then
  pass "Brewfile satisfied"
else
  fail "Brewfile missing applications"
fi

LINK_SPECS=(
  "$DOTFILES_DIR/setup/mac-thin/.zshrc|$HOME/.zshrc"
  "$DOTFILES_DIR/config/ghostty/config|$HOME/Library/Application Support/com.mitchellh.ghostty/config"
)
for spec in "${LINK_SPECS[@]}"; do
  source_path="${spec%%|*}"
  destination="${spec#*|}"
  if link_matches "$source_path" "$destination"; then
    pass "$destination -> $source_path"
  else
    fail "link mismatch: $destination"
  fi
done

for app_name in \
  "1Password.app" \
  "ChatGPT.app" \
  "Ghostty.app" \
  "Obsidian.app" \
  "Tailscale.app" \
  "VMware Fusion.app"; do
  if [[ -d "$APPLICATIONS_DIR/$app_name" ]]; then
    pass "$app_name installed"
  else
    fail "$app_name missing"
  fi
done

if [[ -r "$HOME/.ssh/config" ]]; then
  pass "SSH config readable"
else
  fail "SSH config missing or unreadable"
fi

if [[ "$FAILURES" -eq 0 ]]; then
  printf 'Doctor passed for mac-thin.\n'
  exit 0
fi

printf 'Doctor found %d failure(s).\n' "$FAILURES" >&2
exit 1
