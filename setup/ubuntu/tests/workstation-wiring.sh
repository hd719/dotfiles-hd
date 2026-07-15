#!/usr/bin/env bash
# Validate the safe wiring around the larger Ubuntu workstation bootstrap.
set -euo pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
SETUP="$SOURCE_ROOT/setup/ubuntu/setup.sh"
UPDATE="$SOURCE_ROOT/setup/ubuntu/update-system.sh"
LINKER="$SOURCE_ROOT/setup/ubuntu/link-configs.sh"
ZSHRC="$SOURCE_ROOT/setup/ubuntu/.zshrc"
NVIM_BOOTSTRAP="$SOURCE_ROOT/setup/nvim/bootstrap.sh"
NVIM_ADAPTER="$SOURCE_ROOT/setup/ubuntu/install-neovim-dependencies.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ubuntu-workstation-wiring.XXXXXX")"
REAL_BASH="$(command -v bash)"
failures=0
trap 'rm -rf "$TMP_ROOT"' EXIT

expect() {
  local label="$1"
  shift

  if ! "$@"; then
    echo "FAIL: $label" >&2
    failures=$((failures + 1))
  fi
}

expect "workstation setup has valid Bash syntax" bash -n "$SETUP"
expect "Ubuntu updater has valid Bash syntax" bash -n "$UPDATE"
expect "Ubuntu login config has valid Zsh syntax" zsh -n "$ZSHRC"

expect "setup derives the checkout from BASH_SOURCE" \
  grep -Fq 'dirname "${BASH_SOURCE[0]}"' "$SETUP"
expect "mise installer runs from the selected checkout" \
  grep -Fq '"$DOTFILES_DIR/setup/ubuntu/install-mise.sh"' "$SETUP"
expect "Neovim adapter runs from the selected checkout" \
  grep -Fq '"$DOTFILES_DIR/setup/ubuntu/install-neovim-dependencies.sh"' "$SETUP"
expect "Neovim commands use the controlled mise directory" \
  grep -Fq 'mise -C "$MISE_CONFIG_DIR" exec --' "$SETUP"
if grep -Eq '(^|[[:space:]])mise exec --' "$SETUP"; then
  echo "FAIL: workstation setup must not inherit a caller project mise config" >&2
  failures=$((failures + 1))
fi
expect "Ubuntu updater checks the controlled mise directory" \
  grep -Fq 'mise -C "$config_dir" outdated' "$UPDATE"
if grep -Fq 'mise activate' "$UPDATE"; then
  echo "FAIL: Ubuntu updater must not activate a caller project config" >&2
  failures=$((failures + 1))
fi
expect "Ubuntu linker owns the login-shell link" \
  grep -Fq 'link_path "$DOTFILES_DIR/setup/ubuntu/.zshrc" "$HOME/.zshrc"' "$LINKER"

# ~/.zshrc is a link into the repository. Writing through that link would dirty
# the checkout and duplicate the plugin sources already kept in the tracked file.
if grep -Eq '>>[[:space:]]*(~|"?\$HOME)/\.zshrc' "$SETUP"; then
  echo "FAIL: workstation setup must not append through the tracked zshrc link" >&2
  failures=$((failures + 1))
fi

for plugin_file in \
  'zsh-autosuggestions/zsh-autosuggestions.zsh' \
  'zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' \
  'zsh-you-should-use/you-should-use.plugin.zsh'
do
  expect "tracked zshrc sources $plugin_file" grep -Fq "$plugin_file" "$ZSHRC"
done

# Model mise's `-C` behavior from a hostile project directory. The command path
# must be absolute because mise deliberately runs it from the controlled config.
mkdir -p \
  "$TMP_ROOT/fake-bin" \
  "$TMP_ROOT/hostile-project" \
  "$TMP_ROOT/mise-config"
MISE_CONFIG_REAL="$(cd "$TMP_ROOT/mise-config" && pwd -P)"
printf '%s\n' '[tools]' 'node = "unexpected-project-version"' \
  >"$TMP_ROOT/hostile-project/mise.toml"
{
  printf '#!%s\n' "$REAL_BASH"
  printf '%s\n' \
    '[[ "$1" == "-C" ]] || exit 80' \
    'working_dir="$2"' \
    'shift 2' \
    '[[ "$1" == "exec" && "$2" == "--" ]] || exit 81' \
    'shift 2' \
    'cd "$working_dir"' \
    'exec "$@"'
} >"$TMP_ROOT/fake-bin/mise"
{
  printf '#!%s\n' "$REAL_BASH"
  printf '%s\n' 'printf "%s|%s\n" "$PWD" "$1" >"$TEST_MISE_EXEC_LOG"'
} >"$TMP_ROOT/absolute-adapter"
chmod +x "$TMP_ROOT/fake-bin/mise" "$TMP_ROOT/absolute-adapter"
(
  cd "$TMP_ROOT/hostile-project"
  PATH="$TMP_ROOT/fake-bin:/usr/bin:/bin" \
    TEST_MISE_EXEC_LOG="$TMP_ROOT/mise-exec.log" \
    mise -C "$MISE_CONFIG_REAL" exec -- "$TMP_ROOT/absolute-adapter" desktop
)
expect "controlled mise exec ignores the hostile caller project" \
  grep -Fxq "$MISE_CONFIG_REAL|desktop" "$TMP_ROOT/mise-exec.log"

if grep -Eq 'astral\.sh/uv|uv self update' "$SETUP" "$UPDATE"; then
  echo "FAIL: workstation scripts must not replace the adapter's pinned uv" >&2
  failures=$((failures + 1))
fi

if grep -Eq '^[[:space:]]*(npm|npx)([[:space:]]|$)' \
  "$NVIM_BOOTSTRAP" "$NVIM_ADAPTER" "$SETUP" "$UPDATE"; then
  echo "FAIL: portable Neovim setup must invoke pnpm, never npm or npx" >&2
  failures=$((failures + 1))
fi

# Source the real file through ~/.zshrc and prove that its `:A` expansion follows
# the symlink back to this checkout instead of assuming ~/Developer/dotfiles-hd.
mkdir -p "$TMP_ROOT/home"
ln -s "$ZSHRC" "$TMP_ROOT/home/.zshrc"
expect "linked zshrc resolves this checkout" \
  env \
    HOME="$TMP_ROOT/home" \
    PATH="/usr/bin:/bin" \
    EXPECTED_DOTFILES_DIR="$SOURCE_ROOT" \
    zsh -f -c 'source "$HOME/.zshrc"; [[ "$DOTFILES_DIR" == "$EXPECTED_DOTFILES_DIR" ]]'

if ((failures > 0)); then
  echo "$failures Ubuntu workstation-wiring regression test(s) failed." >&2
  exit 1
fi

echo "Ubuntu workstation-wiring regression tests: ok"
