#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-full}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

case "$PROFILE" in
  core | full | desktop) ;;
  *)
    echo "Usage: $0 [core|full|desktop]" >&2
    exit 2
    ;;
esac

export HOMEBREW_NO_AUTO_UPDATE=1
export PATH="$HOME/.local/bin:$PATH"

have() {
  command -v "$1" >/dev/null 2>&1
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

ensure_vscode_language_servers() {
  local command_name
  local missing_server=0

  for command_name in \
    vscode-eslint-language-server \
    vscode-json-language-server \
    vscode-css-language-server \
    vscode-html-language-server
  do
    if ! have "$command_name"; then
      missing_server=1
    fi
  done

  if ((missing_server == 0)); then
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

  if ! have uv; then
    echo "cannot install mdformat or ruff: uv is not available" >&2
    return
  fi

  export PATH="$(uv tool dir --bin):$PATH"
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

  if have ruff && [[ "$(ruff --version 2>/dev/null || true)" == "ruff 0.15.21" ]]; then
    echo "already available: ruff 0.15.21"
  else
    uv tool install --force 'ruff==0.15.21'
  fi
}

echo "Bootstrapping Neovim ($PROFILE) from $REPO_ROOT"

ensure_brew_command nvim neovim
ensure_brew_command git git
ensure_brew_command rg ripgrep
ensure_brew_command fd fd
ensure_brew_command fzf fzf
ensure_brew_command tree-sitter tree-sitter-cli
ensure_brew_command lazygit lazygit

if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]]; then
  ensure_brew_command uv uv
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
  ensure_uv_tools
  ensure_graphql_lsp
fi

if [[ "$PROFILE" == "desktop" ]]; then
  ensure_brew_command magick imagemagick
  ensure_brew_command gs ghostscript
fi

"$SCRIPT_DIR/check-dependencies.sh" "$PROFILE"

echo "restoring locked Neovim plugins"
XDG_CONFIG_HOME="$REPO_ROOT/config" nvim --headless '+Lazy! restore' +qa
