#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-full}"

case "$PROFILE" in
  core | full | desktop) ;;
  *)
    echo "Usage: $0 [core|full|desktop]" >&2
    exit 2
    ;;
esac

if command -v uv >/dev/null 2>&1; then
  UV_BIN="$(uv tool dir --bin 2>/dev/null || true)"
  if [[ -n "$UV_BIN" ]]; then
    export PATH="$UV_BIN:$PATH"
  fi
fi

missing=0

ok() {
  echo "ok: $1"
}

fail() {
  echo "missing: $1" >&2
  missing=$((missing + 1))
}

check_command() {
  local label="$1"
  local command_name="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    ok "$label ($(command -v "$command_name"))"
  else
    fail "$label ($command_name)"
  fi
}

check_any_command() {
  local label="$1"
  shift
  local command_name

  for command_name in "$@"; do
    if command -v "$command_name" >/dev/null 2>&1; then
      ok "$label ($(command -v "$command_name"))"
      return
    fi
  done

  fail "$label ($*)"
}

check_neovim() {
  local version_line version major minor rest

  if ! command -v nvim >/dev/null 2>&1; then
    fail "Neovim 0.12+ (nvim)"
    return
  fi

  version_line="$(nvim --version | sed -n '1p')"
  version="${version_line#NVIM v}"
  version="${version%% *}"
  major="${version%%.*}"
  rest="${version#*.}"
  minor="${rest%%.*}"

  if [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] \
    && ((major > 0 || minor >= 12)); then
    ok "$version_line"
  else
    fail "Neovim 0.12+ (found: $version_line)"
  fi
}

check_graphql_lsp() {
  local fixed="$HOME/.local/graphql-lsp/bin/graphql-lsp"

  if command -v graphql-lsp >/dev/null 2>&1; then
    ok "GraphQL language server ($(command -v graphql-lsp))"
  elif [[ -x "$fixed" ]]; then
    ok "GraphQL language server ($fixed)"
  else
    fail "GraphQL language server (graphql-lsp)"
  fi
}

check_mdformat_extensions() {
  local listing

  if ! command -v uv >/dev/null 2>&1 || ! command -v mdformat >/dev/null 2>&1; then
    fail "mdformat 1.0.0 with Obsidian-safe extensions"
    return
  fi

  listing="$(uv tool list --show-with --show-version-specifiers 2>/dev/null || true)"
  if printf '%s\n' "$listing" | grep -q '^mdformat v1\.0\.0 ' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-gfm==1\.0\.0' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-frontmatter==2\.1\.2' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-footnote==0\.1\.3' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-gfm-alerts==2\.0\.0' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-wikilink==0\.3\.0'; then
    ok "mdformat 1.0.0 with Obsidian-safe extensions"
  else
    fail "mdformat 1.0.0 with Obsidian-safe extensions"
  fi
}

echo "Neovim dependency check ($PROFILE)"

check_neovim
check_command "Git" git
check_command "ripgrep" rg
check_command "fd" fd
check_command "fzf" fzf
check_command "Tree-sitter CLI" tree-sitter
check_command "LazyGit" lazygit
check_command "C compiler" cc
check_any_command "download client" curl wget
check_command "unzip" unzip
check_any_command "tar" tar gtar
check_command "gzip" gzip

if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]]; then
  check_command "Node.js" node
  check_command "npm" npm
  check_command "Bash language server" bash-language-server
  check_command "Go language server" gopls
  check_command "Go formatter" gofmt
  check_command "Lua language server" lua-language-server
  check_command "Lua formatter" stylua
  check_command "TypeScript language server" vtsls
  check_command "ESLint language server" vscode-eslint-language-server
  check_command "JSON language server" vscode-json-language-server
  check_command "CSS language server" vscode-css-language-server
  check_command "HTML language server" vscode-html-language-server
  check_graphql_lsp
  check_command "uv" uv
  check_mdformat_extensions
  check_command "Python formatter" ruff
  echo "project: Prettier stays project-local and is not installed globally"
fi

if [[ "$PROFILE" == "desktop" ]]; then
  check_command "ImageMagick" magick
  check_command "Ghostscript" gs
  check_any_command "system file opener" open xdg-open wslview
fi

if ((missing > 0)); then
  echo "Neovim dependency check failed: $missing missing requirement(s)." >&2
  exit 1
fi

echo "Neovim dependency check passed."
