#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
MISE_BIN="${DOTFILES_MISE_BIN:-$HOME/.local/bin/mise}"
MISE_SOURCE="$SCRIPT_DIR/mise.toml"
MISE_TARGET="$HOME/.config/mise/config.toml"
NVIM_SOURCE="$ROOT_DIR/config/nvim"
NVIM_TARGET="$HOME/.config/nvim"
GRAPHQL_SOURCE="$SCRIPT_DIR/bin/graphql-lsp"
GRAPHQL_TARGET="$HOME/.local/graphql-lsp/bin/graphql-lsp"

print_usage() {
  cat <<'EOF'
Usage: setup-neovim.sh [--check]

Install or repair the Ubuntu Neovim daily-driver setup.

Options:
  --check   Validate the existing setup without installing anything.
  -h, --help
            Show this help.
EOF
}

log() {
  printf '\n==> %s\n' "$1"
}

backup_path() {
  local target="$1"
  local backup
  local suffix=0

  backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"

  while [[ -e "$backup" || -L "$backup" ]]; do
    suffix=$((suffix + 1))
    backup="${target}.backup.$(date +%Y%m%d-%H%M%S).$suffix"
  done

  mv "$target" "$backup"
  printf 'Backed up %s to %s\n' "$target" "$backup"
}

safe_link() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_path "$target"
  fi

  ln -s "$source" "$target"
  printf 'Linked %s -> %s\n' "$target" "$source"
}

ensure_directory() {
  local directory="$1"

  if [[ -L "$directory" || (-e "$directory" && ! -d "$directory") ]]; then
    backup_path "$directory"
  fi
  mkdir -p "$directory"
}

require_link() {
  local source="$1"
  local target="$2"

  [[ -L "$target" && "$(readlink "$target")" == "$source" ]] || {
    printf 'Expected %s to link to %s.\n' "$target" "$source" >&2
    return 1
  }
}

install_mise() {
  if [[ -x "$MISE_BIN" ]]; then
    log "Updating mise"
    "$MISE_BIN" self-update -y
    return
  fi

  log "Installing mise"
  mkdir -p "$(dirname "$MISE_BIN")"
  curl -fsSL https://mise.run | sh
  [[ -x "$MISE_BIN" ]] || {
    printf 'mise was not installed at %s.\n' "$MISE_BIN" >&2
    exit 1
  }
}

link_configs() {
  log "Linking mise and Neovim configuration"
  ensure_directory "$HOME/.config/mise"
  safe_link "$MISE_SOURCE" "$MISE_TARGET"
  safe_link "$NVIM_SOURCE" "$NVIM_TARGET"
  safe_link "$GRAPHQL_SOURCE" "$GRAPHQL_TARGET"
}

install_tools() {
  log "Installing pinned runtimes"
  "$MISE_BIN" trust "$MISE_TARGET"
  "$MISE_BIN" install node@24.18.0 go@1.26.5 python@3.14.6 bun@1.3.14

  log "Installing pinned editor tools"
  "$MISE_BIN" install
  "$MISE_BIN" reshim

  log "Installing pinned Markdown formatter"
  "$MISE_BIN" exec -- uv tool install --force \
    'mdformat==1.0.0' \
    --with 'mdformat-gfm==1.0.0' \
    --with 'mdformat-frontmatter==2.1.2' \
    --with 'mdformat-footnote==0.1.3' \
    --with 'mdformat-gfm-alerts==2.0.0' \
    --with 'mdformat-wikilink==0.3.0'
}

restore_plugins() {
  log "Restoring locked Neovim plugins"
  "$MISE_BIN" exec -- nvim --headless "+Lazy! restore" +qa
}

require_mise_command() {
  local command_name="$1"
  local command_path

  command_path="$("$MISE_BIN" which "$command_name" 2>/dev/null)" || {
    printf 'Missing Neovim dependency: %s\n' "$command_name" >&2
    return 1
  }
  [[ -x "$command_path" ]] || {
    printf 'Neovim dependency is not executable: %s\n' "$command_name" >&2
    return 1
  }
}

require_system_command() {
  local command_name="$1"

  command -v "$command_name" >/dev/null 2>&1 || {
    printf 'Missing system dependency: %s\n' "$command_name" >&2
    return 1
  }
}

check_daily_driver() {
  local command_name
  local nvim_path
  local mise_commands=(
    bash-language-server
    bun
    fd
    fzf
    go
    gopls
    graphql-lsp
    lazygit
    lua-language-server
    node
    nvim
    pnpm
    python
    rg
    ruff
    shellcheck
    starship
    stylua
    tree-sitter
    uv
    vscode-css-language-server
    vscode-eslint-language-server
    vscode-html-language-server
    vscode-json-language-server
    vtsls
    zoxide
  )
  local system_commands=(gs magick mdformat wl-copy xclip)

  export MISE_AUTO_INSTALL=0
  export MISE_EXEC_AUTO_INSTALL=0
  export MISE_NOT_FOUND_AUTO_INSTALL=0

  [[ -x "$MISE_BIN" ]] || {
    printf 'mise is missing at %s.\n' "$MISE_BIN" >&2
    return 1
  }
  require_link "$MISE_SOURCE" "$MISE_TARGET"
  require_link "$NVIM_SOURCE" "$NVIM_TARGET"
  require_link "$GRAPHQL_SOURCE" "$GRAPHQL_TARGET"

  for command_name in "${mise_commands[@]}"; do
    require_mise_command "$command_name"
  done
  for command_name in "${system_commands[@]}"; do
    require_system_command "$command_name"
  done

  [[ -x "$GRAPHQL_TARGET" ]] || {
    printf 'GraphQL language-server wrapper is not executable.\n' >&2
    return 1
  }

  "$MISE_BIN" current >/dev/null
  nvim_path="$("$MISE_BIN" which nvim)"
  "$nvim_path" --headless \
    "+lua assert(vim.fn.exists(':Lazy') == 2, 'Lazy is unavailable')" +qa
  printf 'Neovim daily-driver check passed.\n'
}

main() {
  local mode="install"

  if (($# > 1)); then
    print_usage >&2
    exit 2
  fi

  if (($# == 1)); then
    case "$1" in
      --check) mode="check" ;;
      -h | --help)
        print_usage
        exit 0
        ;;
      *)
        print_usage >&2
        exit 2
        ;;
    esac
  fi

  export PATH="$HOME/.local/bin:$PATH"

  if [[ "$mode" == "check" ]]; then
    check_daily_driver
    return
  fi

  install_mise
  link_configs
  install_tools
  restore_plugins
  check_daily_driver
}

main "$@"
