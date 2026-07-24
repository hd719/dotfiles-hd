#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-mac-thin-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home/.ssh" "$TEST_ROOT/apps"
cat > "$TEST_ROOT/home/.ssh/config" <<EOF
Host ubuntu-vm
  HostName ubuntu-vm.local
  AddressFamily inet
  ForwardAgent yes
  PermitLocalCommand yes
  LocalCommand /usr/bin/ssh-add $TEST_ROOT/home/.ssh/id_ed25519_arbiter_hd $TEST_ROOT/home/.ssh/id_ed25519_forgejo_truenas >/dev/null 2>&1
EOF
touch \
  "$TEST_ROOT/home/.ssh/id_ed25519_arbiter_hd" \
  "$TEST_ROOT/home/.ssh/id_ed25519_forgejo_truenas"
chmod 600 \
  "$TEST_ROOT/home/.ssh/id_ed25519_arbiter_hd" \
  "$TEST_ROOT/home/.ssh/id_ed25519_forgejo_truenas"

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
grep -Fxq 'selection-background = #9ABACE' "$REPO_DIR/config/ghostty/config"
grep -Fxq 'selection-foreground = #000001' "$REPO_DIR/config/ghostty/config"
GIT_PAGER='diff-so-fancy | less --tabs=4 -RFX' /bin/zsh -dfc "
  source '$HOME/.zshrc'
  [[ \"\$GIT_PAGER\" == 'less --tabs=4 -RFX' ]] || exit 1
  [[ \"\$(alias g)\" == 'g=git' ]]
  [[ \"\$(alias gs)\" == \"gs='git status'\" ]]
  [[ \"\$(alias cod)\" == 'cod=codex' ]]
  [[ \"\$(alias codu)\" == \"codu='codex update'\" ]]
  [[ \"\$(alias dots)\" == \"dots='cd ~/Developer/dotfiles-hd'\" ]]
  [[ \"\$(alias vault)\" == \"vault='cd ~/Developer/hd'\" ]]
  [[ \"\$(alias u)\" == \"u='ssh ubuntu-vm'\" ]]
  [[ \"\$(alias ubuntu)\" == \"ubuntu='ssh ubuntu-vm'\" ]]
  [[ \"\$(whence -w reload)\" == 'reload: function' ]]
  [[ \"\$(whence -w uvm-status)\" == 'uvm-status: function' ]]
  [[ \"\$(whence -w uvm-ip)\" == 'uvm-ip: function' ]]
  ! alias v >/dev/null 2>&1
  ! alias hm-dev >/dev/null 2>&1
  ! alias docker-nuke >/dev/null 2>&1
"

cat > "$TEST_ROOT/bin/diff-so-fancy" <<'EOF'
#!/bin/sh
cat
EOF
chmod +x "$TEST_ROOT/bin/diff-so-fancy"
GIT_PAGER='less --tabs=4 -RFX' /bin/zsh -dfc "
  source '$HOME/.zshrc'
  [[ \"\$GIT_PAGER\" == 'diff-so-fancy | less --tabs=4 -RFX' ]] || exit 1
"

"$REPO_DIR/setup/mac-thin/bootstrap.sh" --apply >/dev/null
[[ -z "$(find "$HOME" -name '*.backup-*' -print -quit)" ]]
grep -Fq 'bundle install --no-upgrade' "$TEST_ROOT/brew.log"
grep -Fxq 'brew "diff-so-fancy"' "$REPO_DIR/setup/mac-thin/Brewfile"

printf 'Thin Mac bootstrap tests passed.\n'
