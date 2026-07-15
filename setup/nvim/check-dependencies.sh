#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat <<'EOF'
Usage: check-dependencies.sh [core|full|desktop]

Profiles are cumulative; choose the same one used for bootstrap:
  core     Verify the editor, search, Tree-sitter, LazyGit, and plugin base.
  full     Verify core plus language servers and formatters. (default)
  desktop  Verify full plus image/PDF previews and a system file opener.

Running the desktop check already includes the full and core checks.
EOF
}

PROFILE="${1:-full}"

if (($# > 1)); then
  print_usage >&2
  exit 2
fi

case "$PROFILE" in
  core | full | desktop) ;;
  -h | --help)
    print_usage
    exit 0
    ;;
  *)
    print_usage >&2
    exit 2
    ;;
esac

UV_BIN=""
if command -v uv >/dev/null 2>&1; then
  UV_BIN="$(uv tool dir --bin 2>/dev/null || true)"
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

check_tree_sitter() {
  local version_line version major minor patch

  if ! command -v tree-sitter >/dev/null 2>&1; then
    fail "Tree-sitter CLI 0.26.1+ (tree-sitter)"
    return
  fi

  version_line="$(tree-sitter --version 2>/dev/null || true)"
  version="${version_line#tree-sitter }"
  version="${version%% *}"

  if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    major="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    patch="${BASH_REMATCH[3]}"

    if ((major > 0 || minor > 26 || (minor == 26 && patch >= 1))); then
      ok "$version_line"
      return
    fi
  fi

  fail "Tree-sitter CLI 0.26.1+ (found: ${version_line:-unknown})"
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

print_uv_path_guidance() {
  local command_name="$1"
  local resolved="$2"
  local pinned

  if [[ -z "$UV_BIN" ]]; then
    return
  fi

  pinned="$UV_BIN/$command_name"
  if [[ ! -x "$pinned" ]]; then
    return
  fi

  if [[ -z "$resolved" ]]; then
    printf 'path: %s exists but is not reachable through the caller PATH.\n' "$pinned" >&2
  elif [[ "$resolved" != "$pinned" ]]; then
    printf 'path: %s shadows the pinned UV tool at %s.\n' "$resolved" "$pinned" >&2
  else
    return
  fi

  printf 'path: Put %s first: export PATH="%s:$PATH"\n' "$UV_BIN" "$UV_BIN" >&2
  echo "path: Persist that ordering through the machine-approved shell setup." >&2
}

check_mdformat_extensions() {
  local command_path version version_line

  command_path="$(command -v mdformat 2>/dev/null || true)"
  if [[ -z "$command_path" ]]; then
    fail "mdformat 1.0.0 with Obsidian-safe extensions"
    print_uv_path_guidance mdformat ""
    return
  fi

  version_line="$("$command_path" --version 2>/dev/null || true)"
  version="${version_line#mdformat }"
  version="${version%% *}"
  if [[ "$version" == "1.0.0" \
    && "$version_line" == *"mdformat-gfm 1.0.0"* \
    && "$version_line" == *"mdformat_frontmatter 2.1.2"* \
    && "$version_line" == *"mdformat_footnote 0.1.3"* \
    && "$version_line" == *"mdformat_gfm_alerts 2.0.0"* \
    && "$version_line" == *"mdformat_wikilink 0.3.0"* ]]; then
    ok "mdformat 1.0.0 with Obsidian-safe extensions ($command_path)"
  else
    fail "mdformat 1.0.0 with Obsidian-safe extensions (found: ${version_line:-unknown}; path: $command_path)"
    print_uv_path_guidance mdformat "$command_path"
  fi
}

check_ruff() {
  local command_path version_line

  command_path="$(command -v ruff 2>/dev/null || true)"
  if [[ -z "$command_path" ]]; then
    fail "Ruff 0.15.21 (ruff)"
    print_uv_path_guidance ruff ""
    return
  fi

  version_line="$("$command_path" --version 2>/dev/null || true)"
  if [[ "$version_line" == "ruff 0.15.21" ]]; then
    ok "Ruff 0.15.21 ($command_path)"
  else
    fail "Ruff 0.15.21 (found: ${version_line:-unknown}; path: $command_path)"
    print_uv_path_guidance ruff "$command_path"
  fi
}

echo "Neovim dependency check ($PROFILE)"

check_neovim
check_command "Git" git
check_command "ripgrep" rg
check_command "fd" fd
check_command "fzf" fzf
check_tree_sitter
check_command "LazyGit" lazygit
check_command "C compiler" cc
check_command "curl" curl
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
  check_ruff
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
