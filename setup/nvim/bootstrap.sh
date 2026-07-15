#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat <<'EOF'
Usage: bootstrap.sh [core|full|desktop]

Profiles are cumulative; choose one:
  core     Editor, search, Tree-sitter, LazyGit, and locked plugins.
           Use on a minimal headless or SSH server.
  full     Core plus configured language servers and formatters. (default)
           Use on a developer machine or cloud development host.
  desktop  Full plus image/PDF preview tools and a system file opener.
           Use with Ghostty or another Kitty-graphics-compatible terminal.

Choose one per machine; using desktop on a laptop and core on a server is normal.
Running desktop already includes full and core. You can safely rerun later with
a higher profile; the bootstrap only fills missing capabilities.
EOF
}

PROFILE="${1:-full}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

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

export HOMEBREW_NO_AUTO_UPDATE=1

HOST_NODE_PATH=""
HOST_NODE_VERSION=""
HOST_BREW_NODE_FORMULA=""
NODE_RESTORE_PENDING=0

have() {
  command -v "$1" >/dev/null 2>&1
}

capture_host_node() {
  local brew_prefix node_link relative

  if ! have node; then
    return
  fi

  HOST_NODE_PATH="$(command -v node)"
  HOST_NODE_VERSION="$(node --version 2>/dev/null || true)"

  if ! have brew; then
    return
  fi

  brew_prefix="$(brew --prefix)"
  if [[ "$HOST_NODE_PATH" != "$brew_prefix/bin/node" ]]; then
    return
  fi

  node_link="$(readlink "$HOST_NODE_PATH" 2>/dev/null || true)"
  case "$node_link" in
    ../Cellar/*/*/bin/node)
      relative="${node_link#../Cellar/}"
      HOST_BREW_NODE_FORMULA="${relative%%/*}"
      ;;
  esac
}

prepare_homebrew_node_dependency() {
  local outdated_node=""

  if [[ -z "$HOST_NODE_PATH" ]] || ! have brew; then
    return
  fi

  if [[ "$HOST_BREW_NODE_FORMULA" == "node" ]]; then
    if ! outdated_node="$(brew outdated --quiet node 2>/dev/null)"; then
      echo "cannot verify whether the active Homebrew node formula is current" >&2
      return 1
    fi
    if [[ -n "$outdated_node" ]]; then
      echo "cannot safely install language servers while the active Homebrew node formula is outdated" >&2
      echo "upgrade Node intentionally, or activate a versioned/external Node, then rerun bootstrap" >&2
      return 1
    fi
  fi

  if brew list --versions node >/dev/null 2>&1; then
    return
  fi

  echo "installing Homebrew Node for language servers without linking it"
  brew install --skip-link --as-dependency node
  hash -r
}

restore_host_node() {
  local brew_prefix current_path current_version

  if [[ -z "$HOST_NODE_PATH" ]]; then
    return
  fi

  hash -r
  current_path="$(command -v node 2>/dev/null || true)"
  current_version="$(node --version 2>/dev/null || true)"
  if [[ "$current_path" == "$HOST_NODE_PATH" && "$current_version" == "$HOST_NODE_VERSION" ]]; then
    return
  fi

  if ! have brew; then
    echo "Node changed during bootstrap and Homebrew is unavailable to restore it" >&2
    return 1
  fi

  brew_prefix="$(brew --prefix)"
  if [[ -n "$HOST_BREW_NODE_FORMULA" ]]; then
    if brew list --versions node >/dev/null 2>&1; then
      brew unlink node >/dev/null
    fi
    brew link --force --overwrite "$HOST_BREW_NODE_FORMULA" >/dev/null
  elif [[ "$HOST_NODE_PATH" != "$brew_prefix/bin/node" ]]; then
    if brew list --versions node >/dev/null 2>&1; then
      brew unlink node >/dev/null
    fi
  else
    echo "Node changed during bootstrap and its original Homebrew formula is unknown" >&2
    return 1
  fi

  hash -r
  current_path="$(command -v node 2>/dev/null || true)"
  current_version="$(node --version 2>/dev/null || true)"
  if [[ "$current_path" != "$HOST_NODE_PATH" || "$current_version" != "$HOST_NODE_VERSION" ]]; then
    echo "Node changed during bootstrap and could not be restored" >&2
    echo "before: $HOST_NODE_PATH ($HOST_NODE_VERSION)" >&2
    echo "after: ${current_path:-missing} (${current_version:-missing})" >&2
    return 1
  fi

  echo "restored host-managed Node: $HOST_NODE_PATH ($HOST_NODE_VERSION)"
}

restore_host_node_on_exit() {
  if ((NODE_RESTORE_PENDING == 1)); then
    restore_host_node || true
  fi
}

ensure_brew_command() {
  local command_name="$1"
  local formula="$2"

  if have "$command_name"; then
    echo "already available: $command_name ($(command -v "$command_name"))"
    return
  fi

  if have brew; then
    echo "installing $formula for $command_name"
    brew install "$formula"
  else
    echo "cannot install $command_name automatically: Homebrew is not available" >&2
  fi
}

vscode_language_servers_available() {
  local command_name

  for command_name in \
    vscode-eslint-language-server \
    vscode-json-language-server \
    vscode-css-language-server \
    vscode-html-language-server
  do
    if ! have "$command_name"; then
      return 1
    fi
  done

  return 0
}

ensure_vscode_language_servers() {
  if vscode_language_servers_available; then
    echo "already available: VSCode language servers"
  elif have brew; then
    echo "installing vscode-langservers-extracted"
    brew install vscode-langservers-extracted
  else
    echo "cannot install VSCode language servers automatically: Homebrew is not available" >&2
  fi
}

ensure_graphql_lsp() {
  local prefix="$HOME/.local/graphql-lsp"
  local package_json="$prefix/lib/node_modules/graphql-language-service-cli/package.json"
  local wanted_version="3.5.0"
  local installed_version=""

  if have graphql-lsp; then
    echo "already available: graphql-lsp ($(command -v graphql-lsp))"
    return
  fi

  if have node && [[ -f "$package_json" ]]; then
    installed_version="$(node -p "require('$package_json').version" 2>/dev/null || true)"
  fi

  if [[ "$installed_version" == "$wanted_version" && -x "$prefix/bin/graphql-lsp" ]]; then
    echo "already available: graphql-lsp $wanted_version ($prefix/bin/graphql-lsp)"
    return
  fi

  if ! have npm; then
    echo "cannot install graphql-lsp: npm is not available" >&2
    return
  fi

  echo "installing graphql-language-service-cli@$wanted_version"
  npm install -g \
    --prefix "$prefix" \
    "graphql-language-service-cli@$wanted_version"
}

ensure_uv_tools() {
  local listing=""
  local ruff_command=""
  local uv_bin=""

  if ! have uv; then
    echo "cannot install mdformat or ruff: uv is not available" >&2
    return
  fi

  uv_bin="$(uv tool dir --bin)"
  listing="$(uv tool list --show-with --show-version-specifiers 2>/dev/null || true)"

  if printf '%s\n' "$listing" | grep -q '^mdformat v1\.0\.0 ' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-gfm==1\.0\.0' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-frontmatter==2\.1\.2' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-footnote==0\.1\.3' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-gfm-alerts==2\.0\.0' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-wikilink==0\.3\.0'; then
    echo "already available: mdformat 1.0.0 with Obsidian-safe extensions"
  else
    uv tool install --force 'mdformat==1.0.0' \
      --with 'mdformat-gfm==1.0.0' \
      --with 'mdformat-frontmatter==2.1.2' \
      --with 'mdformat-footnote==0.1.3' \
      --with 'mdformat-gfm-alerts==2.0.0' \
      --with 'mdformat-wikilink==0.3.0'
  fi

  if [[ -x "$uv_bin/ruff" ]]; then
    ruff_command="$uv_bin/ruff"
  elif have ruff; then
    ruff_command="$(command -v ruff)"
  fi

  if [[ -n "$ruff_command" && "$("$ruff_command" --version 2>/dev/null || true)" == "ruff 0.15.21" ]]; then
    echo "already available: ruff 0.15.21"
  else
    uv tool install --force 'ruff==0.15.21'
  fi
}

echo "Bootstrapping Neovim ($PROFILE) from $REPO_ROOT"

capture_host_node
if [[ -n "$HOST_NODE_PATH" ]]; then
  NODE_RESTORE_PENDING=1
  trap restore_host_node_on_exit EXIT
fi

ensure_brew_command nvim neovim
ensure_brew_command git git
ensure_brew_command rg ripgrep
ensure_brew_command fd fd
ensure_brew_command fzf fzf
ensure_brew_command tree-sitter tree-sitter-cli
ensure_brew_command lazygit lazygit
ensure_brew_command curl curl

if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]]; then
  ensure_brew_command uv uv
  if have brew \
    && { ! have bash-language-server \
      || ! have vtsls \
      || ! vscode_language_servers_available; }; then
    prepare_homebrew_node_dependency
  fi
  ensure_brew_command bash-language-server bash-language-server
  ensure_brew_command gopls gopls
  if have gofmt; then
    echo "already available: gofmt ($(command -v gofmt))"
  else
    echo "host-managed prerequisite missing: gofmt (install the approved Go toolchain)" >&2
  fi
  ensure_brew_command lua-language-server lua-language-server
  ensure_brew_command stylua stylua
  ensure_brew_command vtsls vtsls
  ensure_vscode_language_servers
fi

if [[ "$PROFILE" == "desktop" ]]; then
  ensure_brew_command magick imagemagick
  ensure_brew_command gs ghostscript
fi

restore_host_node
NODE_RESTORE_PENDING=0
trap - EXIT

if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]]; then
  ensure_uv_tools
  ensure_graphql_lsp
fi

"$SCRIPT_DIR/check-dependencies.sh" "$PROFILE"

LOCKFILE="$REPO_ROOT/config/nvim/lazy-lock.json"
LOCKFILE_BACKUP="$(mktemp "${TMPDIR:-/tmp}/nvim-lazy-lock.XXXXXX")"

restore_lockfile() {
  if [[ -n "${LOCKFILE_BACKUP:-}" && -f "$LOCKFILE_BACKUP" ]]; then
    cp "$LOCKFILE_BACKUP" "$LOCKFILE"
    rm -f "$LOCKFILE_BACKUP"
  fi
}

if ! cp "$LOCKFILE" "$LOCKFILE_BACKUP"; then
  rm -f "$LOCKFILE_BACKUP"
  exit 1
fi

trap restore_lockfile EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

echo "restoring locked Neovim plugins"
DOTFILES_NVIM_BOOTSTRAP=1 \
  XDG_CONFIG_HOME="$REPO_ROOT/config" \
  nvim --headless '+Lazy! restore' +qa

# Lazy may rewrite the lock while installing missing plugins. Put the committed
# pins back before a second restore so every checkout converges to those pins.
cp "$LOCKFILE_BACKUP" "$LOCKFILE"
DOTFILES_NVIM_BOOTSTRAP=1 \
  XDG_CONFIG_HOME="$REPO_ROOT/config" \
  nvim --headless '+Lazy! restore' +qa

if ! cmp -s "$LOCKFILE_BACKUP" "$LOCKFILE"; then
  echo "Neovim plugin restore changed $LOCKFILE" >&2
  exit 1
fi

restore_lockfile
LOCKFILE_BACKUP=""
trap - EXIT HUP INT TERM
