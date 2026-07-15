#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BOOTSTRAP="$SCRIPT_DIR/../bootstrap.sh"
DOCTOR="$SCRIPT_DIR/../check-dependencies.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/nvim-doctor.XXXXXX")"
FAKE_HOME="$TMP_ROOT/home"
UV_BIN="$TMP_ROOT/uv-bin"
REAL_BASH="$(command -v bash)"
REAL_GREP="$(command -v grep)"
REAL_DIRNAME="$(command -v dirname)"
REAL_SED="$(command -v sed)"
failures=0

trap 'rm -rf "$TMP_ROOT"' EXIT
mkdir -p "$FAKE_HOME" "$UV_BIN"

write_stub() {
  local dir="$1"
  local name="$2"
  shift 2

  {
    printf '#!%s\n' "$REAL_BASH"
    printf '%s\n' "$@"
  } >"$dir/$name"
  chmod +x "$dir/$name"
}

make_core_path() {
  local dir="$1"
  local tree_sitter_version="$2"
  local download_client="$3"
  local command_name

  mkdir -p "$dir"
  ln -s "$REAL_BASH" "$dir/bash"
  ln -s "$REAL_DIRNAME" "$dir/dirname"
  ln -s "$REAL_GREP" "$dir/grep"
  ln -s "$REAL_SED" "$dir/sed"

  write_stub "$dir" nvim 'echo "NVIM v0.12.4"'
  write_stub "$dir" tree-sitter "echo \"tree-sitter $tree_sitter_version\""

  for command_name in git rg fd fzf lazygit cc unzip tar gzip; do
    write_stub "$dir" "$command_name" 'exit 0'
  done

  write_stub "$dir" "$download_client" 'exit 0'
}

make_full_path() {
  local dir="$1"
  local command_name

  make_core_path "$dir" "0.26.10" curl

  for command_name in \
    node npm bash-language-server gopls gofmt lua-language-server stylua vtsls \
    vscode-eslint-language-server vscode-json-language-server \
    vscode-css-language-server vscode-html-language-server graphql-lsp
  do
    write_stub "$dir" "$command_name" 'exit 0'
  done

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

run_doctor() {
  local path="$1"
  local profile="$2"

  set +e
  DOCTOR_OUTPUT="$(
    PATH="$path" \
      HOME="$FAKE_HOME" \
      TEST_UV_BIN="$UV_BIN" \
      "$REAL_BASH" "$DOCTOR" "$profile" 2>&1
  )"
  DOCTOR_STATUS=$?
  set -e
}

run_bootstrap() {
  local path="$1"
  local profile="$2"

  set +e
  DOCTOR_OUTPUT="$(
    PATH="$path" \
      HOME="$FAKE_HOME" \
      TEST_UV_BIN="$UV_BIN" \
      "$REAL_BASH" "$BOOTSTRAP" "$profile" 2>&1
  )"
  DOCTOR_STATUS=$?
  set -e
}

expect_success() {
  local label="$1"

  if ((DOCTOR_STATUS != 0)); then
    echo "FAIL: $label (expected success)" >&2
    printf '%s\n' "$DOCTOR_OUTPUT" >&2
    failures=$((failures + 1))
  fi
}

expect_failure_containing() {
  local label="$1"
  local expected="$2"

  if ((DOCTOR_STATUS == 0)); then
    echo "FAIL: $label (expected failure)" >&2
    failures=$((failures + 1))
  elif [[ "$DOCTOR_OUTPUT" != *"$expected"* ]]; then
    echo "FAIL: $label (missing output: $expected)" >&2
    printf '%s\n' "$DOCTOR_OUTPUT" >&2
    failures=$((failures + 1))
  fi
}

expect_output_containing() {
  local label="$1"
  local expected="$2"

  if [[ "$DOCTOR_OUTPUT" != *"$expected"* ]]; then
    echo "FAIL: $label (missing output: $expected)" >&2
    printf '%s\n' "$DOCTOR_OUTPUT" >&2
    failures=$((failures + 1))
  fi
}

write_stub "$UV_BIN" mdformat \
  'echo "mdformat 1.0.0 (mdformat_gfm_alerts 2.0.0, mdformat-gfm 1.0.0, mdformat_footnote 0.1.3, mdformat_wikilink 0.3.0, mdformat_frontmatter 2.1.2)"'
write_stub "$UV_BIN" ruff 'echo "ruff 0.15.21"'

old_tree_sitter_path="$TMP_ROOT/old-tree-sitter"
make_core_path "$old_tree_sitter_path" "0.26.0" curl
run_doctor "$old_tree_sitter_path" core
expect_failure_containing \
  "Tree-sitter below 0.26.1 is rejected" \
  "Tree-sitter CLI 0.26.1+"

minimum_tree_sitter_path="$TMP_ROOT/minimum-tree-sitter"
make_core_path "$minimum_tree_sitter_path" "0.26.1" curl
run_doctor "$minimum_tree_sitter_path" core
expect_success "Tree-sitter 0.26.1 is accepted"

wget_only_path="$TMP_ROOT/wget-only"
make_core_path "$wget_only_path" "0.26.10" wget
run_doctor "$wget_only_path" core
expect_failure_containing "wget cannot replace curl" "curl (curl)"

uv_not_persistent_path="$TMP_ROOT/uv-not-persistent"
make_full_path "$uv_not_persistent_path"
run_doctor "$uv_not_persistent_path" full
expect_failure_containing \
  "uv tools must be on the caller PATH" \
  "Put $UV_BIN first"

run_bootstrap "$uv_not_persistent_path" full
expect_failure_containing \
  "bootstrap preserves the caller PATH for its doctor" \
  "Put $UV_BIN first"

uv_persistent_path="$TMP_ROOT/uv-persistent"
make_full_path "$uv_persistent_path"
run_doctor "$uv_persistent_path:$UV_BIN" full
expect_success "uv tools on the caller PATH are accepted"

stale_shadow_path="$TMP_ROOT/stale-shadow"
make_full_path "$stale_shadow_path"
write_stub "$stale_shadow_path" mdformat 'echo "mdformat 0.7.17"'
write_stub "$stale_shadow_path" ruff 'echo "ruff 0.9.0"'
run_doctor "$stale_shadow_path:$UV_BIN" full
expect_failure_containing \
  "stale mdformat ahead of the uv tool directory is rejected" \
  "found: mdformat 0.7.17"
expect_output_containing \
  "stale Ruff ahead of the uv tool directory is rejected" \
  "found: ruff 0.9.0"
expect_output_containing \
  "PATH ordering guidance puts the uv tool directory first" \
  "Put $UV_BIN first"

if ((failures > 0)); then
  echo "$failures dependency-doctor regression test(s) failed." >&2
  exit 1
fi

echo "dependency-doctor regression tests: ok"
