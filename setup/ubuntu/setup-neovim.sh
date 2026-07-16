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
LAZY_REPOSITORY="https://github.com/folke/lazy.nvim.git"
TREE_SITTER_LANGUAGES=(
  bash ecma go gomod gosum gowork graphql javascript json jsx lua markdown
  markdown_inline python query toml tsx typescript vim vimdoc yaml
)
TREE_SITTER_PARSERS=(
  bash go gomod gosum gowork graphql javascript json lua markdown
  markdown_inline python query toml tsx typescript vim vimdoc yaml
)

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

locked_plugin_commit() {
  local plugin="$1"

  sed -n "s/^  \"${plugin}\":.*\"commit\": \"\([^\"]*\)\".*/\1/p" \
    "$NVIM_SOURCE/lazy-lock.json"
}

pin_lazy_manager() {
  local lazy_commit lazy_dir nvim_data

  lazy_commit="$(locked_plugin_commit lazy.nvim)"
  [[ -n "$lazy_commit" ]] || {
    printf 'The Neovim lockfile has no lazy.nvim commit.\n' >&2
    return 1
  }

  nvim_data="$(
    "$MISE_BIN" exec -- nvim --clean --headless \
      "+lua io.write(vim.fn.stdpath('data'))" +qa
  )"
  [[ -n "$nvim_data" ]] || {
    printf 'Neovim returned an empty data directory.\n' >&2
    return 1
  }

  lazy_dir="$nvim_data/lazy/lazy.nvim"
  if [[ ! -d "$lazy_dir/.git" ]]; then
    rm -rf -- "$lazy_dir"
    mkdir -p "$(dirname "$lazy_dir")"
    git clone --filter=blob:none --depth=1 --no-checkout \
      "$LAZY_REPOSITORY" "$lazy_dir"
  fi
  if ! git -C "$lazy_dir" cat-file -e "${lazy_commit}^{commit}" 2>/dev/null; then
    git -C "$lazy_dir" fetch --depth=1 origin "$lazy_commit"
  fi
  git -C "$lazy_dir" checkout --detach "$lazy_commit"
}

install_tree_sitter_parsers() {
  local language
  local lua_languages=""

  for language in "${TREE_SITTER_LANGUAGES[@]}"; do
    [[ -z "$lua_languages" ]] || lua_languages+=", "
    lua_languages+="'$language'"
  done

  log "Installing Tree-sitter parsers"
  "$MISE_BIN" exec -- nvim --headless \
    "+lua local parsers = { $lua_languages }; assert(require('nvim-treesitter').install(parsers):wait(), 'Tree-sitter parser installation failed')" \
    +qa
}

require_neovim_state() {
  local nvim_data="$1"
  local actual_commit expected_commit language parser plugin
  local plugin_count=0

  [[ -f "$NVIM_SOURCE/lazy-lock.json" ]] || {
    printf 'Missing Neovim plugin lockfile: %s\n' "$NVIM_SOURCE/lazy-lock.json" >&2
    return 1
  }

  while IFS=$'\t' read -r plugin expected_commit; do
    [[ -n "$plugin" ]] || continue
    plugin_count=$((plugin_count + 1))
    [[ -d "$nvim_data/lazy/$plugin" ]] || {
      printf 'Missing locked Neovim plugin: %s\n' "$plugin" >&2
      return 1
    }
    actual_commit="$(git -C "$nvim_data/lazy/$plugin" rev-parse HEAD 2>/dev/null)" || {
      printf 'Cannot read the installed Neovim plugin commit: %s\n' "$plugin" >&2
      return 1
    }
    [[ "$actual_commit" == "$expected_commit" ]] || {
      printf 'Neovim plugin is not at its locked commit: %s\n' "$plugin" >&2
      return 1
    }
  done < <(
    sed -n 's/^  "\([^"]*\)":.*"commit": "\([^"]*\)".*/\1\t\2/p' \
      "$NVIM_SOURCE/lazy-lock.json"
  )

  ((plugin_count > 0)) || {
    printf 'Neovim plugin lockfile contains no plugins.\n' >&2
    return 1
  }

  for parser in "${TREE_SITTER_PARSERS[@]}"; do
    [[ -f "$nvim_data/site/parser/$parser.so" ]] || {
      printf 'Missing Tree-sitter parser: %s\n' "$parser" >&2
      return 1
    }
  done
  for language in "${TREE_SITTER_LANGUAGES[@]}"; do
    [[ -d "$nvim_data/site/queries/$language" ]] || {
      printf 'Missing Tree-sitter queries: %s\n' "$language" >&2
      return 1
    }
  done
}

smoke_tree_sitter() {
  local nvim_path="$1"
  local parser
  local lua_parsers=""

  for parser in "${TREE_SITTER_PARSERS[@]}"; do
    [[ -z "$lua_parsers" ]] || lua_parsers+=", "
    lua_parsers+="'$parser'"
  done

  NVIM_LOG_FILE=/dev/null "$nvim_path" --clean --headless -i NONE \
    "+lua local ok, err = xpcall(function() vim.opt.runtimepath:prepend(vim.fn.stdpath('data') .. '/site'); local parsers = { $lua_parsers }; for _, lang in ipairs(parsers) do local loaded, parser = pcall(vim.treesitter.get_string_parser, '', lang); assert(loaded, 'cannot load parser: ' .. lang .. ': ' .. tostring(parser)); local parsed, parse_err = pcall(function() parser:parse() end); assert(parsed, 'cannot parse with: ' .. lang .. ': ' .. tostring(parse_err)); assert(vim.treesitter.query.get(lang, 'highlights'), 'cannot load highlights query: ' .. lang) end end, debug.traceback); if not ok then io.stderr:write('Tree-sitter parser validation failed: ', tostring(err), '\n'); vim.cmd('cquit 1') else vim.cmd('qa!') end"
}

smoke_neovim_config() {
  local nvim_path="$1"

  DOTFILES_NVIM_SMOKE_INIT="$NVIM_SOURCE/init.lua" NVIM_LOG_FILE=/dev/null \
    "$nvim_path" --headless -u NONE -i NONE \
    "+lua local ok, err = xpcall(function() local init = vim.env.DOTFILES_NVIM_SMOKE_INIT; vim.go.loadplugins = true; vim.opt.runtimepath:prepend(vim.fs.dirname(init)); dofile(init); assert(vim.fn.exists(':Lazy') == 2, 'Lazy is unavailable') end, debug.traceback); if not ok then io.stderr:write('Neovim config validation failed: ', tostring(err), '\n'); vim.cmd('cquit 1') else vim.cmd('qa!') end"
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
  local nvim_data
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
  local system_commands=(git gs magick mdformat wl-copy xclip)

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
  "$nvim_path" --clean --headless \
    "+lua assert(vim.fn.has('nvim-0.12') == 1, 'Neovim 0.12+ is required')" +qa
  nvim_data="$(
    "$nvim_path" --clean --headless \
      "+lua io.write(vim.fn.stdpath('data'))" +qa
  )"
  [[ -n "$nvim_data" ]] || {
    printf 'Neovim returned an empty data directory.\n' >&2
    return 1
  }
  require_neovim_state "$nvim_data"
  smoke_tree_sitter "$nvim_path"
  smoke_neovim_config "$nvim_path"
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
  pin_lazy_manager
  restore_plugins
  install_tree_sitter_parsers
  check_daily_driver
}

main "$@"
