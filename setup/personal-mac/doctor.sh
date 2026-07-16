#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
PROFILE=""
FAILURES=0
MISE_RUNTIME_FAILURES=0

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  printf 'Usage: doctor.sh --profile mac-vm|mac-mini\n'
}

pass() {
  printf 'PASS  %s\n' "$*"
}

fail() {
  printf 'FAIL  %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      PROFILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "$PROFILE" ]] || { usage >&2; exit 2; }
load_profile "$PROFILE" "$DOTFILES_DIR" "$HOME" || exit 2
load_mise_specs "$MISE_CONFIG" || exit 2
export MISE_AUTO_INSTALL=0

check_approved_pin() {
  local tool="$1"
  local actual="$2"
  local expected="$3"

  if [[ "$actual" == "$expected" ]]; then
    pass "$tool config pin is $expected"
  else
    fail "$tool config pin expected $expected, got $actual"
  fi
}

check_approved_pin node "$NODE_VERSION" "$APPROVED_NODE_VERSION"
check_approved_pin pnpm "$PNPM_VERSION" "$APPROVED_PNPM_VERSION"
check_approved_pin go "$GO_VERSION" "$APPROVED_GO_VERSION"
check_approved_pin python "$PYTHON_VERSION" "$APPROVED_PYTHON_VERSION"
check_approved_pin bun "$BUN_VERSION" "$APPROVED_BUN_VERSION"

for brewfile in "$COMMON_BREWFILE" "$PROFILE_BREWFILE"; do
  if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file "$brewfile" >/dev/null; then
    pass "Brewfile satisfied: $brewfile"
  else
    fail "Brewfile missing dependencies: $brewfile"
  fi
done

for spec in "${LINK_SPECS[@]}"; do
  source_path="${spec%%|*}"
  destination="${spec#*|}"
  if link_matches "$source_path" "$destination"; then
    pass "$destination -> $source_path"
  else
    fail "link mismatch: $destination"
  fi
done

if zprofile_block_matches "$HOME/.zprofile" "$MISE_FRAGMENT"; then
  pass "mise shims block is exact in ~/.zprofile"
else
  fail "mise shims block is missing, malformed, or stale in ~/.zprofile"
fi

check_mise_version() {
  local tool="$1"
  local expected="$2"
  local command_name="$3"
  local version_argument="--version"
  local normalized
  local actual

  if ! MISE_NO_CONFIG=1 mise where "$tool@$expected" >/dev/null 2>&1; then
    fail "$tool $expected is not installed by mise"
    MISE_RUNTIME_FAILURES=$((MISE_RUNTIME_FAILURES + 1))
    return
  fi

  [[ "$command_name" == "go" ]] && version_argument="version"
  actual="$(MISE_NO_CONFIG=1 mise exec "$tool@$expected" -- "$command_name" "$version_argument" 2>/dev/null | head -n 1)"
  normalized="$(normalize_tool_version "$tool" "$actual")"
  if [[ "$normalized" == "$expected" ]]; then
    pass "$tool $expected"
  else
    fail "$tool expected $expected, got '${normalized:-missing}'"
    MISE_RUNTIME_FAILURES=$((MISE_RUNTIME_FAILURES + 1))
  fi
}

normalize_tool_version() {
  local tool="$1"
  local output="$2"

  output="${output//$'\r'/}"
  output="${output%%$'\n'*}"
  case "$tool" in
    node) output="${output#v}" ;;
    go)
      output="${output#go version go}"
      output="${output%% *}"
      ;;
    python)
      output="${output#Python }"
      output="${output%% *}"
      ;;
    pnpm|bun) output="${output%% *}" ;;
  esac
  printf '%s\n' "$output"
}

check_mise_version node "$APPROVED_NODE_VERSION" node
check_mise_version pnpm "$APPROVED_PNPM_VERSION" pnpm
check_mise_version go "$APPROVED_GO_VERSION" go
check_mise_version python "$APPROVED_PYTHON_VERSION" python
check_mise_version bun "$APPROVED_BUN_VERSION" bun

if [[ "$MISE_RUNTIME_FAILURES" -eq 0 ]]; then
  for command_name in npm npx; do
    if MISE_NO_CONFIG=1 mise exec "node@$NODE_VERSION" -- "$command_name" --version >/dev/null 2>&1; then
      pass "$command_name remains available through mise Node"
    else
      fail "$command_name is missing from mise Node"
    fi
  done

  required_commands='mise node npm npx pnpm go python bun nvim rg fd fzf lazygit tree-sitter lua-language-server stylua vtsls vscode-eslint-language-server bash-language-server gopls ruff mdformat'
  shell_baseline_path="$(sanitize_shell_path "$PATH")"
  shell_version_probe='printf "__DOTFILES_NODE__=%s\n" "$(node --version 2>/dev/null)"
printf "__DOTFILES_PNPM__=%s\n" "$(pnpm --version 2>/dev/null)"
printf "__DOTFILES_GO__=%s\n" "$(go version 2>/dev/null)"
printf "__DOTFILES_PYTHON__=%s\n" "$(python --version 2>/dev/null)"
printf "__DOTFILES_BUN__=%s\n" "$(bun --version 2>/dev/null)"'
  for shell_mode in '-lic' '-lc'; do
    if HOME="$HOME" PATH="$shell_baseline_path" /bin/zsh "$shell_mode" "for tool in $required_commands; do command -v \"\$tool\" >/dev/null || exit 1; done" >/dev/null 2>&1; then
      pass "zsh $shell_mode resolves the required toolchain"
    else
      fail "zsh $shell_mode cannot resolve the full required toolchain"
    fi

    shell_versions="$(HOME="$HOME" PATH="$shell_baseline_path" /bin/zsh "$shell_mode" "$shell_version_probe" 2>/dev/null || true)"
    for version_spec in \
      "node|$NODE_VERSION|NODE" \
      "pnpm|$PNPM_VERSION|PNPM" \
      "go|$GO_VERSION|GO" \
      "python|$PYTHON_VERSION|PYTHON" \
      "bun|$BUN_VERSION|BUN"; do
      tool="${version_spec%%|*}"
      version_spec="${version_spec#*|}"
      expected="${version_spec%%|*}"
      tag="${version_spec#*|}"
      raw_version="$(printf '%s\n' "$shell_versions" | sed -n "s/^__DOTFILES_${tag}__=//p" | tail -n 1)"
      actual_version="$(normalize_tool_version "$tool" "$raw_version")"
      if [[ "$actual_version" == "$expected" ]]; then
        pass "zsh $shell_mode active $tool is $expected"
      else
        fail "zsh $shell_mode active $tool expected $expected, got '${actual_version:-missing}'"
      fi
    done
  done
else
  fail "active shell checks skipped because pinned mise runtimes are missing"
fi

ruff_output="$("${XDG_BIN_HOME:-$HOME/.local/bin}/ruff" --version 2>/dev/null || true)"
if [[ "$ruff_output" == "ruff 0.15.21" ]]; then
  pass "Ruff 0.15.21"
else
  fail "Ruff expected 0.15.21, got '${ruff_output:-missing}'"
fi

mdformat_output="$("${XDG_BIN_HOME:-$HOME/.local/bin}/mdformat" --version 2>/dev/null || true)"
mdformat_components="$(printf '%s\n' "$mdformat_output" \
  | tr '(),' '\n' \
  | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
for expected_component in \
  'mdformat 1.0.0' \
  'mdformat_gfm_alerts 2.0.0' \
  'mdformat-gfm 1.0.0' \
  'mdformat_footnote 0.1.3' \
  'mdformat_wikilink 0.3.0' \
  'mdformat_frontmatter 2.1.2'; do
  if grep -Fqx "$expected_component" <<< "$mdformat_components"; then
    pass "$expected_component"
  else
    fail "mdformat component missing or wrong: $expected_component"
  fi
done

graphql_lsp="$HOME/.local/graphql-lsp/bin/graphql-lsp"
if [[ "$MISE_RUNTIME_FAILURES" -eq 0 ]]; then
  graphql_output="$(MISE_NO_CONFIG=1 mise exec "node@$NODE_VERSION" -- "$graphql_lsp" --version 2>/dev/null || true)"
  if [[ "$graphql_output" == "3.5.0" ]]; then
    pass "GraphQL LSP 3.5.0 at fixed prefix"
  else
    fail "GraphQL LSP expected 3.5.0, got '${graphql_output:-missing}'"
  fi
else
  fail "GraphQL LSP check skipped because pinned mise Node is missing"
fi

nvim_version_output="$(nvim --version 2>/dev/null | head -n 1)"
nvim_version="${nvim_version_output#NVIM v}"
nvim_major="${nvim_version%%.*}"
nvim_remainder="${nvim_version#*.}"
nvim_minor="${nvim_remainder%%.*}"
if [[ "$nvim_major" =~ ^[0-9]+$ && "$nvim_minor" =~ ^[0-9]+$ ]] \
  && (( nvim_major > 0 || (nvim_major == 0 && nvim_minor >= 12) )); then
  pass "Neovim is $nvim_version (required 0.12+)"
else
  fail "Neovim 0.12+ required, got '${nvim_version_output:-missing}'"
fi

if ! verify_neovim_plugins_restored "$DOTFILES_DIR/config/nvim/lazy-lock.json"; then
  fail "Neovim plugins are not fully restored"
elif ! verify_neovim_parsers_restored; then
  fail "Tree-sitter parsers are not fully restored"
elif verify_neovim_config_sandboxed "$DOTFILES_DIR/config/nvim"; then
  pass "Neovim config starts in an isolated, network-blocked data directory"
else
  fail "Neovim isolated headless startup"
fi

if [[ "$FAILURES" -eq 0 ]]; then
  printf 'Doctor passed for %s.\n' "$PROFILE"
  exit 0
fi

printf 'Doctor found %d failure(s).\n' "$FAILURES" >&2
exit 1
