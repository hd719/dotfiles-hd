#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-mac-thin-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home/.ssh" "$TEST_ROOT/apps"
cat > "$TEST_ROOT/home/.ssh/config" <<'EOF'
Host ubuntu-vm
  HostName ubuntu-vm.local
  AddressFamily inet
EOF

for app_name in \
  "1Password.app" \
  "Brave Browser.app" \
  "ChatGPT.app" \
  "Ghostty.app" \
  "Obsidian.app" \
  "Tailscale.app" \
  "VMware Fusion.app"; do
  mkdir -p "$TEST_ROOT/apps/$app_name"
done

cat > "$TEST_ROOT/bin/brew" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$DOTFILES_TEST_BREW_LOG"
exit 0
EOF

cat > "$TEST_ROOT/bin/uname" <<'EOF'
#!/bin/sh
case "$1" in
  -s) printf 'Darwin\n' ;;
  -m) printf 'arm64\n' ;;
  *) exit 2 ;;
esac
EOF

cat > "$TEST_ROOT/bin/xcode-select" <<'EOF'
#!/bin/sh
printf '/Library/Developer/CommandLineTools\n'
EOF

chmod +x "$TEST_ROOT/bin/brew" "$TEST_ROOT/bin/uname" "$TEST_ROOT/bin/xcode-select"
: > "$TEST_ROOT/brew.log"

export DOTFILES_ALLOW_DIRTY=1
export DOTFILES_ALLOW_NONCANONICAL=1
export DOTFILES_APPLICATIONS_DIR="$TEST_ROOT/apps"
export DOTFILES_DIR="$REPO_DIR"
export DOTFILES_TEST_BREW_LOG="$TEST_ROOT/brew.log"
export HOME="$TEST_ROOT/home"
export PATH="$TEST_ROOT/bin:/usr/bin:/bin"

"$REPO_DIR/setup/mac-thin/bootstrap.sh" --dry-run >/dev/null
[[ ! -e "$HOME/.zshrc" ]]

"$REPO_DIR/setup/mac-thin/bootstrap.sh" --apply >/dev/null
[[ "$(readlink "$HOME/.zshrc")" == "$REPO_DIR/setup/mac-thin/.zshrc" ]]
[[ "$(readlink "$HOME/Library/Application Support/com.mitchellh.ghostty/config")" \
  == "$REPO_DIR/config/ghostty/config" ]]
/bin/zsh -dfc "
  source '$HOME/.zshrc'
  [[ \"\$(alias u)\" == \"u='ssh ubuntu-vm'\" ]]
  [[ \"\$(alias ubuntu)\" == \"ubuntu='ssh ubuntu-vm'\" ]]
  [[ \"\$(whence -w uvm-status)\" == 'uvm-status: function' ]]
  [[ \"\$(whence -w uvm-ip)\" == 'uvm-ip: function' ]]
"

"$REPO_DIR/setup/mac-thin/bootstrap.sh" --apply >/dev/null
[[ -z "$(find "$HOME" -name '*.backup-*' -print -quit)" ]]
grep -Fq 'bundle install --no-upgrade' "$TEST_ROOT/brew.log"

printf 'Thin Mac bootstrap tests passed.\n'
