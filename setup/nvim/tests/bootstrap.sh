#!/usr/bin/env bash
# Stop on command errors (-e), unset variables (-u), and failures hidden
# inside pipelines (pipefail).
set -euo pipefail

# This test never installs real packages. It builds a disposable repo, HOME,
# PATH, and Homebrew tree, then fills them with tiny fake commands (stubs).
SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/nvim-bootstrap.XXXXXX")"
TEST_REPO="$TMP_ROOT/repo"
CORE_BIN="$TMP_ROOT/core-bin"
FULL_BIN="$TMP_ROOT/full-bin"
UV_BIN="$TMP_ROOT/uv-bin"
BREW_ROOT="$TMP_ROOT/homebrew"
STATE_DIR="$TMP_ROOT/state"
FAKE_HOME="$TMP_ROOT/home"
REAL_BASH="$(command -v bash)"
failures=0

# Remove the entire fake machine even when an assertion or command fails.
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p \
  "$TEST_REPO/setup/nvim" \
  "$TEST_REPO/config/nvim" \
  "$CORE_BIN" \
  "$FULL_BIN" \
  "$UV_BIN" \
  "$BREW_ROOT/bin" \
  "$BREW_ROOT/Cellar/node@22/22.23.1/bin" \
  "$BREW_ROOT/Cellar/node/26.5.0/bin" \
  "$STATE_DIR" \
  "$FAKE_HOME"

cp "$SOURCE_ROOT/setup/nvim/bootstrap.sh" "$TEST_REPO/setup/nvim/bootstrap.sh"
cp "$SOURCE_ROOT/setup/nvim/check-dependencies.sh" "$TEST_REPO/setup/nvim/check-dependencies.sh"
cp "$SOURCE_ROOT/config/nvim/lazy-lock.json" "$TEST_REPO/config/nvim/lazy-lock.json"
cp "$SOURCE_ROOT/config/nvim/lazy-lock.json" "$TMP_ROOT/expected-lock.json"

write_stub() {
  local dir="$1"
  local name="$2"
  shift 2

  # Each remaining argument is one line of the fake executable. Writing stubs
  # this way lets a test control exactly what a dependency reports or changes.
  {
    printf '#!%s\n' "$REAL_BASH"
    printf '%s\n' "$@"
  } >"$dir/$name"
  chmod +x "$dir/$name"
}

link_real_commands() {
  local dir="$1"
  local command_name real_command

  # The fake PATH contains only the commands we choose. Link harmless shell
  # utilities from the real machine so the script under test can still run.
  for command_name in bash chmod cmp cp dirname grep ln mktemp readlink rm sed; do
    real_command="$(command -v "$command_name")"
    ln -s "$real_command" "$dir/$command_name"
  done
}

make_core_path() {
  local dir="$1"
  local command_name

  mkdir -p "$dir"
  link_real_commands "$dir"

  # This Neovim stub counts headless restores. On request, its first call
  # corrupts the lock and its second call proves bootstrap restored the pins.
  write_stub "$dir" nvim \
    'if [[ "${1:-}" == "--version" ]]; then' \
    '  echo "NVIM v0.12.4"' \
    '  exit 0' \
    'fi' \
    'count_file="$TEST_STATE_DIR/nvim-calls"' \
    'count=0' \
    '[[ -f "$count_file" ]] && count="$(<"$count_file")"' \
    'count=$((count + 1))' \
    'printf "%s\n" "$count" >"$count_file"' \
    'if [[ "${TEST_MUTATE_LOCK:-0}" == "1" && "$count" == "1" ]]; then' \
    '  printf "%s\n" "{\"lazy.nvim\":{\"commit\":\"mutated\"}}" >"$TEST_LOCKFILE"' \
    'elif [[ "${TEST_MUTATE_LOCK:-0}" == "1" && "$count" == "2" ]]; then' \
    '  cmp -s "$TEST_LOCKFILE" "$TEST_EXPECTED_LOCK" || exit 91' \
    'fi'

  write_stub "$dir" tree-sitter 'echo "tree-sitter 0.26.10"'

  for command_name in git rg fd fzf lazygit cc curl unzip tar gzip; do
    write_stub "$dir" "$command_name" 'exit 0'
  done
}

make_full_path() {
  local dir="$1"
  local command_name

  # Start with core, then add the commands required by the full profile.
  make_core_path "$dir"

  for command_name in \
    gofmt lua-language-server stylua vtsls \
    vscode-eslint-language-server vscode-json-language-server \
    vscode-css-language-server vscode-html-language-server graphql-lsp
  do
    write_stub "$dir" "$command_name" 'exit 0'
  done

  # The shared doctor enforces the minimum supported gopls line, not only the
  # existence of a command with that name.
  write_stub "$dir" gopls 'echo "golang.org/x/tools/gopls v0.23.0"'

  write_stub "$dir" uv \
    'if [[ "$1 $2 $3" == "tool dir --bin" ]]; then' \
    '  printf "%s\n" "$TEST_UV_BIN"' \
    'elif [[ "$1 $2" == "tool list" ]]; then' \
    '  printf "%s\n" \' \
    '    "mdformat v1.0.0 (from mdformat==1.0.0)" \' \
    '    "- mdformat-footnote==0.1.3" \' \
    '    "- mdformat-frontmatter==2.1.2" \' \
    '    "- mdformat-gfm==1.0.0" \' \
    '    "- mdformat-gfm-alerts==2.0.0" \' \
    '    "- mdformat-wikilink==0.3.0"' \
    'fi'
}

run_bootstrap() {
  local path="$1"
  local profile="$2"
  shift 2

  rm -f "$STATE_DIR/nvim-calls"
  # Some scenarios intentionally fail. Temporarily disable `set -e` so the
  # harness can capture both output and status, then turn strict mode back on.
  set +e
  BOOTSTRAP_OUTPUT="$(
    env \
      PATH="$path" \
      HOME="$FAKE_HOME" \
      TEST_EXPECTED_LOCK="$TMP_ROOT/expected-lock.json" \
      TEST_LOCKFILE="$TEST_REPO/config/nvim/lazy-lock.json" \
      TEST_STATE_DIR="$STATE_DIR" \
      TEST_UV_BIN="$UV_BIN" \
      "$@" \
      "$REAL_BASH" "$TEST_REPO/setup/nvim/bootstrap.sh" "$profile" 2>&1
  )"
  BOOTSTRAP_STATUS=$?
  set -e
}

expect() {
  local label="$1"
  shift

  # Run the assertion command supplied in "$@". Record every failure so one
  # test run reports all broken guarantees instead of stopping at the first.
  if ! "$@"; then
    echo "FAIL: $label" >&2
    failures=$((failures + 1))
  fi
}

expect_output_containing() {
  local label="$1"
  local expected="$2"

  if [[ "$BOOTSTRAP_OUTPUT" != *"$expected"* ]]; then
    echo "FAIL: $label (missing output: $expected)" >&2
    failures=$((failures + 1))
  fi
}

expect_output_not_containing() {
  local label="$1"
  local unexpected="$2"

  if [[ "$BOOTSTRAP_OUTPUT" == *"$unexpected"* ]]; then
    echo "FAIL: $label (unexpected output: $unexpected)" >&2
    failures=$((failures + 1))
  fi
}

# Scenario 1: a fresh core restore may mutate the lock once, but bootstrap must
# replace it and run a second convergence pass.
make_core_path "$CORE_BIN"
run_bootstrap "$CORE_BIN" core TEST_MUTATE_LOCK=1
expect "fresh bootstrap succeeds after restoring the committed lock" \
  test "$BOOTSTRAP_STATUS" -eq 0
expect "fresh bootstrap leaves lazy-lock.json byte-identical" \
  cmp -s "$TEST_REPO/config/nvim/lazy-lock.json" "$TMP_ROOT/expected-lock.json"
expect "fresh bootstrap runs a second restore after replacing the lock" \
  test "$(<"$STATE_DIR/nvim-calls")" -eq 2

# Build a fake Homebrew with Node 22 linked for the user and Node 26 available
# for language servers. The Brew stub records installs and can simulate relinks.
write_stub "$BREW_ROOT/Cellar/node@22/22.23.1/bin" node 'echo "v22.23.1"'
write_stub "$BREW_ROOT/Cellar/node@22/22.23.1/bin" npm 'echo "10.9.4"'
write_stub "$BREW_ROOT/Cellar/node/26.5.0/bin" node 'echo "v26.5.0"'
write_stub "$BREW_ROOT/Cellar/node/26.5.0/bin" npm 'echo "11.17.0"'
ln -s ../Cellar/node@22/22.23.1/bin/node "$BREW_ROOT/bin/node"
ln -s ../Cellar/node@22/22.23.1/bin/npm "$BREW_ROOT/bin/npm"

write_stub "$BREW_ROOT/bin" brew \
  'case "$1" in' \
  '  --prefix)' \
  '    printf "%s\n" "$TEST_BREW_ROOT"' \
  '    ;;' \
  '  install)' \
  '    formula="${*: -1}"' \
  '    printf "%s\n" "$*" >>"$TEST_STATE_DIR/brew-installs"' \
  '    if [[ "$formula" == "node" ]]; then' \
  '      printf "installed\n" >"$TEST_STATE_DIR/brew-node-installed"' \
  '    elif [[ "$formula" == "bash-language-server" ]]; then' \
  '      if [[ ! -f "$TEST_STATE_DIR/brew-node-installed" || "${TEST_BREW_FORCE_RELINK:-0}" == "1" ]]; then' \
  '        printf "installed\n" >"$TEST_STATE_DIR/brew-node-installed"' \
  '        ln -sf ../Cellar/node/26.5.0/bin/node "$TEST_BREW_ROOT/bin/node"' \
  '        ln -sf ../Cellar/node/26.5.0/bin/npm "$TEST_BREW_ROOT/bin/npm"' \
  '      fi' \
  '      printf "#!%s\nexit 0\n" "$TEST_REAL_BASH" >"$TEST_BREW_ROOT/bin/bash-language-server"' \
  '      chmod +x "$TEST_BREW_ROOT/bin/bash-language-server"' \
  '      if [[ "${TEST_BREW_FAIL_AFTER_RELINK:-0}" == "1" ]]; then' \
  '        exit 42' \
  '      fi' \
  '    fi' \
  '    ;;' \
  '  list)' \
  '    if [[ "${2:-} ${3:-}" == "--versions node" && -f "$TEST_STATE_DIR/brew-node-installed" ]]; then' \
  '      echo "node 26.5.0"' \
  '    else' \
  '      exit 1' \
  '    fi' \
  '    ;;' \
  '  outdated)' \
  '    if [[ "${2:-} ${3:-}" == "--quiet node" && "${TEST_BREW_NODE_OUTDATED:-0}" == "1" ]]; then' \
  '      echo "node"' \
  '    fi' \
  '    ;;' \
  '  unlink)' \
  '    [[ "$2" == "node" ]] && rm -f "$TEST_BREW_ROOT/bin/node" "$TEST_BREW_ROOT/bin/npm"' \
  '    ;;' \
  '  link)' \
  '    if [[ "${*: -1}" == "node@22" ]]; then' \
  '      ln -sf ../Cellar/node@22/22.23.1/bin/node "$TEST_BREW_ROOT/bin/node"' \
  '      ln -sf ../Cellar/node@22/22.23.1/bin/npm "$TEST_BREW_ROOT/bin/npm"' \
  '    fi' \
  '    ;;' \
  'esac'

make_full_path "$FULL_BIN"
write_stub "$UV_BIN" mdformat \
  'echo "mdformat 1.0.0 (mdformat_gfm_alerts 2.0.0, mdformat-gfm 1.0.0, mdformat_footnote 0.1.3, mdformat_wikilink 0.3.0, mdformat_frontmatter 2.1.2)"'
write_stub "$UV_BIN" ruff 'echo "ruff 0.15.21"'
cp "$TMP_ROOT/expected-lock.json" "$TEST_REPO/config/nvim/lazy-lock.json"
rm -f "$STATE_DIR/brew-node-installed" "$STATE_DIR/brew-installs"

# Scenario 2: installing a language server must use private Node 26 while
# restoring the public `node` command to the original Node 22.
run_bootstrap \
  "$BREW_ROOT/bin:$FULL_BIN:$UV_BIN" \
  full \
  TEST_BREW_ROOT="$BREW_ROOT" \
  TEST_REAL_BASH="$REAL_BASH"

expect "full bootstrap succeeds after a Homebrew dependency relinks Node" \
  test "$BOOTSTRAP_STATUS" -eq 0
expect "bootstrap restores the original Homebrew Node link" \
  test "$(readlink "$BREW_ROOT/bin/node")" = "../Cellar/node@22/22.23.1/bin/node"
expect "bootstrap keeps the original Node version" \
  test "$(PATH="$BREW_ROOT/bin:$FULL_BIN" node --version)" = "v22.23.1"
expect "the installed language server remains available" \
  test -x "$BREW_ROOT/bin/bash-language-server"
expect "Homebrew Node was installed as an unlinked dependency" \
  grep -q '^install --skip-link --as-dependency node$' "$STATE_DIR/brew-installs"

# Scenario 3: a second full run is idempotent and installs nothing else.
install_count="$(wc -l <"$STATE_DIR/brew-installs")"
run_bootstrap \
  "$BREW_ROOT/bin:$FULL_BIN:$UV_BIN" \
  full \
  TEST_BREW_ROOT="$BREW_ROOT" \
  TEST_REAL_BASH="$REAL_BASH"
expect "a second full bootstrap performs no Homebrew installs" \
  test "$(wc -l <"$STATE_DIR/brew-installs")" -eq "$install_count"
expect "a second full bootstrap still keeps Node 22" \
  test "$(PATH="$BREW_ROOT/bin:$FULL_BIN" node --version)" = "v22.23.1"

# Scenario 4: a machine that starts without Node may receive Homebrew Node as
# its new active runtime because there is no existing host choice to preserve.
rm -f \
  "$BREW_ROOT/bin/node" \
  "$BREW_ROOT/bin/npm" \
  "$BREW_ROOT/bin/bash-language-server" \
  "$STATE_DIR/brew-node-installed"
cp "$TMP_ROOT/expected-lock.json" "$TEST_REPO/config/nvim/lazy-lock.json"
run_bootstrap \
  "$BREW_ROOT/bin:$FULL_BIN:$UV_BIN" \
  full \
  TEST_BREW_ROOT="$BREW_ROOT" \
  TEST_REAL_BASH="$REAL_BASH"
expect "a machine without Node receives Homebrew Node" \
  test "$BOOTSTRAP_STATUS" -eq 0
expect "a newly supplied Node is available to Neovim" \
  test "$(PATH="$BREW_ROOT/bin:$FULL_BIN" node --version)" = "v26.5.0"

# Scenario 5: even when Brew relinks Node and then fails, the EXIT cleanup trap
# must put the original Node 22 link back before the script returns.
ln -sf ../Cellar/node@22/22.23.1/bin/node "$BREW_ROOT/bin/node"
ln -sf ../Cellar/node@22/22.23.1/bin/npm "$BREW_ROOT/bin/npm"
rm -f "$BREW_ROOT/bin/bash-language-server"
printf "installed\n" >"$STATE_DIR/brew-node-installed"
run_bootstrap \
  "$BREW_ROOT/bin:$FULL_BIN:$UV_BIN" \
  full \
  TEST_BREW_ROOT="$BREW_ROOT" \
  TEST_REAL_BASH="$REAL_BASH" \
  TEST_BREW_FORCE_RELINK=1 \
  TEST_BREW_FAIL_AFTER_RELINK=1
expect "a failed Homebrew install keeps a failing exit status" \
  test "$BOOTSTRAP_STATUS" -ne 0
expect "failure cleanup restores the original Node link" \
  test "$(readlink "$BREW_ROOT/bin/node")" = "../Cellar/node@22/22.23.1/bin/node"
expect "failure cleanup restores the original Node version" \
  test "$(PATH="$BREW_ROOT/bin:$FULL_BIN" node --version)" = "v22.23.1"

# Scenario 6: refuse to install against an outdated active unversioned Node;
# otherwise Brew could upgrade it before the old version can be restored.
ln -sf ../Cellar/node/26.5.0/bin/node "$BREW_ROOT/bin/node"
ln -sf ../Cellar/node/26.5.0/bin/npm "$BREW_ROOT/bin/npm"
rm -f "$BREW_ROOT/bin/bash-language-server"
install_count="$(wc -l <"$STATE_DIR/brew-installs")"
run_bootstrap \
  "$BREW_ROOT/bin:$FULL_BIN:$UV_BIN" \
  full \
  TEST_BREW_ROOT="$BREW_ROOT" \
  TEST_REAL_BASH="$REAL_BASH" \
  TEST_BREW_NODE_OUTDATED=1
expect "an outdated active unversioned Homebrew Node stops bootstrap" \
  test "$BOOTSTRAP_STATUS" -ne 0
expect "the outdated active Node is not changed" \
  test "$(PATH="$BREW_ROOT/bin:$FULL_BIN" node --version)" = "v26.5.0"
expect "no language-server install runs with an outdated active Node" \
  test "$(wc -l <"$STATE_DIR/brew-installs")" -eq "$install_count"

# Scenario 7: an old external gopls cannot be upgraded safely by the shared
# bootstrap. Stop before the doctor and explain the exact host-managed upgrade.
stale_gopls_path="$TMP_ROOT/stale-external-gopls"
make_full_path "$stale_gopls_path"
write_stub "$stale_gopls_path" node 'echo "v22.22.0"'
write_stub "$stale_gopls_path" npm 'echo "10.9.4"'
write_stub "$stale_gopls_path" gopls 'echo "golang.org/x/tools/gopls v0.16.1"'
run_bootstrap "$stale_gopls_path:$UV_BIN" full
expect "stale external gopls stops bootstrap" \
  test "$BOOTSTRAP_STATUS" -ne 0
expect_output_containing \
  "stale external gopls reports the supported minimum" \
  "gopls 0.23.0+"
expect_output_containing \
  "stale external gopls explains the required action" \
  "with its package manager"
expect_output_not_containing \
  "stale external gopls fails before the dependency doctor" \
  "Neovim dependency check"

# Convert the accumulated assertion count into the test process's exit status.
if ((failures > 0)); then
  printf '%s\n' "$BOOTSTRAP_OUTPUT" >&2
  echo "$failures bootstrap regression test(s) failed." >&2
  exit 1
fi

echo "bootstrap regression tests: ok"
