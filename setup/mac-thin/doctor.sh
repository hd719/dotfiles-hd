#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
APPLICATIONS_DIR="${DOTFILES_APPLICATIONS_DIR:-/Applications}"
BREWFILE="$DOTFILES_DIR/setup/mac-thin/Brewfile"
SSH_CONFIG="$HOME/.ssh/config"
VAGRANT_SSH_CONFIG="$DOTFILES_DIR/setup/mac-thin/ssh/ubuntu-vagrant.conf"
UBUNTU_LOGIN_KEY="$HOME/.ssh/id_ed25519_ubuntu_vm"
UBUNTU_LOGIN_KEY_NAME="$(basename "$UBUNTU_LOGIN_KEY")"
ARBITER_SSH_KEY="$HOME/.ssh/id_ed25519_arbiter_hd"
FORGEJO_SSH_KEY="$HOME/.ssh/id_ed25519_forgejo_truenas"
LEGACY_AGENT_ROUTES=0
FAILURES=0
VAGRANT_VMWARE_PLUGIN_VERSION="3.0.5"
VAGRANT_VMWARE_UTILITY="${DOTFILES_VAGRANT_VMWARE_UTILITY:-/opt/vagrant-vmware-desktop/bin/vagrant-vmware-utility}"
VAGRANT_VMWARE_SERVICE_LABEL="com.vagrant.vagrant-vmware-utility"

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

if command -v vagrant >/dev/null 2>&1; then
  pass "Vagrant available"
else
  fail "Vagrant missing"
fi

if [[ -x "$VAGRANT_VMWARE_UTILITY" ]]; then
  pass "Vagrant VMware utility available"
else
  fail "Vagrant VMware utility missing"
fi

if launchctl print "system/$VAGRANT_VMWARE_SERVICE_LABEL" >/dev/null 2>&1; then
  pass "Vagrant VMware utility service active"
else
  fail "Vagrant VMware utility service is not active"
fi

if command -v vagrant >/dev/null 2>&1 \
  && vagrant plugin list 2>/dev/null \
    | /usr/bin/grep -Eq \
      "^vagrant-vmware-desktop \\($VAGRANT_VMWARE_PLUGIN_VERSION([,)])"; then
  pass "Vagrant VMware provider $VAGRANT_VMWARE_PLUGIN_VERSION"
else
  fail "Vagrant VMware provider must be $VAGRANT_VMWARE_PLUGIN_VERSION"
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
    LEGACY_AGENT_ROUTES=$((LEGACY_AGENT_ROUTES + 1))
    pass "$ssh_alias uses the legacy forwarded-agent route"

    if printf '%s\n' "$effective" \
      | /usr/bin/awk '$1 == "permitlocalcommand" && $2 == "yes" { found = 1 } END { exit !found }' \
      && printf '%s\n' "$effective" | /usr/bin/grep -Fq "$ARBITER_SSH_KEY" \
      && printf '%s\n' "$effective" | /usr/bin/grep -Fq "$FORGEJO_SSH_KEY"; then
      pass "$ssh_alias loads the legacy Arbiter and Forgejo keys"
    else
      fail "$ssh_alias legacy route must load Arbiter and Forgejo keys"
    fi
  elif printf '%s\n' "$effective" \
    | /usr/bin/awk '$1 == "forwardagent" && $2 == "no" { found = 1 } END { exit !found }' \
    && printf '%s\n' "$effective" \
      | /usr/bin/awk '$1 == "identitiesonly" && $2 == "yes" { found = 1 } END { exit !found }' \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fq "$UBUNTU_LOGIN_KEY_NAME"; then
    pass "$ssh_alias uses only the Ubuntu login key"
  else
    fail "$ssh_alias must use one complete legacy or Vagrant SSH policy"
  fi
}

check_ubuntu_ssh_alias ubuntu-vm
check_ubuntu_ssh_alias ubuntu-vm-ts

if ((LEGACY_AGENT_ROUTES == 2)); then
  ubuntu_ssh_keys=("$ARBITER_SSH_KEY" "$FORGEJO_SSH_KEY" "$UBUNTU_LOGIN_KEY")
elif ((LEGACY_AGENT_ROUTES == 0)); then
  ubuntu_ssh_keys=("$UBUNTU_LOGIN_KEY")
else
  ubuntu_ssh_keys=()
  fail "Ubuntu SSH routes mix legacy and Vagrant policies"
fi

for ssh_key in "${ubuntu_ssh_keys[@]}"; do
  if [[ -f "$ssh_key" && "$(stat -f '%Lp' "$ssh_key" 2>/dev/null)" == "600" ]]; then
    pass "$(basename "$ssh_key") present with mode 600"
  else
    fail "$(basename "$ssh_key") missing or not mode 600"
  fi
done

check_vagrant_ssh_alias() {
  local ssh_alias="$1"
  local expected_hostname="$2"
  local expected_port="$3"
  local expected_host_key_alias="$4"
  local effective

  effective="$(ssh -G -F "$VAGRANT_SSH_CONFIG" "$ssh_alias" 2>/dev/null || true)"
  if printf '%s\n' "$effective" | /usr/bin/grep -Fq "$UBUNTU_LOGIN_KEY_NAME" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "hostname $expected_hostname" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "port $expected_port" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "hostkeyalias $expected_host_key_alias" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "forwardagent no" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "identitiesonly yes" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "stricthostkeychecking true"; then
    pass "$ssh_alias Vagrant policy"
  else
    fail "$ssh_alias Vagrant SSH policy is incomplete"
  fi
}

if [[ -r "$VAGRANT_SSH_CONFIG" ]]; then
  check_vagrant_ssh_alias ubuntu-vm-canary 127.0.0.1 2222 ubuntu-dev-canary
  check_vagrant_ssh_alias ubuntu-vm-canary-ts ubuntu-dev-canary 22 ubuntu-dev-canary
  check_vagrant_ssh_alias ubuntu-vm 127.0.0.1 2222 ubuntu-dev
  check_vagrant_ssh_alias ubuntu-vm-ts ubuntu-dev 22 ubuntu-dev
else
  fail "Vagrant SSH config missing"
fi

if /bin/zsh -dfc "
  source '$DOTFILES_DIR/setup/mac-thin/.zshrc'
  [[ \"\$(alias g)\" == 'g=git' ]]
  [[ \"\$(alias gs)\" == \"gs='git status'\" ]]
  [[ \"\$(alias cod)\" == 'cod=codex' ]]
  [[ \"\$(alias codu)\" == \"codu='codex update'\" ]]
  [[ \"\$(alias dots)\" == \"dots='cd ~/Developer/dotfiles-hd'\" ]]
  [[ \"\$(alias vault)\" == \"vault='cd ~/Developer/hd'\" ]]
  [[ \"\$(alias u)\" == \"u='ssh ubuntu-vm'\" ]]
  [[ \"\$(alias ut)\" == \"ut='ssh ubuntu-vm-ts'\" ]]
  [[ \"\$(alias uc)\" == \"uc='ssh -F ~/Developer/dotfiles-hd/setup/mac-thin/ssh/ubuntu-vagrant.conf ubuntu-vm-canary'\" ]]
  [[ \"\$(alias uct)\" == \"uct='ssh -F ~/Developer/dotfiles-hd/setup/mac-thin/ssh/ubuntu-vagrant.conf ubuntu-vm-canary-ts'\" ]]
  ! alias ubuntu >/dev/null 2>&1
  ! alias ubuntu-ts >/dev/null 2>&1
  ! alias uvm-open >/dev/null 2>&1
  [[ \"\$(whence -w reload)\" == 'reload: function' ]]
  [[ \"\$(whence -w uvm-status)\" == 'uvm-status: function' ]]
  [[ \"\$(whence -w uvm-ip)\" == 'uvm-ip: function' ]]
  [[ \"\$(whence -w uvm-up)\" == 'uvm-up: function' ]]
  [[ \"\$(whence -w uvm-up-headless)\" == 'uvm-up-headless: function' ]]
  [[ \"\$(whence -w uvm-stop)\" == 'uvm-stop: function' ]]
  [[ \"\$(whence -w uvm-suspend)\" == 'uvm-suspend: function' ]]
  [[ \"\$(whence -w uvm-resume)\" == 'uvm-resume: function' ]]
  [[ \"\$(whence -w uvm-destroy)\" == 'uvm-destroy: function' ]]
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
