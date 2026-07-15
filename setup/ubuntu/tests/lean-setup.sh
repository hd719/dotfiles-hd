#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
SETUP_SCRIPT="$ROOT_DIR/setup/ubuntu/setup.sh"
NEOVIM_SCRIPT="$ROOT_DIR/setup/ubuntu/setup-neovim.sh"
UPDATE_SCRIPT="$ROOT_DIR/setup/ubuntu/update-system.sh"
CLEANUP_SCRIPT="$ROOT_DIR/setup/ubuntu/cleanup-legacy.sh"
MISE_CONFIG="$ROOT_DIR/setup/ubuntu/mise.toml"
ZSH_CONFIG="$ROOT_DIR/setup/ubuntu/.zshrc"
GHOSTTY_CONFIG="$ROOT_DIR/setup/ubuntu/ghostty.conf"
GRAPHQL_WRAPPER="$ROOT_DIR/setup/ubuntu/bin/graphql-lsp"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

assert_file_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "$file is missing: $text"
}

test_wrong_os_stops_before_mutation() {
  local case_dir="$TEST_ROOT/wrong-os"
  local output status

  mkdir -p "$case_dir/home" "$case_dir/bin"
  printf 'ID=fedora\nVERSION_ID=42\n' > "$case_dir/os-release"

  cat > "$case_dir/bin/sudo" <<EOF
#!/usr/bin/env bash
printf 'sudo %s\n' "\$*" >> "$case_dir/mutations.log"
EOF
  chmod +x "$case_dir/bin/sudo"

  set +e
  output="$({
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_OS_RELEASE_FILE="$case_dir/os-release" \
      bash "$SETUP_SCRIPT"
  } 2>&1)"
  status=$?
  set -e

  ((status != 0)) || fail "non-Ubuntu setup unexpectedly succeeded"
  assert_contains "$output" "supports Ubuntu only"
  [[ ! -s "$case_dir/mutations.log" ]] || fail "non-Ubuntu setup attempted a privileged mutation"
}

test_help_is_read_only() {
  local output

  output="$(bash "$SETUP_SCRIPT" --help)"
  assert_contains "$output" "Usage:"
  assert_contains "$output" "lean Ubuntu workstation"
}

test_neovim_help_is_read_only() {
  local output

  output="$(bash "$NEOVIM_SCRIPT" --help)"
  assert_contains "$output" "Usage:"
  assert_contains "$output" "--check"
}

test_cleanup_requires_explicit_confirmation() {
  local case_dir="$TEST_ROOT/cleanup-confirmation"
  local output status

  mkdir -p "$case_dir/home" "$case_dir/bin"
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' > "$case_dir/os-release"
  cat > "$case_dir/bin/sudo" <<EOF
#!/usr/bin/env bash
printf 'sudo %s\n' "\$*" >> "$case_dir/mutations.log"
EOF
  chmod +x "$case_dir/bin/sudo"

  set +e
  output="$({
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_OS_RELEASE_FILE="$case_dir/os-release" \
      bash "$CLEANUP_SCRIPT"
  } 2>&1)"
  status=$?
  set -e

  ((status != 0)) || fail "legacy cleanup ran without explicit confirmation"
  assert_contains "$output" "--yes"
  [[ ! -s "$case_dir/mutations.log" ]] || fail "unconfirmed legacy cleanup attempted a privileged mutation"
}

test_ubuntu_mise_toolchain_is_exact() {
  local expected

  [[ -f "$MISE_CONFIG" ]] || fail "Ubuntu mise config is missing"
  if grep -Eq '=[[:space:]]*"latest"' "$MISE_CONFIG"; then
    fail "Ubuntu mise config contains an unpinned latest version"
  fi

  while IFS= read -r expected; do
    [[ -n "$expected" ]] && assert_file_contains "$MISE_CONFIG" "$expected"
  done <<'EOF'
min_version = "2026.7.5"
node = "24.18.0"
go = "1.26.5"
python = "3.14.6"
bun = "1.3.14"
"aqua:pnpm/pnpm" = "11.13.0"
"aqua:neovim/neovim" = "0.12.4"
"aqua:BurntSushi/ripgrep" = "15.1.0"
"aqua:sharkdp/fd" = "10.4.2"
"aqua:junegunn/fzf" = "0.74.0"
"aqua:jesseduffield/lazygit" = "0.63.0"
"aqua:tree-sitter/tree-sitter" = "0.26.11"
"aqua:LuaLS/lua-language-server" = "3.18.2"
"aqua:JohnnyMorganz/StyLua" = "2.5.2"
"aqua:astral-sh/uv" = "0.11.28"
"aqua:astral-sh/ruff" = "0.15.21"
"aqua:starship/starship" = "1.26.0"
"aqua:ajeetdsouza/zoxide" = "0.10.0"
"aqua:koalaman/shellcheck" = "0.11.0"
"go:golang.org/x/tools/gopls" = { version = "0.23.0", depends = ["go"] }
"npm:@vtsls/language-server" = { version = "0.3.0", depends = ["node"] }
"npm:vscode-langservers-extracted" = { version = "4.10.0", depends = ["node"] }
"npm:bash-language-server" = { version = "5.6.0", depends = ["node"] }
"npm:graphql-language-service-cli" = { version = "3.5.0", depends = ["node"] }
EOF
}

test_nerd_font_download_is_pinned() {
  assert_file_contains "$SETUP_SCRIPT" 'NERD_FONT_VERSION="3.4.0"'
  assert_file_contains "$SETUP_SCRIPT" 'NERD_FONT_SHA256="e82418895a7036158baf9a425faea7de1fe332267b218341eec44c6b5071d1ad"'
  assert_file_contains "$SETUP_SCRIPT" 'sha256sum -c -'
  assert_file_contains "$SETUP_SCRIPT" '.nerd-font-version'
}

test_zsh_config_is_linux_native() {
  local forbidden output

  while IFS= read -r expected; do
    [[ -n "$expected" ]] && assert_file_contains "$ZSH_CONFIG" "$expected"
  done <<'EOF'
export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="nvim"
eval "$(mise activate zsh)"
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"
/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
alias gs='git status --short --branch'
alias dc='docker compose'
EOF

  for forbidden in mac-vm linuxbrew rbenv 'code --wait' kubectl terraform; do
    if grep -Fq -- "$forbidden" "$ZSH_CONFIG"; then
      fail "Ubuntu zsh config still references: $forbidden"
    fi
  done

  output="$(
    HOME="$TEST_ROOT/zsh-home" \
      PATH="/usr/bin:/bin" \
      TERM="xterm-test" \
      zsh -f -c 'source "$1"; printf "%s|%s|%s" "$EDITOR" "$TERM" "$path[1]"' _ "$ZSH_CONFIG"
  )"
  [[ "$output" == "nvim|xterm-test|$TEST_ROOT/zsh-home/.local/bin" ]] || fail "Ubuntu zsh config did not load cleanly in isolation"
}

test_setup_is_lean_and_rerunnable() {
  local case_dir="$TEST_ROOT/lean-setup"
  local output backup_count forbidden

  mkdir -p "$case_dir/home/.config" "$case_dir/home/.local/share/fonts/Hasklig" "$case_dir/bin" "$case_dir/legacy-ghostty"
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' > "$case_dir/os-release"
  printf 'legacy zsh config\n' > "$case_dir/home/.zshrc"
  printf '3.4.0\n' > "$case_dir/home/.local/share/fonts/Hasklig/.nerd-font-version"
  printf 'legacy shared Ghostty config\n' > "$case_dir/legacy-ghostty/config"
  ln -s "$case_dir/legacy-ghostty" "$case_dir/home/.config/ghostty"

  cat > "$case_dir/bin/sudo" <<EOF
#!/usr/bin/env bash
printf 'sudo %s\n' "\$*" >> "$case_dir/mutations.log"
EOF
  cat > "$case_dir/bin/fc-list" <<'EOF'
#!/usr/bin/env bash
printf 'Hasklug Nerd Font\n'
EOF
  cat > "$case_dir/fake-neovim-setup.sh" <<EOF
#!/usr/bin/env bash
printf 'neovim %s\n' "\$*" >> "$case_dir/mutations.log"
EOF
  chmod +x "$case_dir/bin/sudo" "$case_dir/bin/fc-list" "$case_dir/fake-neovim-setup.sh"

  output="$({
    HOME="$case_dir/home" \
      USER=hamel \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_OS_RELEASE_FILE="$case_dir/os-release" \
      DOTFILES_NEOVIM_SETUP_SCRIPT="$case_dir/fake-neovim-setup.sh" \
      bash "$SETUP_SCRIPT"
  } 2>&1)"
  assert_contains "$output" "Ubuntu workstation setup complete"

  [[ -L "$case_dir/home/.zshrc" ]] || fail "setup did not link .zshrc"
  [[ "$(readlink "$case_dir/home/.zshrc")" == "$ZSH_CONFIG" ]] || fail ".zshrc points to the wrong source"
  [[ -L "$case_dir/home/.config/ghostty/config" ]] || fail "setup did not link Ghostty config"
  [[ "$(readlink "$case_dir/home/.config/ghostty/config")" == "$GHOSTTY_CONFIG" ]] || fail "Ghostty config points to the wrong source"
  [[ -d "$case_dir/home/.config/ghostty" && ! -L "$case_dir/home/.config/ghostty" ]] || fail "setup did not repair a whole-directory Ghostty link"
  [[ "$(find "$case_dir/home/.config" -maxdepth 1 -name 'ghostty.backup.*' | wc -l | tr -d ' ')" == "1" ]] || fail "setup did not preserve the whole-directory Ghostty link"
  assert_file_contains "$case_dir/legacy-ghostty/config" "legacy shared Ghostty config"
  [[ -L "$case_dir/home/.config/starship.toml" ]] || fail "setup did not link Starship config"

  assert_file_contains "$case_dir/mutations.log" "apt-get update"
  assert_file_contains "$case_dir/mutations.log" "docker.io"
  assert_file_contains "$case_dir/mutations.log" "docker-compose-v2"
  assert_file_contains "$case_dir/mutations.log" "ghostty"
  assert_file_contains "$case_dir/mutations.log" "systemctl enable --now docker"
  assert_file_contains "$case_dir/mutations.log" "usermod -aG docker hamel"
  assert_file_contains "$case_dir/mutations.log" "neovim"

  backup_count="$(find "$case_dir/home" -maxdepth 1 -name '.zshrc.backup.*' | wc -l | tr -d ' ')"
  [[ "$backup_count" == "1" ]] || fail "setup did not preserve the original .zshrc exactly once"

  HOME="$case_dir/home" \
    USER=hamel \
    PATH="$case_dir/bin:/usr/bin:/bin" \
    DOTFILES_OS_RELEASE_FILE="$case_dir/os-release" \
    DOTFILES_NEOVIM_SETUP_SCRIPT="$case_dir/fake-neovim-setup.sh" \
    bash "$SETUP_SCRIPT" >/dev/null

  backup_count="$(find "$case_dir/home" -maxdepth 1 -name '.zshrc.backup.*' | wc -l | tr -d ' ')"
  [[ "$backup_count" == "1" ]] || fail "rerunning setup created another .zshrc backup"

  while IFS= read -r expected; do
    [[ -n "$expected" ]] && assert_file_contains "$SETUP_SCRIPT" "$expected"
  done <<'EOF'
ghostty
docker.io
docker-compose-v2
imagemagick
ghostscript
wl-clipboard
xclip
zsh-autosuggestions
zsh-syntax-highlighting
EOF

  for forbidden in snap flatpak code aws terraform kubectl redis download.docker.com linuxbrew; do
    if grep -Eiq "(^|[^[:alnum:]_-])${forbidden}([^[:alnum:]_-]|$)" "$SETUP_SCRIPT"; then
      fail "lean setup still references: $forbidden"
    fi
  done
}

test_setup_propagates_package_failure() {
  local case_dir="$TEST_ROOT/package-failure"
  local output status

  mkdir -p "$case_dir/home" "$case_dir/bin"
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' > "$case_dir/os-release"

  cat > "$case_dir/bin/sudo" <<EOF
#!/usr/bin/env bash
printf 'sudo %s\n' "\$*" >> "$case_dir/commands.log"
[[ "\$*" != *"apt-get install"* ]]
EOF
  cat > "$case_dir/bin/fc-list" <<'EOF'
#!/usr/bin/env bash
printf 'Hasklug Nerd Font\n'
EOF
  cat > "$case_dir/fake-neovim-setup.sh" <<EOF
#!/usr/bin/env bash
printf 'neovim\n' >> "$case_dir/commands.log"
EOF
  chmod +x "$case_dir/bin/sudo" "$case_dir/bin/fc-list" "$case_dir/fake-neovim-setup.sh"

  set +e
  output="$({
    HOME="$case_dir/home" \
      USER=hamel \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_OS_RELEASE_FILE="$case_dir/os-release" \
      DOTFILES_NEOVIM_SETUP_SCRIPT="$case_dir/fake-neovim-setup.sh" \
      bash "$SETUP_SCRIPT"
  } 2>&1)"
  status=$?
  set -e

  ((status != 0)) || fail "setup ignored an APT package failure"
  [[ "$output" != *"Ubuntu workstation setup complete"* ]] || fail "failed setup printed success"
  if grep -Fq "neovim" "$case_dir/commands.log"; then
    fail "setup continued to Neovim after an APT package failure"
  fi
}

test_obsolete_ubuntu_helpers_are_gone() {
  local file

  for file in install-ruby-lts.sh setup-ulauncher.sh; do
    [[ ! -e "$ROOT_DIR/setup/ubuntu/$file" ]] || fail "obsolete Ubuntu helper remains: $file"
  done
}

test_neovim_setup_installs_and_checks_daily_driver() {
  local case_dir="$TEST_ROOT/neovim-setup"
  local output tool
  local tools=(
    bash-language-server bun fd fzf go gopls graphql-lsp gs lazygit lua-language-server
    magick mdformat node nvim pnpm python rg ruff shellcheck starship stylua tree-sitter uv wl-copy xclip
    vscode-css-language-server vscode-eslint-language-server
    vscode-html-language-server vscode-json-language-server vtsls zoxide
  )

  mkdir -p "$case_dir/home/.config" "$case_dir/home/.local/bin" "$case_dir/bin"
  ln -s "$case_dir/missing-mise-config" "$case_dir/home/.config/mise"

  cat > "$case_dir/bin/mise" <<EOF
#!/usr/bin/env bash
printf 'mise %s\n' "\$*" >> "$case_dir/commands.log"
if [[ "\${1:-}" == "exec" ]]; then
  shift
  [[ "\${1:-}" == "--" ]] && shift
  exec "\$@"
fi
if [[ "\${1:-}" == "which" ]]; then
  [[ "\${MISE_AUTO_INSTALL:-}" == "0" ]] || exit 91
  printf '%s\n' "$case_dir/bin/\${2:?}"
fi
exit 0
EOF

  for tool in "${tools[@]}"; do
    cat > "$case_dir/bin/$tool" <<EOF
#!/usr/bin/env bash
printf '$tool %s\n' "\$*" >> "$case_dir/commands.log"
exit 0
EOF
    chmod +x "$case_dir/bin/$tool"
  done
  chmod +x "$case_dir/bin/mise"

  HOME="$case_dir/home" \
    PATH="$case_dir/bin:/usr/bin:/bin" \
    DOTFILES_MISE_BIN="$case_dir/bin/mise" \
    bash "$NEOVIM_SCRIPT"

  [[ -L "$case_dir/home/.config/mise/config.toml" ]] || fail "Neovim setup did not link mise config"
  [[ "$(readlink "$case_dir/home/.config/mise/config.toml")" == "$MISE_CONFIG" ]] || fail "mise config points to the wrong source"
  [[ -d "$case_dir/home/.config/mise" && ! -L "$case_dir/home/.config/mise" ]] || fail "Neovim setup did not repair a stale mise directory link"
  [[ "$(find "$case_dir/home/.config" -maxdepth 1 -name 'mise.backup.*' | wc -l | tr -d ' ')" == "1" ]] || fail "Neovim setup did not preserve the stale mise directory link"
  [[ -L "$case_dir/home/.config/nvim" ]] || fail "Neovim setup did not link Neovim config"
  [[ "$(readlink "$case_dir/home/.config/nvim")" == "$ROOT_DIR/config/nvim" ]] || fail "Neovim config points to the wrong source"
  [[ -L "$case_dir/home/.local/graphql-lsp/bin/graphql-lsp" ]] || fail "Neovim setup did not link GraphQL wrapper"
  [[ "$(readlink "$case_dir/home/.local/graphql-lsp/bin/graphql-lsp")" == "$GRAPHQL_WRAPPER" ]] || fail "GraphQL wrapper points to the wrong source"

  assert_file_contains "$case_dir/commands.log" "mise self-update -y"
  assert_file_contains "$case_dir/commands.log" "mise install node@24.18.0 go@1.26.5 python@3.14.6 bun@1.3.14"
  assert_file_contains "$case_dir/commands.log" "mise install"
  assert_file_contains "$case_dir/commands.log" "mise reshim"
  assert_file_contains "$case_dir/commands.log" "mdformat==1.0.0"
  assert_file_contains "$case_dir/commands.log" "mdformat-gfm==1.0.0"
  assert_file_contains "$case_dir/commands.log" "mdformat-frontmatter==2.1.2"
  assert_file_contains "$case_dir/commands.log" "mdformat-footnote==0.1.3"
  assert_file_contains "$case_dir/commands.log" "mdformat-gfm-alerts==2.0.0"
  assert_file_contains "$case_dir/commands.log" "mdformat-wikilink==0.3.0"
  assert_file_contains "$case_dir/commands.log" "nvim --headless +Lazy! restore +qa"

  : > "$case_dir/commands.log"
  output="$(
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_MISE_BIN="$case_dir/bin/mise" \
      bash "$NEOVIM_SCRIPT" --check
  )"
  assert_contains "$output" "Neovim daily-driver check passed"
  assert_file_contains "$case_dir/commands.log" "mise which graphql-lsp"
  if grep -Fq "mise install" "$case_dir/commands.log"; then
    fail "Neovim --check attempted to install tools"
  fi
}

test_update_system_stays_lean() {
  local case_dir="$TEST_ROOT/update-system"
  local output forbidden

  mkdir -p "$case_dir/home" "$case_dir/bin"
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' > "$case_dir/os-release"

  cat > "$case_dir/bin/sudo" <<EOF
#!/usr/bin/env bash
printf 'sudo %s\n' "\$*" >> "$case_dir/commands.log"
EOF
  cat > "$case_dir/bin/mise" <<EOF
#!/usr/bin/env bash
printf 'mise %s\n' "\$*" >> "$case_dir/commands.log"
EOF
  cat > "$case_dir/fake-neovim-setup.sh" <<EOF
#!/usr/bin/env bash
printf 'neovim %s\n' "\$*" >> "$case_dir/commands.log"
EOF
  chmod +x "$case_dir/bin/sudo" "$case_dir/bin/mise" "$case_dir/fake-neovim-setup.sh"

  output="$({
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_OS_RELEASE_FILE="$case_dir/os-release" \
      DOTFILES_MISE_BIN="$case_dir/bin/mise" \
      DOTFILES_NEOVIM_SETUP_SCRIPT="$case_dir/fake-neovim-setup.sh" \
      bash "$UPDATE_SCRIPT"
  } 2>&1)"
  assert_contains "$output" "Ubuntu update complete"
  assert_file_contains "$case_dir/commands.log" "apt-get update"
  assert_file_contains "$case_dir/commands.log" "apt-get full-upgrade -y"
  assert_file_contains "$case_dir/commands.log" "apt-get autoremove -y"
  assert_file_contains "$case_dir/commands.log" "mise self-update -y"
  assert_file_contains "$case_dir/commands.log" "neovim"

  for forbidden in snap flatpak rustup 'pnpm update' 'uv self update' npm npx; do
    if grep -Fq -- "$forbidden" "$UPDATE_SCRIPT"; then
      fail "lean updater still references: $forbidden"
    fi
  done
}

test_cleanup_removes_only_known_legacy_tools() {
  local case_dir="$TEST_ROOT/cleanup-legacy"
  local output

  mkdir -p \
    "$case_dir/home/.config/autostart" \
    "$case_dir/home/.config/ulauncher" \
    "$case_dir/home/.local/bin" \
    "$case_dir/home/.local/nvim-node-tools" \
    "$case_dir/home/.local/opt/nvim" \
    "$case_dir/home/.local/share/diff-so-fancy" \
    "$case_dir/home/.local/share/pnpm" \
    "$case_dir/home/.local/share/ulauncher" \
    "$case_dir/home/.rbenv" \
    "$case_dir/home/Developer/zsh-plugins/custom-plugin" \
    "$case_dir/home/Developer/zsh-plugins/zsh-autosuggestions" \
    "$case_dir/home/Developer/zsh-plugins/zsh-syntax-highlighting" \
    "$case_dir/home/Developer/zsh-plugins/zsh-you-should-use" \
    "$case_dir/root/etc/apt/keyrings" \
    "$case_dir/root/etc/apt/sources.list.d" \
    "$case_dir/root/usr/local/aws-cli" \
    "$case_dir/root/usr/local/bin" \
    "$case_dir/bin"
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' > "$case_dir/os-release"
  touch \
    "$case_dir/home/.config/autostart/ulauncher.desktop" \
    "$case_dir/home/.local/bin/bash-language-server" \
    "$case_dir/home/.local/bin/diff-so-fancy" \
    "$case_dir/home/.local/bin/nvim" \
    "$case_dir/home/.local/bin/uv" \
    "$case_dir/home/.local/bin/zoxide" \
    "$case_dir/home/keep-me" \
    "$case_dir/home/Developer/zsh-plugins/custom-plugin/keep-me" \
    "$case_dir/root/etc/apt/keyrings/docker.gpg" \
    "$case_dir/root/etc/apt/keyrings/packages.microsoft.gpg" \
    "$case_dir/root/etc/apt/sources.list.d/docker.list" \
    "$case_dir/root/etc/apt/sources.list.d/example-ulauncher.sources" \
    "$case_dir/root/etc/apt/sources.list.d/example-fastfetch.sources" \
    "$case_dir/root/etc/apt/sources.list.d/vscode.list" \
    "$case_dir/root/usr/local/aws-cli/aws" \
    "$case_dir/root/usr/local/bin/aws" \
    "$case_dir/root/usr/local/bin/kubectl" \
    "$case_dir/root/usr/local/bin/terraform"

  cat > "$case_dir/bin/sudo" <<EOF
#!/usr/bin/env bash
printf 'sudo %s\n' "\$*" >> "$case_dir/commands.log"
if [[ "\${1:-}" == "rm" ]]; then
  exec "\$@"
fi
EOF
  cat > "$case_dir/bin/dpkg-query" <<'EOF'
#!/usr/bin/env bash
cat <<'PACKAGES'
code	ii
containerd.io	rc
docker-ce	rc
fastfetch	ii
golang:arm64	ii
golang-github-example-library	ii
redis-server	ii
redis-tools	ii
ulauncher	ii
PACKAGES
EOF
  cat > "$case_dir/bin/snap" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == "list" && "${2:-}" == "ghostty" ]]
EOF
  cat > "$case_dir/bin/gsettings" <<EOF
#!/usr/bin/env bash
printf 'gsettings %s\n' "\$*" >> "$case_dir/commands.log"
if [[ "\${1:-}" == "get" && "\${2:-}" == "org.gnome.settings-daemon.plugins.media-keys" ]]; then
  printf "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']\n"
elif [[ "\${1:-}" == "get" && "\${2:-}" == *"custom0/" ]]; then
  case "\${3:-}" in
    name) printf "'Ulauncher'\n" ;;
    command) printf "'ulauncher-toggle'\n" ;;
    binding) printf "'<Super>space'\n" ;;
  esac
elif [[ "\${1:-}" == "get" && "\${2:-}" == *"custom1/" ]]; then
  printf "'Keep Me'\n"
fi
EOF
  chmod +x "$case_dir/bin/sudo" "$case_dir/bin/dpkg-query" "$case_dir/bin/snap" "$case_dir/bin/gsettings"

  output="$({
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_OS_RELEASE_FILE="$case_dir/os-release" \
      DOTFILES_ROOT_PREFIX="$case_dir/root" \
      bash "$CLEANUP_SCRIPT" --yes
  } 2>&1)"
  assert_contains "$output" "Legacy Ubuntu cleanup complete"

  assert_file_contains "$case_dir/commands.log" "apt-get purge -y"
  assert_file_contains "$case_dir/commands.log" "docker-ce"
  assert_file_contains "$case_dir/commands.log" "golang:arm64"
  assert_file_contains "$case_dir/commands.log" "redis-server"
  assert_file_contains "$case_dir/commands.log" "ulauncher"
  assert_file_contains "$case_dir/commands.log" "snap remove ghostty"
  assert_file_contains "$case_dir/commands.log" "apt-get autoremove -y"
  assert_file_contains "$case_dir/commands.log" "reset-recursively org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
  assert_file_contains "$case_dir/commands.log" "set org.gnome.settings-daemon.plugins.media-keys custom-keybindings ['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"
  assert_file_contains "$case_dir/commands.log" "reset org.gnome.desktop.wm.keybindings switch-input-source"
  assert_file_contains "$case_dir/commands.log" "reset org.gnome.desktop.wm.keybindings switch-input-source-backward"
  if grep -Fq "golang-github-example-library" "$case_dir/commands.log"; then
    fail "cleanup selected an unrelated Go library package"
  fi

  [[ ! -e "$case_dir/root/usr/local/bin/aws" ]] || fail "cleanup left the legacy AWS binary"
  [[ ! -e "$case_dir/root/usr/local/bin/terraform" ]] || fail "cleanup left the legacy Terraform binary"
  [[ ! -e "$case_dir/root/usr/local/bin/kubectl" ]] || fail "cleanup left the legacy kubectl binary"
  [[ ! -e "$case_dir/root/etc/apt/sources.list.d/docker.list" ]] || fail "cleanup left the Docker CE source"
  [[ ! -e "$case_dir/home/.rbenv" ]] || fail "cleanup left rbenv"
  [[ ! -e "$case_dir/home/.config/ulauncher" ]] || fail "cleanup left Ulauncher config"
  [[ ! -e "$case_dir/home/.local/share/ulauncher" ]] || fail "cleanup left Ulauncher data"
  [[ ! -e "$case_dir/home/.local/bin/nvim" ]] || fail "cleanup left the legacy Neovim shim"
  [[ ! -e "$case_dir/home/.local/share/pnpm" ]] || fail "cleanup left the standalone pnpm home"
  [[ -e "$case_dir/home/keep-me" ]] || fail "cleanup removed unrelated user data"
  [[ -e "$case_dir/home/Developer/zsh-plugins/custom-plugin/keep-me" ]] || fail "cleanup removed an unrelated Zsh plugin"
}

test_wrong_os_stops_before_mutation
test_help_is_read_only
test_neovim_help_is_read_only
test_cleanup_requires_explicit_confirmation
test_ubuntu_mise_toolchain_is_exact
test_nerd_font_download_is_pinned
test_zsh_config_is_linux_native
test_setup_is_lean_and_rerunnable
test_setup_propagates_package_failure
test_neovim_setup_installs_and_checks_daily_driver
test_update_system_stays_lean
test_cleanup_removes_only_known_legacy_tools
test_obsolete_ubuntu_helpers_are_gone
printf 'lean_setup_tests=ok\n'
