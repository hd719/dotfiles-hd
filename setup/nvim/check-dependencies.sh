#!/usr/bin/env bash
# Stop on command errors (-e), unset variables (-u), and failures hidden inside
# pipelines (pipefail).
set -euo pipefail

# This is a read-only doctor: inspect the caller's real environment, report
# every gap, then fail once at the end if anything is missing.

# Print the command reference literally; quoting `EOF` prevents Bash from
# expanding examples or variables inside this help text.
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

# `${1:-full}` uses the first argument, or `full` when none is supplied.
PROFILE="${1:-full}"

# Exit status 2 means the command was invoked incorrectly.
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

# Locate uv's managed bin directory for diagnostics only. Do not add it to PATH:
# this check must see the same commands that a normal Neovim process inherits.
UV_BIN=""
if command -v uv >/dev/null 2>&1; then
  UV_BIN="$(uv tool dir --bin 2>/dev/null || true)"
fi

# Accumulate failures so one run shows every dependency that needs attention.
missing=0

# Keep result messages consistent. A failure increments the shared counter
# instead of exiting immediately, which lets the doctor finish every check.
ok() {
  echo "ok: $1"
}

fail() {
  echo "missing: $1" >&2
  missing=$((missing + 1))
}

# Test for a usable capability, not package ownership; any command on PATH counts.
check_command() {
  local label="$1"
  local command_name="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    ok "$label ($(command -v "$command_name"))"
  else
    fail "$label ($command_name)"
  fi
}

# Some hosts use different names for the same capability. `shift` removes the
# display label, leaving only the candidate command names in "$@".
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

# Finding `nvim` is not enough; parse its first version line to enforce the
# minimum version required by this configuration.
check_neovim() {
  local version_line version major minor rest

  if ! command -v nvim >/dev/null 2>&1; then
    fail "Neovim 0.12+ (nvim)"
    return
  fi

  # These parameter expansions remove the text around MAJOR.MINOR. The numeric
  # comparison accepts Neovim 0.12+ as well as any future major version.
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

# Tree-sitter also has a minimum supported version, so verify more than command
# availability before reporting success.
check_tree_sitter() {
  local version_line version major minor patch

  if ! command -v tree-sitter >/dev/null 2>&1; then
    fail "Tree-sitter CLI 0.26.1+ (tree-sitter)"
    return
  fi

  # The regular expression stores major, minor, and patch in Bash's
  # BASH_REMATCH array so the pieces can be compared as integers.
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

# Configured JavaScript language servers require Node 18 or newer. Report an
# old host runtime instead of accepting commands that will fail when started.
check_node() {
  local version_line version major

  if ! command -v node >/dev/null 2>&1; then
    fail "Node.js 18+ (node)"
    return
  fi

  version_line="$(node --version 2>/dev/null || true)"
  version="${version_line#v}"
  major="${version%%.*}"
  if [[ "$major" =~ ^[0-9]+$ ]] && ((10#$major >= 18)); then
    ok "Node.js $version_line ($(command -v node))"
  else
    fail "Node.js 18+ (found: ${version_line:-unknown})"
  fi
}

check_pnpm() {
  local version major

  if ! command -v pnpm >/dev/null 2>&1; then
    fail "pnpm 11+"
    return
  fi

  version="$(pnpm --version 2>/dev/null || true)"
  major="${version%%.*}"
  if [[ "$major" =~ ^[0-9]+$ ]] && ((10#$major >= 11)); then
    ok "pnpm $version ($(command -v pnpm))"
  else
    fail "pnpm 11+ (found: ${version:-broken command})"
  fi
}

# Go 1.26 development uses the current gopls line. An older distro binary can
# exist on PATH yet still be too stale for the configured language features.
check_gopls() {
  local version_line major minor patch

  if ! command -v gopls >/dev/null 2>&1; then
    fail "gopls 0.23.0+ (gopls)"
    return
  fi

  version_line="$(gopls version 2>/dev/null || true)"
  if [[ "$version_line" =~ gopls[[:space:]]+v?([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    major="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    patch="${BASH_REMATCH[3]}"
    if ((10#$major > 0 || 10#$minor > 23 || (10#$minor == 23 && 10#$patch >= 0))); then
      ok "gopls v$major.$minor.$patch ($(command -v gopls))"
      return
    fi
  fi

  fail "gopls 0.23.0+ (found: ${version_line:-unknown})"
}

# The Lua config explicitly knows this private fallback path, so it is valid
# even when `graphql-lsp` is not globally available on PATH.
check_graphql_lsp() {
  local fixed="$HOME/.local/graphql-lsp/bin/graphql-lsp"
  local resolved version

  if command -v graphql-lsp >/dev/null 2>&1; then
    resolved="$(command -v graphql-lsp)"
  elif [[ -x "$fixed" ]]; then
    resolved="$fixed"
  else
    fail "GraphQL language server (graphql-lsp)"
    return
  fi

  if ! version="$("$resolved" --version 2>/dev/null)" || [[ -z "$version" ]]; then
    fail "GraphQL language server (broken command: $resolved)"
    return
  fi

  version="${version%%$'\n'*}"
  if [[ "$resolved" == "$fixed" && "$version" != "3.5.0" ]]; then
    fail "GraphQL language server 3.5.0 (found: $version)"
    return
  fi

  ok "GraphQL language server $version ($resolved)"
}

# Explain when a pinned uv tool exists but PATH misses or shadows it. Never
# patch PATH here, because doing so would hide a persistent shell setup gap.
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

# The mdformat version alone is insufficient: these exact extensions preserve
# GFM, frontmatter, footnotes, alerts, and Obsidian wikilinks.
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

# Ruff must be both the pinned version and the command that the caller's PATH
# resolves; reuse the same shadowing guidance as mdformat when either drifts.
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

# Core checks run for every profile.
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

# Full includes core and adds language-server and formatter checks.
if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]]; then
  check_node
  check_pnpm
  check_command "Bash language server" bash-language-server
  check_gopls
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

# Desktop includes full and adds terminal image/PDF preview requirements.
if [[ "$PROFILE" == "desktop" ]]; then
  check_command "ImageMagick" magick
  check_command "Ghostscript" gs
  check_any_command "system file opener" open xdg-open wslview
fi

# Convert the collected count into one nonzero exit status for scripts and CI.
if ((missing > 0)); then
  echo "Neovim dependency check failed: $missing missing requirement(s)." >&2
  exit 1
fi

echo "Neovim dependency check passed."
