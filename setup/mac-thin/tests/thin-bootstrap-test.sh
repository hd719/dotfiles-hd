#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-mac-thin-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p \
  "$TEST_ROOT/bin" \
  "$TEST_ROOT/home/.local/share/nvim/lazy" \
  "$TEST_ROOT/home/.local/share/nvim/site" \
  "$TEST_ROOT/home/.config/herdr" \
  "$TEST_ROOT/home/.config/hunk" \
  "$TEST_ROOT/home/.ssh" \
  "$TEST_ROOT/homebrew/share/zsh-autocomplete" \
  "$TEST_ROOT/homebrew/share/zsh-autosuggestions" \
  "$TEST_ROOT/homebrew/share/zsh-syntax-highlighting" \
  "$TEST_ROOT/apps"
cat > "$TEST_ROOT/home/.ssh/config" <<EOF
Include $REPO_DIR/setup/mac-thin/ssh/ubuntu-vagrant.conf
EOF
printf 'runtime state\n' > "$TEST_ROOT/home/.config/herdr/session"
printf 'hunk state\n' > "$TEST_ROOT/home/.config/hunk/state.json"
touch "$TEST_ROOT/home/.ssh/id_ed25519_ubuntu_vm"
chmod 600 "$TEST_ROOT/home/.ssh/id_ed25519_ubuntu_vm"

for app_name in \
  "1Password.app" \
  "Brave Browser.app" \
  "ChatGPT.app" \
  "Ghostty.app" \
  "Obsidian.app" \
  "Tailscale.app" \
  "VMware Fusion.app" \
  "zoom.us.app"; do
  mkdir -p "$TEST_ROOT/apps/$app_name"
done

cat > "$TEST_ROOT/bin/brew" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$DOTFILES_TEST_BREW_LOG"
if [ "$*" = "reinstall --cask vagrant" ]; then
  cp "$DOTFILES_TEST_VAGRANT_STUB" "$DOTFILES_TEST_BIN/vagrant"
  chmod +x "$DOTFILES_TEST_BIN/vagrant"
fi
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

cat > "$TEST_ROOT/bin/launchctl" <<'EOF'
#!/bin/sh
test "$*" = "print system/com.vagrant.vagrant-vmware-utility"
EOF

cat > "$TEST_ROOT/bin/herdr" <<'EOF'
#!/bin/sh
printf 'herdr %s\n' "$*"
EOF

cat > "$TEST_ROOT/bin/hunk" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "$TEST_ROOT/bin/marksman" <<'EOF'
#!/bin/sh
printf 'marksman %s\n' "$*"
EOF

cat > "$TEST_ROOT/bin/nvim" <<'EOF'
#!/bin/sh
printf 'nvim %s\n' "$*" >> "$DOTFILES_TEST_BREW_LOG"
exit 0
EOF

cat > "$TEST_ROOT/bin/rg" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "$TEST_ROOT/bin/starship" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "init" ]; then
  printf '%s\n' 'prompt_starship_precmd() { :; }'
fi
EOF

cat > "$TEST_ROOT/bin/tree-sitter" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "$TEST_ROOT/bin/zoxide" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "init" ]; then
  printf '%s\n' '__zoxide_z() { :; }'
fi
EOF

cat > "$TEST_ROOT/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh" <<'EOF'
_autocomplete__main() { :; }
EOF

cat > "$TEST_ROOT/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" <<'EOF'
_zsh_autosuggest_start() { :; }
EOF

cat > "$TEST_ROOT/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" <<'EOF'
_zsh_highlight() { :; }
EOF

cat > "$TEST_ROOT/bin/pkgutil" <<'EOF'
#!/bin/sh
test "$*" = "--pkg-info com.apple.pkg.RosettaUpdateAuto" \
  && test -f "$DOTFILES_TEST_ROSETTA_STATE"
EOF

cat > "$TEST_ROOT/bin/softwareupdate" <<'EOF'
#!/bin/sh
printf 'softwareupdate %s\n' "$*" >> "$DOTFILES_TEST_BREW_LOG"
touch "$DOTFILES_TEST_ROSETTA_STATE"
EOF

cat > "$TEST_ROOT/bin/sudo" <<'EOF'
#!/bin/sh
"$@"
EOF

cat > "$TEST_ROOT/vagrant-stub" <<'EOF'
#!/bin/sh
printf 'vagrant %s\n' "$*" >> "$DOTFILES_TEST_BREW_LOG"
if [ "${1:-}" = "plugin" ] && [ "${2:-}" = "list" ]; then
  printf 'vagrant-vmware-desktop (%s, global)\n' \
    "$(cat "$DOTFILES_TEST_VAGRANT_STATE")"
elif [ "${1:-}" = "plugin" ] && [ "${2:-}" = "install" ]; then
  printf '3.0.5\n' > "$DOTFILES_TEST_VAGRANT_STATE"
fi
EOF
cp "$TEST_ROOT/vagrant-stub" "$TEST_ROOT/bin/vagrant"

touch "$TEST_ROOT/vagrant-vmware-utility"
chmod +x \
  "$TEST_ROOT/bin/brew" \
  "$TEST_ROOT/bin/herdr" \
  "$TEST_ROOT/bin/hunk" \
  "$TEST_ROOT/bin/launchctl" \
  "$TEST_ROOT/bin/marksman" \
  "$TEST_ROOT/bin/nvim" \
  "$TEST_ROOT/bin/pkgutil" \
  "$TEST_ROOT/bin/rg" \
  "$TEST_ROOT/bin/softwareupdate" \
  "$TEST_ROOT/bin/starship" \
  "$TEST_ROOT/bin/sudo" \
  "$TEST_ROOT/bin/tree-sitter" \
  "$TEST_ROOT/bin/uname" \
  "$TEST_ROOT/bin/vagrant" \
  "$TEST_ROOT/bin/xcode-select" \
  "$TEST_ROOT/bin/zoxide" \
  "$TEST_ROOT/vagrant-stub" \
  "$TEST_ROOT/vagrant-vmware-utility"
: > "$TEST_ROOT/brew.log"
printf '2.0.0\n' > "$TEST_ROOT/vagrant-plugin-version"

export DOTFILES_ALLOW_DIRTY=1
export DOTFILES_ALLOW_NONCANONICAL=1
export DOTFILES_APPLICATIONS_DIR="$TEST_ROOT/apps"
export DOTFILES_DIR="$REPO_DIR"
export DOTFILES_TEST_BREW_LOG="$TEST_ROOT/brew.log"
export DOTFILES_TEST_BIN="$TEST_ROOT/bin"
export DOTFILES_TEST_ROSETTA_STATE="$TEST_ROOT/rosetta-installed"
export DOTFILES_TEST_VAGRANT_STUB="$TEST_ROOT/vagrant-stub"
export DOTFILES_TEST_VAGRANT_STATE="$TEST_ROOT/vagrant-plugin-version"
export DOTFILES_VAGRANT_VMWARE_UTILITY="$TEST_ROOT/vagrant-vmware-utility"
export HOMEBREW_PREFIX="$TEST_ROOT/homebrew"
export DOTFILES_PKGUTIL="$TEST_ROOT/bin/pkgutil"
export DOTFILES_SOFTWAREUPDATE="$TEST_ROOT/bin/softwareupdate"
export DOTFILES_SUDO="$TEST_ROOT/bin/sudo"
export HOME="$TEST_ROOT/home"
export PATH="$TEST_ROOT/bin:/usr/bin:/bin"

"$REPO_DIR/setup/mac-thin/bootstrap.sh" --dry-run >/dev/null
[[ ! -e "$HOME/.zshrc" ]]

"$REPO_DIR/setup/mac-thin/bootstrap.sh" --apply >/dev/null
[[ -f "$DOTFILES_TEST_ROSETTA_STATE" ]]
[[ "$(git config --global --includes --get alias.st)" == "status" ]]
[[ "$(readlink "$HOME/.zshrc")" == "$REPO_DIR/setup/mac-thin/.zshrc" ]]
[[ "$(readlink "$HOME/Library/Application Support/com.mitchellh.ghostty/config")" \
  == "$REPO_DIR/config/ghostty/config" ]]
[[ "$(readlink "$HOME/.config/herdr/config.toml")" \
  == "$REPO_DIR/config/herdr/config.toml" ]]
[[ "$(readlink "$HOME/.config/hunk/config.toml")" \
  == "$REPO_DIR/config/hunk/config.toml" ]]
[[ "$(readlink "$HOME/.config/nvim")" == "$REPO_DIR/config/nvim" ]]
[[ "$(readlink "$HOME/.config/starship.toml")" \
  == "$REPO_DIR/config/starship/starship.toml" ]]
[[ "$(<"$HOME/.config/herdr/session")" == "runtime state" ]]
[[ "$(<"$HOME/.config/hunk/state.json")" == "hunk state" ]]
grep -Fxq 'selection-background = #9ABACE' "$REPO_DIR/config/ghostty/config"
grep -Fxq 'selection-foreground = #000001' "$REPO_DIR/config/ghostty/config"
GIT_PAGER='diff-so-fancy | less --tabs=4 -RFX' /bin/zsh -dfc "
  source '$HOME/.zshrc'
  [[ -z \"\${GIT_PAGER+x}\" ]] || exit 1
  [[ \"\$DOTFILES_NVIM_PROFILE\" == thin ]]
  [[ \"\$EDITOR\" == nvim ]]
  [[ \"\$VISUAL\" == nvim ]]
  [[ \"\$GIT_EDITOR\" == nvim ]]
  [[ \"\$(alias g)\" == 'g=git' ]]
  [[ \"\$(alias gs)\" == \"gs='git status'\" ]]
  [[ \"\$(alias hdiff)\" == \"hdiff='hunk diff'\" ]]
  [[ \"\$(alias hstaged)\" == \"hstaged='hunk diff --staged'\" ]]
  [[ \"\$(alias hshow)\" == \"hshow='hunk show'\" ]]
  [[ \"\$(alias hwatch)\" == \"hwatch='hunk diff --watch'\" ]]
  ! alias gdiff >/dev/null 2>&1
  [[ \"\$(alias cod)\" == 'cod=codex' ]]
  [[ \"\$(alias codu)\" == \"codu='codex update'\" ]]
  [[ \"\$(alias dots)\" == \"dots='cd ~/Developer/dotfiles-hd'\" ]]
  [[ \"\$(alias vault)\" == \"vault='cd ~/Developer/hd'\" ]]
  [[ \"\$(alias u)\" == \"u='ssh ubuntu-vm'\" ]]
  [[ \"\$(alias ut)\" == \"ut='ssh ubuntu-vm-ts'\" ]]
  [[ \"\$(alias hu)\" == \"hu='herdr --remote ubuntu-vm'\" ]]
  [[ \"\$(alias hut)\" == \"hut='herdr --remote ubuntu-vm-ts'\" ]]
  ! alias uc >/dev/null 2>&1
  ! alias uct >/dev/null 2>&1
  ! alias ubuntu >/dev/null 2>&1
  ! alias ubuntu-ts >/dev/null 2>&1
  ! alias uvm-open >/dev/null 2>&1
  [[ \"\$(whence -w reload)\" == 'reload: function' ]]
  [[ \"\$(whence -w uvm-status)\" == 'uvm-status: function' ]]
  [[ \"\$(whence -w uvm-ip)\" == 'uvm-ip: function' ]]
  [[ \"\$(whence -w uvm-up)\" == 'uvm-up: function' ]]
  [[ \"\$(whence -w uvm-up-headless)\" != 'uvm-up-headless: function' ]]
  [[ \"\$(whence -w uvm-stop)\" == 'uvm-stop: function' ]]
  [[ \"\$(whence -w uvm-suspend)\" == 'uvm-suspend: function' ]]
  [[ \"\$(whence -w uvm-resume)\" == 'uvm-resume: function' ]]
  [[ \"\$(whence -w uvm-destroy)\" == 'uvm-destroy: function' ]]
  ! alias v >/dev/null 2>&1
  ! alias hm-dev >/dev/null 2>&1
  ! alias docker-nuke >/dev/null 2>&1
"
HOMEBREW_PREFIX="$TEST_ROOT/homebrew" TERM=xterm-256color /bin/zsh -dfic "
  source '$HOME/.zshrc'
  whence -w _zsh_highlight >/dev/null
"

"$REPO_DIR/setup/mac-thin/bootstrap.sh" --apply >/dev/null
[[ -z "$(find "$HOME" -name '*.backup-*' -print -quit)" ]]
rm "$TEST_ROOT/bin/vagrant"
"$REPO_DIR/setup/mac-thin/bootstrap.sh" --apply >/dev/null
[[ -x "$TEST_ROOT/bin/vagrant" ]]
grep -Fq 'bundle install --no-upgrade' "$TEST_ROOT/brew.log"
grep -Fq 'reinstall --cask vagrant' "$TEST_ROOT/brew.log"
[[ "$(grep -c '^softwareupdate --install-rosetta --agree-to-license$' \
  "$TEST_ROOT/brew.log")" == "1" ]]
grep -Fq \
  'vagrant plugin install vagrant-vmware-desktop --plugin-version 3.0.5' \
  "$TEST_ROOT/brew.log"
grep -Fq 'nvim --headless +Lazy! restore +qa' "$TEST_ROOT/brew.log"
grep -Fq "markdown_inline" "$TEST_ROOT/brew.log"
grep -Fxq 'brew "gh"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'brew "herdr"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'brew "hunk"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'brew "marksman"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'brew "neovim"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'brew "ripgrep"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'brew "starship"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'brew "tree-sitter-cli"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'brew "zoxide"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'brew "zsh-autocomplete"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'brew "zsh-autosuggestions"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'brew "zsh-syntax-highlighting"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'cask "vagrant"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'cask "vagrant-vmware-utility"' "$REPO_DIR/setup/mac-thin/Brewfile"
grep -Fxq 'cask "zoom"' "$REPO_DIR/setup/mac-thin/Brewfile"
! grep -Fq 'diff-so-fancy' "$REPO_DIR/setup/mac-thin/Brewfile"

printf 'Thin Mac bootstrap tests passed.\n'
