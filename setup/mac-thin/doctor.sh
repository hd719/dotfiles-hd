#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
APPLICATIONS_DIR="${DOTFILES_APPLICATIONS_DIR:-/Applications}"
BREWFILE="$DOTFILES_DIR/setup/mac-thin/Brewfile"
SSH_CONFIG="$HOME/.ssh/config"
ARBITER_SSH_KEY="$HOME/.ssh/id_ed25519_arbiter_hd"
FORGEJO_SSH_KEY="$HOME/.ssh/id_ed25519_forgejo_truenas"
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
  "Brave Browser.app" \
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

if [[ -r "$SSH_CONFIG" ]]; then
  pass "SSH config readable"
else
  fail "SSH config missing or unreadable"
fi

check_ubuntu_ssh_alias() {
  local ssh_alias="$1"
  local effective

  effective="$(ssh -G -F "$SSH_CONFIG" "$ssh_alias" 2>/dev/null || true)"

  if printf '%s\n' "$effective" \
    | /usr/bin/awk '$1 == "addressfamily" && $2 == "inet" { found = 1 } END { exit !found }'; then
    pass "$ssh_alias prefers IPv4"
  else
    fail "$ssh_alias must set AddressFamily inet"
  fi

  if printf '%s\n' "$effective" \
    | /usr/bin/awk '$1 == "forwardagent" && $2 == "yes" { found = 1 } END { exit !found }'; then
    pass "$ssh_alias forwards the Mac agent"
  else
    fail "$ssh_alias must set ForwardAgent yes"
  fi

  if printf '%s\n' "$effective" \
    | /usr/bin/awk '$1 == "permitlocalcommand" && $2 == "yes" { found = 1 } END { exit !found }' \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fq "$ARBITER_SSH_KEY" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fq "$FORGEJO_SSH_KEY"; then
    pass "$ssh_alias loads Arbiter and Forgejo keys"
  else
    fail "$ssh_alias must load Arbiter and Forgejo keys before forwarding"
  fi
}

check_ubuntu_ssh_alias ubuntu-vm
check_ubuntu_ssh_alias ubuntu-vm-ts

for ssh_key in "$ARBITER_SSH_KEY" "$FORGEJO_SSH_KEY"; do
  if [[ -f "$ssh_key" && "$(stat -f '%Lp' "$ssh_key" 2>/dev/null)" == "600" ]]; then
    pass "$(basename "$ssh_key") present with mode 600"
  else
    fail "$(basename "$ssh_key") missing or not mode 600"
  fi
done

if /bin/zsh -dfc "
  source '$DOTFILES_DIR/setup/mac-thin/.zshrc'
  [[ \"\$(alias g)\" == 'g=git' ]]
  [[ \"\$(alias gs)\" == \"gs='git status'\" ]]
  [[ \"\$(alias cod)\" == 'cod=codex' ]]
  [[ \"\$(alias codu)\" == \"codu='codex update'\" ]]
  [[ \"\$(alias dots)\" == \"dots='cd ~/Developer/dotfiles-hd'\" ]]
  [[ \"\$(alias vault)\" == \"vault='cd ~/Developer/hd'\" ]]
  [[ \"\$(alias u)\" == \"u='ssh ubuntu-vm'\" ]]
  [[ \"\$(alias ubuntu)\" == \"ubuntu='ssh ubuntu-vm'\" ]]
  [[ \"\$(alias ut)\" == \"ut='ssh ubuntu-vm-ts'\" ]]
  [[ \"\$(alias ubuntu-ts)\" == \"ubuntu-ts='ssh ubuntu-vm-ts'\" ]]
  [[ \"\$(alias uvm-open)\" == \"uvm-open='open -a \\\"VMware Fusion\\\"'\" ]]
  [[ \"\$(whence -w reload)\" == 'reload: function' ]]
  [[ \"\$(whence -w uvm-status)\" == 'uvm-status: function' ]]
  [[ \"\$(whence -w uvm-ip)\" == 'uvm-ip: function' ]]
  ! alias v >/dev/null 2>&1
  ! alias hm-dev >/dev/null 2>&1
  ! alias docker-nuke >/dev/null 2>&1
"; then
  pass "Thin-Mac personal shell allowlist available"
else
  fail "Thin-Mac personal shell allowlist invalid"
fi

if [[ "$FAILURES" -eq 0 ]]; then
  printf 'Doctor passed for mac-thin.\n'
  exit 0
fi

printf 'Doctor found %d failure(s).\n' "$FAILURES" >&2
exit 1
