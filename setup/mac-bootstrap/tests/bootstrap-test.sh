#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAC_BOOTSTRAP_DIR="$(cd "$TEST_DIR/.." && pwd)"
REPO_DIR="$(cd "$MAC_BOOTSTRAP_DIR/../.." && pwd)"
TMP_ROOT="$(mktemp -d)"
TESTS=0

cleanup() {
  if [[ "${KEEP_BOOTSTRAP_TEST_TMP:-0}" == "1" ]]; then
    printf 'kept test directory: %s\n' "$TMP_ROOT" >&2
  else
    rm -rf "$TMP_ROOT"
  fi
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  TESTS=$((TESTS + 1))
  [[ "$actual" == "$expected" ]] || fail "$message (expected '$expected', got '$actual')"
}

assert_file() {
  TESTS=$((TESTS + 1))
  [[ -f "$1" ]] || fail "expected file: $1"
}

assert_no_path() {
  TESTS=$((TESTS + 1))
  [[ ! -e "$1" && ! -L "$1" ]] || fail "expected no path: $1"
}

assert_contains() {
  TESTS=$((TESTS + 1))
  grep -Fq -- "$2" "$1" || fail "expected '$2' in $1"
}

assert_not_contains() {
  TESTS=$((TESTS + 1))
  ! grep -Fq -- "$2" "$1" || fail "did not expect '$2' in $1"
}

snapshot_path() {
  local target="$1"

  if [[ -L "$target" ]]; then
    printf 'L|%s|%s\n' "$target" "$(readlink "$target")"
  elif [[ -f "$target" ]]; then
    printf 'F|%s|%s|%s\n' "$target" "$(stat -f '%Sp' "$target")" "$(shasum -a 256 "$target" | awk '{print $1}')"
  elif [[ -d "$target" ]]; then
    printf 'D|%s|%s\n' "$target" "$(stat -f '%Sp' "$target")"
    find "$target" -mindepth 1 -maxdepth 1 -print | LC_ALL=C sort | while IFS= read -r child; do
      snapshot_path "$child"
    done
  else
    printf 'M|%s\n' "$target"
  fi
}

snapshot_home() {
  local home_dir="$1"
  local output="$2"

  snapshot_path "$home_dir" > "$output"
}

snapshot_managed_paths() {
  local profile="$1"
  local home_dir="$2"
  local output="$3"
  local spec

  load_profile "$profile" "$REPO_DIR" "$home_dir"
  : > "$output"
  for spec in "${LINK_SPECS[@]}"; do
    snapshot_path "${spec#*|}" >> "$output"
  done
  snapshot_path "$home_dir/.zprofile" >> "$output"
}

snapshot_protected_state() {
  local home_dir="$1"
  local output="$2"
  local relative

  : > "$output"
  for relative in \
    '.ssh/sentinel' \
    '.gitconfig' \
    '.aws/credentials' \
    '.docker/config.json' \
    '.config/1Password/sentinel' \
    '.config/cagent/sentinel' \
    '.config/gh/hosts.yml' \
    '.config/op/sentinel' \
    '.config/herdr/session' \
    '.config/hunk/state.json' \
    '.config/zed/prompts/sentinel' \
    '.config/tmux/plugins/sentinel'; do
    snapshot_path "$home_dir/$relative" >> "$output"
  done
}

# shellcheck source=../lib.sh
source "$MAC_BOOTSTRAP_DIR/lib.sh"

test_link_helper() {
  local root="$TMP_ROOT/link-helper"
  local source_file="$root/source"
  local destination="$root/live/config"
  local wrong_target="$root/missing-target"
  local source_tree="$root/source-tree"
  local linked_parent="$root/linked-zed"

  mkdir -p "$root/live"
  printf 'source\n' > "$source_file"

  backup_and_link "$source_file" "$destination" 20260715-120000 0 >/dev/null
  assert_eq "$source_file" "$(readlink "$destination")" "missing destination is linked"

  backup_and_link "$source_file" "$destination" 20260715-120000 0 >/dev/null
  assert_no_path "$destination.backup-20260715-120000"

  rm "$destination"
  printf 'sentinel\n' > "$destination"
  backup_and_link "$source_file" "$destination" 20260715-120000 0 >/dev/null
  assert_file "$destination.backup-20260715-120000"
  assert_contains "$destination.backup-20260715-120000" sentinel

  rm "$destination"
  ln -s "$wrong_target" "$destination"
  backup_and_link "$source_file" "$destination" 20260715-120000 0 >/dev/null
  assert_eq "$wrong_target" "$(readlink "$destination.backup-20260715-120000.1")" "broken link is backed up"

  rm "$destination"
  printf 'dry-run\n' > "$destination"
  backup_and_link "$source_file" "$destination" 20260715-130000 1 >/dev/null
  assert_contains "$destination" dry-run
  assert_no_path "$destination.backup-20260715-130000"

  mkdir -p "$source_tree/zed"
  printf 'tracked-settings\n' > "$source_tree/zed/settings.json"
  ln -s "$source_tree/zed" "$linked_parent"
  if backup_and_link \
    "$source_tree/zed/settings.json" \
    "$linked_parent/settings.json" \
    20260715-140000 0 >/dev/null 2>&1; then
    fail "destination reached through a whole-Zed parent link should fail"
  fi
  TESTS=$((TESTS + 1))
  assert_eq "$source_tree/zed" "$(readlink "$linked_parent")" "whole-Zed parent link is preserved"
  assert_eq 'tracked-settings' "$(cat "$source_tree/zed/settings.json")" "tracked Zed source is unchanged"
  assert_no_path "$linked_parent/settings.json.backup-20260715-140000"

  ln -s "$source_file" "$root/dangling-check"
  link_matches "$source_file" "$root/dangling-check" \
    || fail "live source link should match"
  TESTS=$((TESTS + 1))
  rm "$source_file"
  if link_matches "$source_file" "$root/dangling-check"; then
    fail "dangling source link should not match"
  fi
  TESTS=$((TESTS + 1))
}

test_zprofile_helper() {
  local root="$TMP_ROOT/zprofile-helper"
  local profile="$root/.zprofile"
  local fragment="$root/mise shims.zsh"
  local legacy_root="$root/legacy-migration"
  local legacy_profile="$legacy_root/.zprofile"
  local backup_count

  mkdir -p "$root"
  printf 'export KEEP_ME=yes\n' > "$profile"
  printf 'export SHIMS=yes\n' > "$fragment"

  write_zprofile_block "$profile" "$fragment" 20260715-120000 0 >/dev/null
  assert_contains "$profile" 'export KEEP_ME=yes'
  assert_contains "$profile" '# BEGIN dotfiles-hd mac-bootstrap mise shims'
  assert_file "$profile.backup-20260715-120000"
  assert_eq "$(stat -f '%Lp' "$profile.backup-20260715-120000")" \
    "$(stat -f '%Lp' "$profile")" "managed zprofile preserves its file mode"

  write_zprofile_block "$profile" "$fragment" 20260715-120000 0 >/dev/null
  backup_count="$(find "$root" -maxdepth 1 -name '.zprofile.backup-*' | wc -l | tr -d ' ')"
  assert_eq 1 "$backup_count" "idempotent managed block creates no extra backup"
  assert_eq 1 "$(grep -Fxc '# BEGIN dotfiles-hd mac-bootstrap mise shims' "$profile")" "managed block appears once"

  mkdir -p "$legacy_root"
  printf '%s\n%s\n%s\n%s\n%s\n' \
    'export LEGACY_KEEP=yes' \
    '# BEGIN dotfiles-hd personal-mac mise shims' \
    'source /tmp/dotfiles/setup/personal-mac/mise-shims.zsh' \
    '# END dotfiles-hd personal-mac mise shims' \
    'export LEGACY_AFTER=yes' > "$legacy_profile"
  write_zprofile_block "$legacy_profile" "$fragment" 20260715-120001 0 >/dev/null
  assert_eq 1 "$(grep -Fxc '# BEGIN dotfiles-hd mac-bootstrap mise shims' "$legacy_profile")" \
    "legacy marker is migrated once"
  assert_not_contains "$legacy_profile" 'dotfiles-hd personal-mac mise shims'
  assert_not_contains "$legacy_profile" 'setup/personal-mac/mise-shims.zsh'
  assert_contains "$legacy_profile" 'export LEGACY_KEEP=yes'
  assert_contains "$legacy_profile" 'export LEGACY_AFTER=yes'
  assert_file "$legacy_profile.backup-20260715-120001"
  assert_contains "$legacy_profile.backup-20260715-120001" \
    '# BEGIN dotfiles-hd personal-mac mise shims'
  zprofile_block_matches "$legacy_profile" "$fragment" \
    || fail "migrated legacy block should match the current fragment"
  TESTS=$((TESTS + 1))

  write_zprofile_block "$legacy_profile" "$fragment" 20260715-120002 0 >/dev/null
  backup_count="$(find "$legacy_root" -maxdepth 1 -name '.zprofile.backup-*' | wc -l | tr -d ' ')"
  assert_eq 1 "$backup_count" "second apply after legacy migration creates no backup"

  printf '%s\n' '# BEGIN dotfiles-hd personal-mac mise shims' \
    > "$root/malformed-legacy"
  if write_zprofile_block \
    "$root/malformed-legacy" "$fragment" 20260715-120003 0 >/dev/null 2>&1; then
    fail "malformed legacy managed block should fail"
  fi
  TESTS=$((TESTS + 1))
  assert_eq '# BEGIN dotfiles-hd personal-mac mise shims' \
    "$(cat "$root/malformed-legacy")" "malformed legacy block preserves profile bytes"

  cp "$legacy_profile" "$root/dual-managed"
  printf '%s\n%s\n%s\n' \
    '# BEGIN dotfiles-hd personal-mac mise shims' \
    'source /tmp/dotfiles/setup/personal-mac/mise-shims.zsh' \
    '# END dotfiles-hd personal-mac mise shims' >> "$root/dual-managed"
  cp "$root/dual-managed" "$root/dual-managed.before"
  if write_zprofile_block \
    "$root/dual-managed" "$fragment" 20260715-120004 0 >/dev/null 2>&1; then
    fail "current and legacy managed blocks together should fail"
  fi
  TESTS=$((TESTS + 1))
  assert_eq "$(cat "$root/dual-managed.before")" "$(cat "$root/dual-managed")" \
    "multiple managed blocks preserve profile bytes"
  if zprofile_block_matches "$root/dual-managed" "$fragment"; then
    fail "doctor helper should reject a stale legacy block beside the current block"
  fi
  TESTS=$((TESTS + 1))

  printf '# BEGIN dotfiles-hd mac-bootstrap mise shims\n' > "$root/malformed"
  if write_zprofile_block "$root/malformed" "$fragment" 20260715-120000 0 >/dev/null 2>&1; then
    fail "malformed managed block should fail"
  fi
  TESTS=$((TESTS + 1))

  printf '%s\nkeep-before\n%s\nkeep-after\n' \
    '# END dotfiles-hd mac-bootstrap mise shims' \
    '# BEGIN dotfiles-hd mac-bootstrap mise shims' > "$root/reversed"
  cp "$root/reversed" "$root/reversed.before"
  if write_zprofile_block "$root/reversed" "$fragment" 20260715-120000 0 >/dev/null 2>&1; then
    fail "reversed managed block should fail"
  fi
  TESTS=$((TESTS + 1))
  assert_eq "$(cat "$root/reversed.before")" "$(cat "$root/reversed")" "reversed markers preserve profile bytes"

  printf '%s\n%s\n%s\n%s\n' \
    '# BEGIN dotfiles-hd mac-bootstrap mise shims' \
    '# BEGIN dotfiles-hd mac-bootstrap mise shims' \
    '# END dotfiles-hd mac-bootstrap mise shims' \
    '# END dotfiles-hd mac-bootstrap mise shims' > "$root/nested"
  if write_zprofile_block "$root/nested" "$fragment" 20260715-120000 0 >/dev/null 2>&1; then
    fail "nested managed blocks should fail"
  fi
  TESTS=$((TESTS + 1))

  printf 'linked-profile\n' > "$root/profile-target"
  ln -s "$root/profile-target" "$root/symlinked-profile"
  if write_zprofile_block "$root/symlinked-profile" "$fragment" 20260715-120000 0 >/dev/null 2>&1; then
    fail "symlinked profile should require manual review"
  fi
  TESTS=$((TESTS + 1))
  assert_eq "$root/profile-target" "$(readlink "$root/symlinked-profile")" "symlinked profile topology is preserved"
  assert_eq 'linked-profile' "$(cat "$root/profile-target")" "symlink target is unchanged"
}

make_fake_command() {
  local fake_bin="$1"
  local name="$2"
  local output="${3:-}"

  cat > "$fake_bin/$name" <<EOF
#!/usr/bin/env bash
printf '%s %s\\n' '$name' "\$*" >> "\${COMMAND_LOG:?}"
printf '%s\\n' '$output'
EOF
  chmod +x "$fake_bin/$name"
}

make_fake_toolchain() {
  local fake_bin="$1"
  local command_name

  mkdir -p "$fake_bin"

  cat > "$fake_bin/brew" <<'EOF'
#!/usr/bin/env bash
printf 'brew %s\n' "$*" >> "${COMMAND_LOG:?}"
if [[ "${FAIL_BREW_INSTALL:-0}" == "1" && "$*" == *'bundle install'* ]]; then
  exit 23
fi
exit 0
EOF
  chmod +x "$fake_bin/brew"

  cat > "$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
command_line="$*"
if [[ "$command_line" == *'/nvim/lazy/'* ]]; then
  printf 'git %s\n' "$command_line" >> "${COMMAND_LOG:?}"
  if [[ "${1:-}" == "clone" ]]; then
    target="${!#}"
    mkdir -p "$target/.git"
    exit 0
  fi
  if [[ "$command_line" == *'rev-parse HEAD'* ]]; then
    if [[ "${FAKE_NVIM_MISSING_PLUGIN:-0}" == "1" ]]; then
      exit 31
    fi
    plugin_dir=""
    args=("$@")
    for ((index = 0; index < ${#args[@]}; index++)); do
      if [[ "${args[$index]}" == "-C" ]]; then
        plugin_dir="${args[$((index + 1))]}"
        break
      fi
    done
    plugin_name="$(basename "$plugin_dir")"
    if [[ "${FAKE_NVIM_COMMIT_MISMATCH:-0}" == "1" ]]; then
      printf '%040d\n' 0
    else
      lockfile="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy-lock.json"
      /usr/bin/ruby -rjson -e \
        'puts JSON.parse(File.read(ARGV.fetch(0))).fetch(ARGV.fetch(1)).fetch("commit")' \
        "$lockfile" "$plugin_name"
    fi
  fi
  exit 0
fi
exec /usr/bin/git "$@"
EOF
  chmod +x "$fake_bin/git"

  cat > "$fake_bin/mise" <<'EOF'
#!/usr/bin/env bash
printf 'mise %s\n' "$*" >> "${COMMAND_LOG:?}"
if [[ "${1:-}" == "--no-config" ]]; then
  shift
fi
if [[ "${1:-}" == "activate" ]]; then
  fake_bin="$(cd "$(dirname "$0")" && pwd)"
  printf 'export PATH=%q:$PATH\n' "$fake_bin"
  exit 0
fi
if [[ "${1:-}" == "where" ]]; then
  if [[ "${MISE_WHERE_MISSING:-}" == "1" \
    || "${MISE_WHERE_MISSING:-}" == "${2:-}" \
    || "${MISE_WHERE_MISSING:-}" == "${2%%@*}" ]]; then
    exit 1
  fi
  printf '%s\n' "/fake/mise/installs/${2:-unknown}"
  exit 0
fi
if [[ "${FAIL_MISE_INSTALL:-0}" == "1" && "${1:-}" == "install" ]]; then
  exit 24
fi
if [[ "${1:-}" == "install" && "$*" == *'--dry-run-code'* ]]; then
  exit "${MISE_DRY_RUN_CODE_STATUS:-0}"
fi
if [[ "${1:-}" == "install" ]]; then
  fake_bin="$(cd "$(dirname "$0")" && pwd)"
  shim_dir="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
  mkdir -p "$shim_dir"
  for tool in mise node npm npx pnpm go python bun; do
    ln -sf "$fake_bin/$tool" "$shim_dir/$tool"
  done
  exit 0
fi
if [[ "${1:-}" == "exec" ]]; then
  if [[ "${FAIL_ON_MISE_AUTO_INSTALL:-0}" == "1" && "${MISE_AUTO_INSTALL:-}" != "0" ]]; then
    exit 25
  fi
  [[ "${FAIL_MISE_EXEC:-0}" != "1" ]] || exit 26
  shift
  while [[ $# -gt 0 && "${1:-}" != "--" ]]; do
    shift
  done
  [[ "${1:-}" == "--" ]] && shift
  export MISE_TEST_EXEC=1
  exec "$@"
fi
exit 0
EOF
  chmod +x "$fake_bin/mise"

  cat > "$fake_bin/uv" <<'EOF'
#!/usr/bin/env bash
printf 'uv %s\n' "$*" >> "${COMMAND_LOG:?}"
uv_bin="${XDG_BIN_HOME:-$HOME/.local/bin}"
mkdir -p "$uv_bin"
case "$*" in
  *'mdformat==1.0.0'*)
    cat > "$uv_bin/mdformat" <<'SCRIPT'
#!/usr/bin/env bash
printf 'mdformat 1.0.0 (mdformat_gfm_alerts 2.0.0, mdformat-gfm %s, mdformat_footnote 0.1.3, mdformat_wikilink 0.3.0, mdformat_frontmatter 2.1.2)\n' "${FAKE_MDFORMAT_GFM_VERSION:-1.0.0}"
SCRIPT
    chmod +x "$uv_bin/mdformat"
    ;;
  *'ruff==0.15.21'*)
    cat > "$uv_bin/ruff" <<'SCRIPT'
#!/usr/bin/env bash
printf 'ruff 0.15.21\n'
SCRIPT
    chmod +x "$uv_bin/ruff"
    ;;
esac
exit 0
EOF
  chmod +x "$fake_bin/uv"

  make_fake_command "$fake_bin" npm 11.0.0

  cat > "$fake_bin/pnpm" <<'EOF'
#!/usr/bin/env bash
printf 'pnpm %s\n' "$*" >> "${COMMAND_LOG:?}"
if [[ "${1:-}" == "add" ]]; then
  [[ "${MISE_TEST_EXEC:-}" == "1" ]] || exit 40
  [[ "${PNPM_HOME:-}" == "$HOME/.local/graphql-lsp" ]] || exit 41
  case ":$PATH:" in
    *":$PNPM_HOME/bin:"*) ;;
    *) exit 42 ;;
  esac
  [[ "$*" == "add --global --global-dir $HOME/.local/graphql-lsp/global graphql-language-service-cli@3.5.0" ]] \
    || exit 43
  [[ "${FAIL_PNPM_ADD:-0}" != "1" ]] || exit 44
  mkdir -p "$HOME/.local/graphql-lsp/bin"
  printf '#!/usr/bin/env bash\n[[ "${MISE_TEST_EXEC:-}" == "1" ]] || exit 127\nprintf "3.5.0\\n"\n' > "$HOME/.local/graphql-lsp/bin/graphql-lsp"
  chmod +x "$HOME/.local/graphql-lsp/bin/graphql-lsp"
else
  printf '11.2.2\n'
fi
EOF
  chmod +x "$fake_bin/pnpm"

  cat > "$fake_bin/node" <<'EOF'
#!/usr/bin/env bash
printf 'node %s\n' "$*" >> "${COMMAND_LOG:?}"
if [[ "${1:-}" == "-e" ]]; then
  exit 1
fi
if [[ "${MISE_TEST_EXEC:-}" == "1" ]]; then
  printf 'v24.18.0\n'
else
  printf '%s\n' "${FAKE_ACTIVE_NODE_VERSION:-v24.18.0}"
fi
EOF
  chmod +x "$fake_bin/node"
  make_fake_command "$fake_bin" npx 11.0.0
  cat > "$fake_bin/go" <<'EOF'
#!/usr/bin/env bash
printf 'go %s\n' "$*" >> "${COMMAND_LOG:?}"
[[ "${1:-}" == "version" ]] || exit 2
printf 'go version go1.26.3 darwin/arm64\n'
EOF
  chmod +x "$fake_bin/go"
  make_fake_command "$fake_bin" python 'Python 3.14.5'
  make_fake_command "$fake_bin" bun 1.3.14

  cat > "$fake_bin/nvim" <<'EOF'
#!/usr/bin/env bash
printf 'nvim %s\n' "$*" >> "${COMMAND_LOG:?}"
if [[ "${1:-}" == "--version" ]]; then
  printf 'NVIM v%s\n' "${FAKE_NVIM_VERSION:-0.12.4}"
  exit 0
fi
if [[ " $* " == *' -u NONE '* ]]; then
  if [[ -n "${DOTFILES_LAZY_LOCK:-}" ]]; then
    [[ "${FAKE_NVIM_MISSING_PLUGIN:-0}" != "1" ]] || exit 31
    [[ "${FAKE_NVIM_COMMIT_MISMATCH:-0}" != "1" ]] || exit 33
    grep -Fq 'invalid json' "$DOTFILES_LAZY_LOCK" && exit 34
  elif [[ -n "${DOTFILES_NVIM_PARSERS:-}" ]]; then
    site_root="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site"
    for parser in \
      bash ecma go gomod gosum gowork graphql javascript json jsx lua markdown \
      markdown_inline python query toml tsx typescript vim vimdoc yaml; do
      [[ -s "$site_root/parser-info/$parser.lua" ]] || exit 35
      [[ -d "$site_root/queries/$parser" ]] || exit 35
    done
    for parser in \
      bash go gomod gosum gowork graphql javascript json lua markdown \
      markdown_inline python query toml tsx typescript vim vimdoc yaml; do
      [[ -s "$site_root/parser/$parser.so" ]] || exit 35
    done
  fi
  exit 0
fi
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua" ]] \
  && grep -Fq 'intentional-startup-error' "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua"; then
  [[ "$*" != *'vim.v.errmsg'* ]] || exit 32
fi
[[ -z "${NVIM_NORMAL_START_MARKER:-}" ]] || : > "$NVIM_NORMAL_START_MARKER"
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim/.git"
if [[ "$*" == *"Lazy! restore"* ]]; then
  [[ "${DOTFILES_NVIM_RESTORE_ALL:-}" == "1" ]] || exit 36
  lockfile="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy-lock.json"
  while IFS= read -r plugin; do
    mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/$plugin/.git"
  done < <(/usr/bin/ruby -rjson -e \
    'JSON.parse(File.read(ARGV.fetch(0))).each_key { |name| puts name }' "$lockfile")
fi
if [[ "$*" == *"nvim-treesitter"* ]]; then
  site_root="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site"
  mkdir -p "$site_root/parser" "$site_root/parser-info" "$site_root/queries"
  for parser in \
    bash ecma go gomod gosum gowork graphql javascript json jsx lua markdown \
    markdown_inline python query toml tsx typescript vim vimdoc yaml; do
    mkdir -p "$site_root/queries/$parser"
    printf 'parser-info\n' > "$site_root/parser-info/$parser.lua"
    printf 'query\n' > "$site_root/queries/$parser/highlights.scm"
  done
  for parser in \
    bash go gomod gosum gowork graphql javascript json lua markdown \
    markdown_inline python query toml tsx typescript vim vimdoc yaml; do
    printf 'parser-binary\n' > "$site_root/parser/$parser.so"
  done
fi
exit 0
EOF
  chmod +x "$fake_bin/nvim"

  for command_name in \
    rg fd fzf lazygit tree-sitter lua-language-server stylua vtsls \
    vscode-eslint-language-server bash-language-server gopls \
    zoxide starship bat lsd btop fastfetch herdr hunk; do
    make_fake_command "$fake_bin" "$command_name" ''
  done

  for command_name in launchctl pkill killall sudo; do
    cat > "$fake_bin/$command_name" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename "$0")" "$*" >> "${COMMAND_LOG:?}"
exit 97
EOF
    chmod +x "$fake_bin/$command_name"
  done
}

test_neovim_lock_guard() {
  local root="$TMP_ROOT/neovim-lock-guard"
  local fake_bin="$root/bin"
  local lockfile="$root/lazy-lock.json"
  local original="$root/original.json"
  local log="$root/commands.log"
  local pin_marker="$root/lazy-pinned"

  mkdir -p "$fake_bin"
  : > "$log"
  printf '{"lazy.nvim":{"commit":"1111111111111111111111111111111111111111"}}\n' > "$lockfile"
  cp "$lockfile" "$original"
  cat > "$fake_bin/nvim" <<'EOF'
#!/usr/bin/env bash
printf 'nvim %s\n' "$*" >> "${COMMAND_LOG:?}"
[[ -f "${LAZY_PIN_MARKER:?}" ]] || exit 86
printf '{"lazy.nvim":{"commit":"drifted"}}\n' > "${TEST_LAZY_LOCK:?}"
exit "${TEST_NVIM_STATUS:-0}"
EOF
  chmod +x "$fake_bin/nvim"
  cat > "$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >> "${COMMAND_LOG:?}"
if [[ "${1:-}" == "clone" ]]; then
  target="${!#}"
  mkdir -p "$target/.git"
  [[ "${FAIL_LAZY_CLONE:-0}" != "1" ]] || exit 87
fi
if [[ "$*" == *'checkout --quiet --detach'* ]]; then
  : > "${LAZY_PIN_MARKER:?}"
fi
exit 0
EOF
  chmod +x "$fake_bin/git"

  PATH="$fake_bin:$PATH" XDG_DATA_HOME="$root/data" TEST_LAZY_LOCK="$lockfile" \
    COMMAND_LOG="$log" LAZY_PIN_MARKER="$pin_marker" \
    restore_neovim_plugins "$lockfile" >/dev/null
  assert_contains "$log" \
    "git clone --quiet --filter=blob:none --no-checkout $LAZY_NVIM_REPOSITORY $root/data/nvim/lazy/lazy.nvim"
  assert_contains "$log" \
    'git -C '"$root/data/nvim/lazy/lazy.nvim"' checkout --quiet --detach 1111111111111111111111111111111111111111'
  assert_contains "$log" 'nvim --headless +Lazy! restore +qa'
  assert_contains "$REPO_DIR/config/nvim/lua/plugins/obsidian.lua" \
    'vim.env.DOTFILES_NVIM_RESTORE_ALL == "1"'
  assert_eq "$(cat "$original")" "$(cat "$lockfile")" "Neovim restore preserves the lockfile"

  if PATH="$fake_bin:$PATH" XDG_DATA_HOME="$root/failed-data" \
    TEST_LAZY_LOCK="$lockfile" FAIL_LAZY_CLONE=1 \
    COMMAND_LOG="$log" LAZY_PIN_MARKER="$root/failed-pin" \
    restore_neovim_plugins "$lockfile" >/dev/null 2>&1; then
    fail "failed lazy.nvim clone should stop Neovim restore"
  fi
  TESTS=$((TESTS + 1))
  assert_no_path "$root/failed-data/nvim/lazy/lazy.nvim"

  if PATH="$fake_bin:$PATH" XDG_DATA_HOME="$root/data" \
    TEST_LAZY_LOCK="$lockfile" TEST_NVIM_STATUS=42 \
    COMMAND_LOG="$log" LAZY_PIN_MARKER="$pin_marker" \
    restore_neovim_plugins "$lockfile" >/dev/null 2>&1; then
    fail "Neovim restore failure should propagate"
  fi
  TESTS=$((TESTS + 1))
  assert_eq "$(cat "$original")" "$(cat "$lockfile")" "failed Neovim restore preserves the lockfile"
}

test_neovim_plugin_checkout_integrity() {
  local root="$TMP_ROOT/neovim-plugin-checkout-integrity"
  local data_dir="$root/data"
  local plugin_dir="$data_dir/nvim/lazy/example.nvim"
  local lockfile="$root/lazy-lock.json"
  local commit

  mkdir -p "$plugin_dir"
  /usr/bin/git -C "$plugin_dir" init --quiet
  printf 'tracked\n' > "$plugin_dir/tracked.txt"
  /usr/bin/git -C "$plugin_dir" add tracked.txt
  /usr/bin/git -C "$plugin_dir" \
    -c user.name='Bootstrap Test' \
    -c user.email='bootstrap-test@example.invalid' \
    -c commit.gpgsign=false \
    commit --quiet -m initial
  commit="$(/usr/bin/git -C "$plugin_dir" rev-parse HEAD)"
  printf '{"example.nvim":{"commit":"%s"}}\n' "$commit" > "$lockfile"

  PATH=/usr/bin:/bin XDG_DATA_HOME="$data_dir" \
    verify_neovim_plugins_restored "$lockfile" \
    || fail "clean locked Neovim plugin should pass verification"
  TESTS=$((TESTS + 1))

  mkdir -p "$plugin_dir/doc"
  printf 'generated tags\n' > "$plugin_dir/doc/tags"
  PATH=/usr/bin:/bin XDG_DATA_HOME="$data_dir" \
    verify_neovim_plugins_restored "$lockfile" \
    || fail "generated untracked doc/tags should be allowed"
  TESTS=$((TESTS + 1))

  printf 'unexpected\n' > "$plugin_dir/unexpected.txt"
  if PATH=/usr/bin:/bin XDG_DATA_HOME="$data_dir" \
    verify_neovim_plugins_restored "$lockfile" >/dev/null 2>&1; then
    fail "unexpected untracked Neovim plugin files should fail verification"
  fi
  TESTS=$((TESTS + 1))
  rm "$plugin_dir/unexpected.txt"

  printf 'modified\n' >> "$plugin_dir/tracked.txt"
  if PATH=/usr/bin:/bin XDG_DATA_HOME="$data_dir" \
    verify_neovim_plugins_restored "$lockfile" >/dev/null 2>&1; then
    fail "modified tracked Neovim plugin files should fail verification"
  fi
  TESTS=$((TESTS + 1))
  printf 'tracked\n' > "$plugin_dir/tracked.txt"

  printf 'staged\n' >> "$plugin_dir/tracked.txt"
  /usr/bin/git -C "$plugin_dir" add tracked.txt
  if PATH=/usr/bin:/bin XDG_DATA_HOME="$data_dir" \
    verify_neovim_plugins_restored "$lockfile" >/dev/null 2>&1; then
    fail "staged Neovim plugin files should fail verification"
  fi
  TESTS=$((TESTS + 1))
}

test_neovim_parser_manifest() {
  local root="$TMP_ROOT/neovim-parser-manifest"
  local drifted="$root/editor.lua"

  mkdir -p "$root"
  validate_neovim_parser_manifest "$REPO_DIR/config/nvim/lua/plugins/editor.lua"
  TESTS=$((TESTS + 1))

  sed '/"yaml",/d' "$REPO_DIR/config/nvim/lua/plugins/editor.lua" > "$drifted"
  if validate_neovim_parser_manifest "$drifted" >/dev/null 2>&1; then
    fail "Neovim parser manifest drift should fail preflight"
  fi
  TESTS=$((TESTS + 1))
}

seed_protected_state() {
  local home_dir="$1"
  mkdir -p \
    "$home_dir/.ssh" \
    "$home_dir/.aws" \
    "$home_dir/.docker" \
    "$home_dir/.config/1Password" \
    "$home_dir/.config/cagent" \
    "$home_dir/.config/gh" \
    "$home_dir/.config/op" \
    "$home_dir/.config/herdr" \
    "$home_dir/.config/hunk" \
    "$home_dir/.config/zed/prompts" \
    "$home_dir/.config/tmux/plugins"
  printf 'ssh\n' > "$home_dir/.ssh/sentinel"
  printf '[user]\n  name = sentinel\n' > "$home_dir/.gitconfig"
  printf '[default]\naws_access_key_id = sentinel\n' > "$home_dir/.aws/credentials"
  printf '{"auths":{"sentinel":{}}}\n' > "$home_dir/.docker/config.json"
  printf 'one-password\n' > "$home_dir/.config/1Password/sentinel"
  printf 'cagent\n' > "$home_dir/.config/cagent/sentinel"
  printf 'github\n' > "$home_dir/.config/gh/hosts.yml"
  printf 'op\n' > "$home_dir/.config/op/sentinel"
  printf 'session\n' > "$home_dir/.config/herdr/session"
  printf '{"version":1}\n' > "$home_dir/.config/hunk/state.json"
  printf 'prompt\n' > "$home_dir/.config/zed/prompts/sentinel"
  printf 'plugin\n' > "$home_dir/.config/tmux/plugins/sentinel"
}

test_profile_names_and_paths() {
  local root="$TMP_ROOT/profile-names-and-paths"
  local home_dir="$root/home"
  local spec
  local zsh_spec=""
  local helper_path

  mkdir -p "$home_dir"

  assert_eq mac-pro "$(canonical_profile mac-pro)" "mac-pro remains canonical"
  assert_eq mac-mini "$(canonical_profile mac-mini)" "mac-mini remains canonical"
  if canonical_profile mac-vm >/dev/null 2>&1; then
    fail "removed mac-vm profile should be rejected"
  fi
  TESTS=$((TESTS + 1))

  assert_no_path "$REPO_DIR/setup/mac-vm"
  assert_no_path "$REPO_DIR/setup/mac-resilience"
  assert_no_path "$REPO_DIR/setup/mac-pro/setup-vm.sh"
  assert_no_path "$REPO_DIR/setup/mac-pro/zsh-config"

  [[ -x "$REPO_DIR/setup/mac-pro/setup.sh" ]] \
    || fail "canonical Mac Pro wrapper should be executable"
  TESTS=$((TESTS + 1))

  load_profile mac-pro "$REPO_DIR" "$home_dir"
  assert_eq "$REPO_DIR/setup/mac-pro/Brewfile" "$PROFILE_BREWFILE" "Mac Pro profile uses its Brewfile"
  for spec in "${LINK_SPECS[@]}"; do
    [[ "${spec#*|}" == "$home_dir/.zshrc" ]] && zsh_spec="$spec"
  done
  assert_eq "$REPO_DIR/setup/mac-pro/.zshrc|$home_dir/.zshrc" "$zsh_spec" "canonical zsh link target"

  while IFS= read -r helper_path; do
    [[ -f "$REPO_DIR/$helper_path" ]] \
      || fail "missing Mac Pro Resilience helper: $helper_path"
    TESTS=$((TESTS + 1))
  done < <(
    grep -Eo 'setup/mac-pro-resilience/[^"]+\.sh' \
      "$REPO_DIR/setup/mac-pro-resilience/.zshrc" | LC_ALL=C sort -u
  )
}

test_full_bootstrap() {
  local root="$TMP_ROOT/full-bootstrap"
  local home_dir="$root/home"
  local fake_bin="$root/bin"
  local log="$root/commands.log"
  local before="$root/before.txt"
  local after="$root/after.txt"
  local backup_count_before
  local backup_count_after
  local managed_before="$root/managed.before.txt"
  local managed_after="$root/managed.after.txt"
  local missing_destinations="$root/managed.missing.txt"
  local protected_before="$root/protected.before.txt"
  local protected_after="$root/protected.after.txt"
  local empty_mise="$root/empty-mise"
  local spec
  local destination

  mkdir -p "$home_dir/Developer"
  ln -s "$REPO_DIR" "$home_dir/Developer/dotfiles-hd"
  make_fake_toolchain "$fake_bin"
  seed_protected_state "$home_dir"
  : > "$log"

  snapshot_home "$home_dir" "$before"
  HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" DOTFILES_STAMP=20260715-140000 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --dry-run >/dev/null
  snapshot_home "$home_dir" "$after"
  assert_eq "$(cat "$before")" "$(cat "$after")" "dry-run writes nothing under HOME"
  assert_eq '' "$(cat "$log")" "dry-run invokes no package manager"

  printf 'old-zshrc\n' > "$home_dir/.zshrc"
  printf 'export KEEP_ME=yes\n' > "$home_dir/.zprofile"
  mkdir -p \
    "$home_dir/.local/graphql-lsp/bin" \
    "$home_dir/.local/graphql-lsp/lib/node_modules/graphql-language-service-cli"
  printf '#!/usr/bin/env bash\nprintf "3.5.0\\n"\n' \
    > "$home_dir/.local/graphql-lsp/bin/graphql-lsp"
  chmod +x "$home_dir/.local/graphql-lsp/bin/graphql-lsp"
  printf '{"version":"3.5.0"}\n' \
    > "$home_dir/.local/graphql-lsp/lib/node_modules/graphql-language-service-cli/package.json"
  mkdir -p "$home_dir/.config/btop"
  printf 'old-btop\n' > "$home_dir/.config/btop/sentinel"
  snapshot_managed_paths mac-pro "$home_dir" "$managed_before"
  snapshot_protected_state "$home_dir" "$protected_before"
  : > "$missing_destinations"
  load_profile mac-pro "$REPO_DIR" "$home_dir"
  for spec in "${LINK_SPECS[@]}"; do
    destination="${spec#*|}"
    if [[ ! -e "$destination" && ! -L "$destination" ]]; then
      printf '%s\n' "$destination" >> "$missing_destinations"
    fi
  done

  HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" DOTFILES_STAMP=20260715-140000 \
    DOTFILES_ALLOW_DIRTY=1 DOTFILES_ALLOW_NONCANONICAL=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --apply >/dev/null

  assert_eq "$REPO_DIR/setup/mac-pro/.zshrc" "$(readlink "$home_dir/.zshrc")" "MacBook zshrc target"
  assert_eq "$REPO_DIR/config/bookokrat" "$(readlink "$home_dir/.config/bookokrat")" "Bookokrat config target"
  assert_eq "$REPO_DIR/config/ghostty/config" "$(readlink "$home_dir/Library/Application Support/com.mitchellh.ghostty/config")" "Ghostty path with spaces"
  assert_eq "$REPO_DIR/config/hunk/config.toml" "$(readlink "$home_dir/.config/hunk/config.toml")" "Hunk config target"
  assert_eq "$REPO_DIR/config/karabiner" "$(readlink "$home_dir/.config/karabiner")" "MacBook profile link"
  assert_file "$home_dir/.zshrc.backup-20260715-140000"
  assert_file "$home_dir/.config/btop.backup-20260715-140000/sentinel"
  assert_contains "$home_dir/.zprofile" 'export KEEP_ME=yes'
  assert_contains "$log" "bundle install --no-upgrade --file $REPO_DIR/setup/mac-bootstrap/Brewfile"
  assert_contains "$log" "bundle install --no-upgrade --file $REPO_DIR/setup/mac-pro/Brewfile"
  assert_contains "$log" "mise exec node@24.18.0 pnpm@11.2.2 -- pnpm add --global --global-dir $home_dir/.local/graphql-lsp/global graphql-language-service-cli@3.5.0"
  assert_contains "$log" "pnpm add --global --global-dir $home_dir/.local/graphql-lsp/global graphql-language-service-cli@3.5.0"
  assert_contains "$home_dir/.local/graphql-lsp/.pnpm-managed-version" \
    'graphql-language-service-cli@3.5.0 via pnpm@11.2.2'
  assert_not_contains "$log" 'npm install'
  assert_not_contains "$log" 'setup/mac-mini/Brewfile'

  snapshot_protected_state "$home_dir" "$protected_after"
  assert_eq "$(cat "$protected_before")" "$(cat "$protected_after")" "protected state is byte-for-byte unchanged"

  backup_count_before="$(find "$home_dir" -name '*.backup-*' | wc -l | tr -d ' ')"
  HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" DOTFILES_STAMP=20260715-150000 \
    DOTFILES_ALLOW_DIRTY=1 DOTFILES_ALLOW_NONCANONICAL=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --apply >/dev/null
  backup_count_after="$(find "$home_dir" -name '*.backup-*' | wc -l | tr -d ' ')"
  assert_eq "$backup_count_before" "$backup_count_after" "second bootstrap creates no backup"
  assert_eq 1 "$(grep -Fxc "pnpm add --global --global-dir $home_dir/.local/graphql-lsp/global graphql-language-service-cli@3.5.0" "$log")" \
    "second bootstrap does not reinstall GraphQL LSP"

  rm "$home_dir/.zshrc"
  mv "$home_dir/.zshrc.backup-20260715-140000" "$home_dir/.zshrc"
  rm "$home_dir/.config/btop"
  mv "$home_dir/.config/btop.backup-20260715-140000" "$home_dir/.config/btop"
  mv "$home_dir/.zprofile.backup-20260715-140000" "$home_dir/.zprofile"
  while IFS= read -r destination; do
    if [[ -L "$destination" ]]; then
      rm "$destination"
    elif [[ -e "$destination" ]]; then
      fail "rollback found unexpected non-link at $destination"
    fi
  done < "$missing_destinations"
  assert_contains "$home_dir/.zshrc" old-zshrc
  assert_contains "$home_dir/.config/btop/sentinel" old-btop
  assert_eq 'export KEEP_ME=yes' "$(cat "$home_dir/.zprofile")" "rollback restores zprofile byte-for-byte"
  snapshot_managed_paths mac-pro "$home_dir" "$managed_after"
  assert_eq "$(cat "$managed_before")" "$(cat "$managed_after")" "rollback restores the complete managed-path inventory"

  HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" DOTFILES_STAMP=20260715-160000 \
    DOTFILES_ALLOW_DIRTY=1 DOTFILES_ALLOW_NONCANONICAL=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --apply >/dev/null
  assert_eq "$REPO_DIR/setup/mac-pro/.zshrc" "$(readlink "$home_dir/.zshrc")" "bootstrap works after rollback"

  assert_not_contains "$log" 'brew upgrade'
  assert_not_contains "$log" 'brew cleanup'
  assert_not_contains "$log" 'autoremove'
  assert_not_contains "$log" 'brew uninstall'
  assert_not_contains "$log" 'ssh-keygen'

  HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" FAIL_ON_MISE_AUTO_INSTALL=1 \
    "$MAC_BOOTSTRAP_DIR/doctor.sh" --profile mac-pro >/dev/null
  TESTS=$((TESTS + 1))

  mv "$home_dir/.local/graphql-lsp/.pnpm-managed-version" \
    "$root/graphql-marker"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" \
    "$MAC_BOOTSTRAP_DIR/doctor.sh" --profile mac-pro >/dev/null 2>&1; then
    fail "doctor should reject an npm-layout GraphQL LSP without the pnpm marker"
  fi
  TESTS=$((TESTS + 1))
  mv "$root/graphql-marker" \
    "$home_dir/.local/graphql-lsp/.pnpm-managed-version"

  cp "$home_dir/.zprofile" "$root/correct-zprofile"
  printf '%s\n' \
    '# BEGIN dotfiles-hd mac-bootstrap mise shims' \
    'source /tmp/not-the-reviewed-fragment' \
    '# END dotfiles-hd mac-bootstrap mise shims' > "$home_dir/.zprofile"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" \
    "$MAC_BOOTSTRAP_DIR/doctor.sh" --profile mac-pro >/dev/null 2>&1; then
    fail "doctor should reject a stale managed zprofile block"
  fi
  TESTS=$((TESTS + 1))
  mv "$root/correct-zprofile" "$home_dir/.zprofile"

  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" MISE_WHERE_MISSING='node@24.18.0' \
    "$MAC_BOOTSTRAP_DIR/doctor.sh" --profile mac-pro >/dev/null 2>&1; then
    fail "doctor should reject a matching PATH fallback when mise Node is missing"
  fi
  TESTS=$((TESTS + 1))

  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" FAKE_ACTIVE_NODE_VERSION=v24.18.10 \
    "$MAC_BOOTSTRAP_DIR/doctor.sh" --profile mac-pro >/dev/null 2>&1; then
    fail "doctor should reject a wrong active shell version"
  fi
  TESTS=$((TESTS + 1))

  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" FAKE_NVIM_VERSION=0.11.9 \
    "$MAC_BOOTSTRAP_DIR/doctor.sh" --profile mac-pro >/dev/null 2>&1; then
    fail "doctor should reject Neovim older than 0.12"
  fi
  TESTS=$((TESTS + 1))

  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" FAKE_MDFORMAT_GFM_VERSION=1.0.01 \
    "$MAC_BOOTSTRAP_DIR/doctor.sh" --profile mac-pro >/dev/null 2>&1; then
    fail "doctor should reject an mdformat plugin prefix-collision version"
  fi
  TESTS=$((TESTS + 1))

  rm -rf "$empty_mise"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" MISE_DATA_DIR="$empty_mise" MISE_WHERE_MISSING=1 \
    "$MAC_BOOTSTRAP_DIR/doctor.sh" --profile mac-pro >/dev/null 2>&1; then
    fail "doctor should fail when pinned runtimes are missing"
  fi
  TESTS=$((TESTS + 1))
  assert_no_path "$empty_mise"

  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" FAKE_NVIM_MISSING_PLUGIN=1 \
    NVIM_NORMAL_START_MARKER="$root/nvim-normal-started" \
    "$MAC_BOOTSTRAP_DIR/doctor.sh" --profile mac-pro >/dev/null 2>&1; then
    fail "doctor should reject a missing locked Neovim plugin"
  fi
  TESTS=$((TESTS + 1))
  assert_no_path "$root/nvim-normal-started"

  rm "$home_dir/.local/share/nvim/site/parser/bash.so"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" \
    "$MAC_BOOTSTRAP_DIR/doctor.sh" --profile mac-pro >/dev/null 2>&1; then
    fail "doctor should reject a missing required Tree-sitter parser"
  fi
  TESTS=$((TESTS + 1))
  : > "$home_dir/.local/share/nvim/site/parser/bash.so"

  rm -rf "$home_dir/.local/share/nvim/site/queries/ecma"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" \
    "$MAC_BOOTSTRAP_DIR/doctor.sh" --profile mac-pro >/dev/null 2>&1; then
    fail "doctor should reject missing query-only Tree-sitter state"
  fi
  TESTS=$((TESTS + 1))
  mkdir -p "$home_dir/.local/share/nvim/site/queries/ecma"
  printf 'query\n' > "$home_dir/.local/share/nvim/site/queries/ecma/highlights.scm"

  printf '{ invalid json\n' > "$root/invalid-lazy-lock.json"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    XDG_DATA_HOME="$home_dir/.local/share" \
    verify_neovim_plugins_restored "$root/invalid-lazy-lock.json" \
      >/dev/null 2>&1; then
    fail "Neovim verifier should reject malformed lock JSON"
  fi
  TESTS=$((TESTS + 1))

  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    XDG_DATA_HOME="$home_dir/.local/share" FAKE_NVIM_COMMIT_MISMATCH=1 \
    verify_neovim_plugins_restored "$REPO_DIR/config/nvim/lazy-lock.json" \
      >/dev/null 2>&1; then
    fail "Neovim verifier should reject a wrong locked commit"
  fi
  TESTS=$((TESTS + 1))

  mkdir -p "$root/broken-config/nvim"
  printf 'error("intentional-startup-error")\n' > "$root/broken-config/nvim/init.lua"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    XDG_DATA_HOME="$home_dir/.local/share" \
    verify_neovim_config_sandboxed "$root/broken-config/nvim"; then
    fail "sandboxed Neovim check should reject an init.lua startup error"
  fi
  TESTS=$((TESTS + 1))
}

test_mac_mini_apply() {
  local root="$TMP_ROOT/mac-mini-apply"
  local home_dir="$root/home"
  local fake_bin="$root/bin"
  local log="$root/commands.log"
  local protected_before="$root/protected.before.txt"
  local protected_after="$root/protected.after.txt"

  mkdir -p "$home_dir/Developer"
  assert_contains "$REPO_DIR/setup/mac-mini/Brewfile" 'brew "node@22"'
  assert_not_contains "$REPO_DIR/setup/mac-mini/Brewfile" 'brew "node@22", link:'
  ln -s "$REPO_DIR" "$home_dir/Developer/dotfiles-hd"
  make_fake_toolchain "$fake_bin"
  seed_protected_state "$home_dir"
  printf 'old-mini-zshrc\n' > "$home_dir/.zshrc"
  printf 'export MINI_KEEP=yes\n' > "$home_dir/.zprofile"
  : > "$log"
  snapshot_protected_state "$home_dir" "$protected_before"

  HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" \
    DOTFILES_DIR="$REPO_DIR" DOTFILES_STAMP=20260715-170000 \
    DOTFILES_ALLOW_DIRTY=1 DOTFILES_ALLOW_NONCANONICAL=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-mini --apply >/dev/null

  assert_eq "$REPO_DIR/setup/mac-mini/.zshrc" "$(readlink "$home_dir/.zshrc")" "Mac mini zshrc target"
  assert_eq "$REPO_DIR/config/bookokrat" "$(readlink "$home_dir/.config/bookokrat")" "Mac mini Bookokrat config target"
  assert_no_path "$home_dir/.config/karabiner"
  assert_no_path "$home_dir/.config/aerospace/aerospace.toml"
  assert_contains "$log" "bundle install --no-upgrade --file $REPO_DIR/setup/mac-mini/Brewfile"
  assert_not_contains "$log" 'setup/mac-pro/Brewfile'
  assert_not_contains "$log" 'launchctl'
  assert_not_contains "$log" 'brew services'
  assert_not_contains "$log" 'pkill'
  assert_not_contains "$log" 'killall'
  assert_not_contains "$log" 'sudo'
  assert_not_contains "$log" 'restart'
  assert_not_contains "$log" 'reload'
  snapshot_protected_state "$home_dir" "$protected_after"
  assert_eq "$(cat "$protected_before")" "$(cat "$protected_after")" "Mac mini apply preserves protected state"
}

test_xdg_bin_home() {
  local root="$TMP_ROOT/xdg-bin-home"
  local home_dir="$root/home"
  local custom_bin="$root/custom-bin"
  local resolved
  local zshrc

  mkdir -p "$custom_bin" "$home_dir/.local/bin" "$home_dir/Developer"
  ln -s "$REPO_DIR" "$home_dir/Developer/dotfiles-hd"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$custom_bin/ruff"
  chmod +x "$custom_bin/ruff"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$home_dir/.local/bin/ruff"
  chmod +x "$home_dir/.local/bin/ruff"
  resolved="$(HOME="$home_dir" XDG_BIN_HOME="$custom_bin" PATH=/usr/bin:/bin \
    zsh -c "source '$MAC_BOOTSTRAP_DIR/mise-shims.zsh'; command -v ruff")"
  assert_eq "$custom_bin/ruff" "$resolved" "XDG_BIN_HOME is present in login shim PATH"

  for zshrc in \
    "$REPO_DIR/setup/mac-pro/.zshrc" \
    "$REPO_DIR/setup/mac-mini/.zshrc"; do
    resolved="$(HOME="$home_dir" XDG_BIN_HOME="$custom_bin" PATH=/usr/bin:/bin \
      zsh -dfc "source '$MAC_BOOTSTRAP_DIR/mise-shims.zsh'; source '$zshrc'; command -v ruff" \
      2>/dev/null | tail -n 1)"
    assert_eq "$custom_bin/ruff" "$resolved" "$(basename "$(dirname "$zshrc")") zshrc keeps XDG_BIN_HOME first"
  done
}

test_profile_and_failure_guards() {
  local root="$TMP_ROOT/guards"
  local home_dir="$root/home"
  local fake_bin="$root/bin"
  local log="$root/commands.log"
  local profile_target="$root/profile-target"
  local drift_config="$root/drift-config.toml"

  mkdir -p "$home_dir/Developer"
  ln -s "$REPO_DIR" "$home_dir/Developer/dotfiles-hd"
  make_fake_toolchain "$fake_bin"
  : > "$log"

  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --dry-run >/dev/null 2>&1; then
    fail "missing profile should fail"
  fi
  TESTS=$((TESTS + 1))

  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile unknown --dry-run >/dev/null 2>&1; then
    fail "unknown profile should fail"
  fi
  TESTS=$((TESTS + 1))

  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-vm --dry-run >/dev/null 2>&1; then
    fail "removed mac-vm profile should fail"
  fi
  TESTS=$((TESTS + 1))
  assert_eq '' "$(cat "$log")" "removed profile stops before package managers"

  HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-mini --check >/dev/null
  assert_contains "$log" "bundle check --no-upgrade --file $REPO_DIR/setup/mac-mini/Brewfile"
  assert_contains "$log" 'mise install --dry-run-code'
  assert_not_contains "$log" 'setup/mac-pro/Brewfile'

  : > "$log"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    MISE_DRY_RUN_CODE_STATUS=42 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --check >/dev/null 2>&1; then
    fail "check should fail when mise runtimes are missing"
  fi
  TESTS=$((TESTS + 1))

  : > "$log"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    DOTFILES_ALLOW_DIRTY=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --apply >/dev/null 2>&1; then
    fail "noncanonical apply should fail"
  fi
  TESTS=$((TESTS + 1))
  assert_eq '' "$(cat "$log")" "noncanonical apply stops before package managers"

  printf 'linked-profile\n' > "$profile_target"
  ln -s "$profile_target" "$home_dir/.zprofile"
  : > "$log"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    DOTFILES_ALLOW_DIRTY=1 DOTFILES_ALLOW_NONCANONICAL=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --apply >/dev/null 2>&1; then
    fail "apply should reject a symlinked zprofile before installers"
  fi
  TESTS=$((TESTS + 1))
  assert_eq '' "$(cat "$log")" "symlinked zprofile stops before package managers"
  assert_eq "$profile_target" "$(readlink "$home_dir/.zprofile")" "rejected zprofile link is preserved"
  assert_no_path "$home_dir/.zshrc"
  rm "$home_dir/.zprofile" "$profile_target"

  printf '# BEGIN dotfiles-hd mac-bootstrap mise shims\n' > "$home_dir/.zprofile"
  : > "$log"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    DOTFILES_ALLOW_DIRTY=1 DOTFILES_ALLOW_NONCANONICAL=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --apply >/dev/null 2>&1; then
    fail "apply should reject a malformed zprofile before installers"
  fi
  TESTS=$((TESTS + 1))
  assert_eq '' "$(cat "$log")" "malformed zprofile stops before package managers"
  assert_eq '# BEGIN dotfiles-hd mac-bootstrap mise shims' "$(cat "$home_dir/.zprofile")" "malformed zprofile is unchanged"
  assert_no_path "$home_dir/.zshrc"
  rm "$home_dir/.zprofile"

  printf 'unreadable-profile\n' > "$home_dir/.zprofile"
  chmod 000 "$home_dir/.zprofile"
  : > "$log"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    DOTFILES_ALLOW_DIRTY=1 DOTFILES_ALLOW_NONCANONICAL=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --apply >/dev/null 2>&1; then
    fail "apply should reject an unreadable zprofile before installers"
  fi
  TESTS=$((TESTS + 1))
  assert_eq '' "$(cat "$log")" "unreadable zprofile stops before package managers"
  assert_no_path "$home_dir/.zshrc"
  chmod 600 "$home_dir/.zprofile"
  assert_eq 'unreadable-profile' "$(cat "$home_dir/.zprofile")" "unreadable zprofile is unchanged"
  rm "$home_dir/.zprofile"

  sed 's/node = "24.18.0"/node = "99.0.0"/' \
    "$REPO_DIR/config/mise/config.toml" > "$drift_config"
  : > "$log"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    DOTFILES_MISE_CONFIG="$drift_config" \
    DOTFILES_ALLOW_DIRTY=1 DOTFILES_ALLOW_NONCANONICAL=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --apply >/dev/null 2>&1; then
    fail "apply should reject unapproved runtime pins before installers"
  fi
  TESTS=$((TESTS + 1))
  assert_eq '' "$(cat "$log")" "unapproved pin stops before package managers"
  assert_no_path "$home_dir/.zshrc"

  : > "$log"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    "$REPO_DIR/setup/mac-pro/setup.sh" --profile mac-mini --dry-run >/dev/null 2>&1; then
    fail "Mac Pro wrapper should reject profile overrides"
  fi
  TESTS=$((TESTS + 1))
  assert_eq '' "$(cat "$log")" "profile override stops in the wrapper"

  : > "$log"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    DOTFILES_ALLOW_DIRTY=1 DOTFILES_ALLOW_NONCANONICAL=1 FAIL_BREW_INSTALL=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --apply >/dev/null 2>&1; then
    fail "Homebrew failure should stop bootstrap"
  fi
  TESTS=$((TESTS + 1))
  assert_no_path "$home_dir/.zshrc"
  assert_not_contains "$log" 'mise install'

  : > "$log"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    DOTFILES_ALLOW_DIRTY=1 DOTFILES_ALLOW_NONCANONICAL=1 FAIL_MISE_INSTALL=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --apply >/dev/null 2>&1; then
    fail "mise failure should stop bootstrap"
  fi
  TESTS=$((TESTS + 1))
  assert_no_path "$home_dir/.zshrc"
  assert_not_contains "$log" 'uv tool install'

  : > "$log"
  if HOME="$home_dir" PATH="$fake_bin:$PATH" COMMAND_LOG="$log" DOTFILES_DIR="$REPO_DIR" \
    DOTFILES_ALLOW_DIRTY=1 DOTFILES_ALLOW_NONCANONICAL=1 FAIL_PNPM_ADD=1 \
    "$MAC_BOOTSTRAP_DIR/bootstrap.sh" --profile mac-pro --apply >/dev/null 2>&1; then
    fail "pnpm failure should stop bootstrap"
  fi
  TESTS=$((TESTS + 1))
  assert_no_path "$home_dir/.local/graphql-lsp/.pnpm-managed-version"
  assert_no_path "$home_dir/.zshrc"
}

test_shared_zsh_interface() {
  local module="$REPO_DIR/config/zsh/completions.zsh"
  local shared_dir="$REPO_DIR/config/zsh/mac"
  local shared_init="$shared_dir/init.zsh"
  local personal_init="$shared_dir/personal.zsh"
  local root="$TMP_ROOT/shared-zsh-completions"
  local home_dir="$root/home"
  local completion_dir="$root/docker-completions"
  local compinit_log="$root/compinit.log"
  local dump_file="$home_dir/.zcompdump"
  local cache_file="$root/tool-completion.zsh"
  local fake_bin="$root/bin"
  local actual
  local zsh_file

  mkdir -p \
    "$home_dir/Developer" \
    "$home_dir/.local/bin" \
    "$completion_dir" \
    "$fake_bin"
  ln -s "$REPO_DIR" "$home_dir/Developer/dotfiles-hd"
  : > "$home_dir/.local/bin/env"

  for zsh_file in \
    "$module" \
    "$shared_dir/init.zsh" \
    "$shared_dir/prompt.zsh" \
    "$shared_dir/tooling.zsh" \
    "$shared_dir/functions.zsh" \
    "$shared_dir/alias.zsh" \
    "$shared_dir/k8s.zsh" \
    "$shared_dir/personal.zsh" \
    "$shared_dir/personal-functions.zsh" \
    "$shared_dir/personal-aliases.zsh" \
    "$REPO_DIR/setup/mac-pro/.zshrc" \
    "$REPO_DIR/setup/mac-mini/.zshrc" \
    "$REPO_DIR/setup/mac-pro-resilience/.zshrc" \
    "$REPO_DIR/setup/fedora/.zshrc"; do
    /bin/zsh -n "$zsh_file" || fail "zsh syntax check failed: $zsh_file"
    TESTS=$((TESTS + 1))
  done

  for zsh_file in \
    "$REPO_DIR/setup/mac-pro/.zshrc" \
    "$REPO_DIR/setup/mac-mini/.zshrc" \
    "$REPO_DIR/setup/mac-pro-resilience/.zshrc"; do
    assert_contains "$zsh_file" 'config/zsh/mac/init.zsh'
  done
  assert_contains "$REPO_DIR/setup/mac-pro/.zshrc" 'config/zsh/mac/personal.zsh'
  assert_contains "$REPO_DIR/setup/mac-mini/.zshrc" 'config/zsh/mac/personal.zsh'
  assert_not_contains "$REPO_DIR/setup/mac-pro-resilience/.zshrc" 'config/zsh/mac/personal.zsh'
  assert_not_contains "$REPO_DIR/setup/fedora/.zshrc" 'config/zsh/mac'
  assert_not_contains "$REPO_DIR/setup/fedora/.zshrc" 'setup/mac-blaze'
  assert_contains "$shared_init" '../completions.zsh'

  actual="$(
    HOME="$home_dir" PATH="$fake_bin:/usr/bin:/bin" /bin/zsh -dfc '
      source "$1"
      (( $+functions[goodMorning] )) && exit 1
      (( $+functions[carchive] )) && exit 1
      (( $+functions[opmission] )) && exit 1
      (( $+functions[reload] )) || exit 1
      (( $+functions[_goodmorning_sync_dotfiles] )) || exit 1
      alias ll >/dev/null || exit 1
      alias hwatch >/dev/null || exit 1
      alias cod >/dev/null 2>&1 && exit 1
      print -r -- interface-ok
    ' zsh "$shared_init" 2>/dev/null
  )"
  assert_eq interface-ok "$actual" "shared Mac zsh interface excludes personal workflows"

  actual="$(
    HOME="$home_dir" PATH="$fake_bin:/usr/bin:/bin" /bin/zsh -dfc '
      source "$1"
      source "$2"
      (( $+functions[goodMorning] )) || exit 1
      (( $+functions[carchive] )) || exit 1
      (( $+functions[opmission] )) || exit 1
      alias cod >/dev/null || exit 1
      alias opdash >/dev/null || exit 1
      alias hm-dev >/dev/null || exit 1
      print -r -- personal-ok
    ' zsh "$shared_init" "$personal_init" 2>/dev/null
  )"
  assert_eq personal-ok "$actual" "personal Mac zsh interface adds personal workflows"

  for zsh_file in \
    "$REPO_DIR/setup/mac-pro/.zshrc" \
    "$REPO_DIR/setup/mac-mini/.zshrc"; do
    actual="$(
      HOME="$home_dir" PATH="$fake_bin:/usr/bin:/bin" /bin/zsh -dfc '
        source "$1"
        (( $+functions[goodMorning] )) || exit 1
        (( $+functions[carchive] )) || exit 1
        alias cod >/dev/null || exit 1
        alias hwatch >/dev/null || exit 1
        print -r -- profile-ok
      ' zsh "$zsh_file" 2>/dev/null
    )"
    assert_eq profile-ok "$actual" "$(basename "$(dirname "$zsh_file")") profile loads personal Mac zsh interface"
  done

  actual="$(
    HOME="$home_dir" PATH="$fake_bin:/usr/bin:/bin" /bin/zsh -dfc '
      source "$1"
      (( $+functions[goodMorning] )) || exit 1
      (( $+functions[carchive] )) && exit 1
      (( $+functions[opmission] )) && exit 1
      alias v >/dev/null || exit 1
      alias hwatch >/dev/null || exit 1
      alias cod >/dev/null 2>&1 && exit 1
      alias opdash >/dev/null 2>&1 && exit 1
      alias hm-dev >/dev/null 2>&1 && exit 1
      print -r -- resilience-ok
    ' zsh "$REPO_DIR/setup/mac-pro-resilience/.zshrc" 2>/dev/null
  )"
  assert_eq resilience-ok "$actual" "Resilience profile keeps work behavior without personal workflows"

  actual="$(
    HOME="$home_dir" /bin/zsh -dfc '
      source "$1"
      compinit_log="$2"
      dump_file="$3"
      completion_dir="$4"

      compinit() {
        if [[ "${1:-}" == "-C" ]]; then
          print -r -- cached >> "$compinit_log"
        else
          print -r -- full >> "$compinit_log"
        fi
      }

      _zsh_add_completion_dirs "$completion_dir" "$completion_dir"
      count=0
      for entry in $fpath; do
        [[ "$entry" == "$completion_dir" ]] && (( count++ ))
      done
      print -r -- "$count"

      rm -f "$dump_file"
      _zsh_init_completions daily "$dump_file"
      : > "$dump_file"
      _zsh_init_completions daily "$dump_file"
      /usr/bin/touch -t 202001010000 "$dump_file"
      _zsh_init_completions daily "$dump_file"
      /usr/bin/touch "$dump_file"
      _zsh_init_completions 43200 "$dump_file"
    ' zsh "$module" "$compinit_log" "$dump_file" "$completion_dir"
  )"
  assert_eq 1 "$actual" "shared completion paths stay unique"
  assert_eq $'full\ncached\nfull\ncached' "$(cat "$compinit_log")" "compinit preserves profile cache policies"

  actual="$(
    HOME="$home_dir" /bin/zsh -dfc '
      source "$1"
      cache_file="$2"

      rm -f "$cache_file"
      _zsh_cache_needs_refresh "$cache_file" && print -r -- missing
      print -r -- cached > "$cache_file"
      _zsh_cache_needs_refresh "$cache_file" || print -r -- fresh
      /usr/bin/touch -t 202001010000 "$cache_file"
      _zsh_cache_needs_refresh "$cache_file" && print -r -- stale
    ' zsh "$module" "$cache_file"
  )"
  assert_eq $'missing\nfresh\nstale' "$actual" "shared cache freshness handles missing, fresh, and stale files"

  printf '#!/bin/sh\nprintf "Linux\\n"\n' > "$fake_bin/uname"
  chmod +x "$fake_bin/uname"
  actual="$(
    HOME="$home_dir" PATH="$fake_bin:/usr/bin:/bin" /bin/zsh -dfc '
      source "$HOME/Developer/dotfiles-hd/setup/mac-pro-resilience/.zshrc"
      whence -w _zsh_load_common_tool_completions _zsh_cache_and_source
      alias v
    ' 2>/dev/null
  )"
  assert_eq $'_zsh_load_common_tool_completions: function\n_zsh_cache_and_source: function\nv=nvim' "$actual" "Resilience shell tolerates missing optional completion tools"

  printf '#!/bin/sh\nprintf "shared_completion_state=generated\\n"\n' > "$fake_bin/completion-ok"
  printf '#!/bin/sh\nexit 1\n' > "$fake_bin/completion-fail"
  chmod +x "$fake_bin/completion-ok" "$fake_bin/completion-fail"
  actual="$(
    HOME="$home_dir" PATH="$fake_bin:/usr/bin:/bin" /bin/zsh -dfc '
      source "$1"
      cache_file="$2"

      rm -f "$cache_file"
      _zsh_cache_and_source completion-ok "$cache_file" completion-ok
      print -r -- "first=$shared_completion_state"

      print -r -- shared_completion_state=preserved > "$cache_file"
      /usr/bin/touch -t 202001010000 "$cache_file"
      unset shared_completion_state
      _zsh_cache_and_source completion-fail "$cache_file" completion-fail
      print -r -- "second=$shared_completion_state"
      print -r -- "disk=$(<"$cache_file")"
    ' zsh "$module" "$cache_file"
  )"
  assert_eq $'first=generated\nsecond=preserved\ndisk=shared_completion_state=preserved' "$actual" "failed refresh preserves a valid completion cache"
}

test_goodmorning_timeout_helper() {
  local functions_file="$REPO_DIR/config/zsh/mac/functions.zsh"
  local start_epoch
  local elapsed

  /bin/zsh -c 'source "$1"; _run_with_timeout 2 /usr/bin/true' zsh "$functions_file" \
    || fail "timeout helper should preserve successful command status"
  TESTS=$((TESTS + 1))

  start_epoch="$(date +%s)"
  if /bin/zsh -c 'source "$1"; _run_with_timeout 1 /bin/sleep 10' zsh "$functions_file"; then
    fail "timeout helper should stop an overlong command"
  fi
  elapsed=$(( $(date +%s) - start_epoch ))
  TESTS=$((TESTS + 1))
  (( elapsed < 5 )) || fail "timeout helper took ${elapsed}s to stop an overlong command"
}

test_goodmorning_dotfiles_sync() {
  local functions_file="$REPO_DIR/config/zsh/mac/functions.zsh"
  local resilience_file="$REPO_DIR/setup/mac-pro-resilience/.zshrc"
  local root="$TMP_ROOT/goodmorning-dotfiles-sync"
  local home_dir="$root/home"
  local fake_bin="$root/bin"
  local git_log="$root/git.log"
  local output

  mkdir -p "$home_dir/Developer/dotfiles-hd/.git" "$fake_bin"
  cat > "$fake_bin/git" <<'EOF'
#!/bin/sh
if [ "$3" = "remote" ]; then
  printf '%s\n' "$FAKE_GIT_ORIGIN"
  exit 0
fi
if [ "$3" = "pull" ]; then
  printf '%s\n' "$*" > "$FAKE_GIT_LOG"
  exit 0
fi
exit 1
EOF
  chmod +x "$fake_bin/git"

  HOME="$home_dir" \
    PATH="$fake_bin:/usr/bin:/bin" \
    FAKE_GIT_ORIGIN="git@github.com:hd719/dotfiles-hd.git" \
    FAKE_GIT_LOG="$git_log" \
    /bin/zsh -dfc 'source "$1"; _goodmorning_sync_dotfiles' zsh "$functions_file"
  assert_contains "$git_log" "pull --ff-only origin master"

  rm -f "$git_log"
  output="$(
    HOME="$home_dir" \
      PATH="$fake_bin:/usr/bin:/bin" \
      FAKE_GIT_ORIGIN="git@github.com:someone-else/dotfiles-hd.git" \
      FAKE_GIT_LOG="$git_log" \
      /bin/zsh -dfc 'source "$1"; _goodmorning_sync_dotfiles' zsh "$functions_file" 2>&1 \
      || true
  )"
  [[ "$output" == *"not hd719/dotfiles-hd"* ]] \
    || fail "unexpected dotfiles origin should be rejected"
  TESTS=$((TESTS + 1))
  assert_no_path "$git_log"
  assert_contains "$resilience_file" "_goodmorning_sync_dotfiles"
}

test_link_helper
test_zprofile_helper
test_neovim_lock_guard
test_neovim_plugin_checkout_integrity
test_neovim_parser_manifest
test_profile_names_and_paths
test_full_bootstrap
test_mac_mini_apply
test_xdg_bin_home
test_profile_and_failure_guards
test_shared_zsh_interface
test_goodmorning_timeout_helper
test_goodmorning_dotfiles_sync

printf 'PASS: %d bootstrap assertions\n' "$TESTS"
