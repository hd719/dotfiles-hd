# Neovim

This is a small, personal Neovim config based on Kuncheng Gui's structure and
Hamel's existing Zed muscle memory.

## Requirements

- Neovim 0.12+, ripgrep, fd, fzf, LazyGit, and the Tree-sitter CLI.
- Go: `gopls` and `gofmt`.
- Lua: `lua-language-server` and `stylua`.

## Safety Net

- `nvim --clean` starts Neovim without this config.
- `:Lazy` shows installed plugins and their status.
- `:checkhealth` runs Neovim's diagnostics.
- `:LspInfo` shows language-server status.
- `:ConformInfo` shows formatter status.
- `:TSStatus` shows Tree-sitter parsers.

For a calm first run, open this file with `nvim ~/.config/nvim/README.md`, then
press `Space` and pause to see the available commands.

## Curriculum and Learning Log

- [CURRICULUM.md](CURRICULUM.md) tracks core sub-lessons and optional deep dives
  with checkboxes.
- [LEARNING_LOG.md](LEARNING_LOG.md) is the required append-only session record.

Every agent teaching Neovim must read and update both files.

## Key Differences From Normal Vim

- `i` inserts after the cursor and `a` inserts before it, matching Zed.
- `Escape` is the primary mode-exit key. Shortcat currently captures
  `Ctrl-Space` before it reaches Neovim.
- Normal-mode `Escape` saves an existing modified file.
- `Ctrl-a` selects the whole file.

## Main Keys

| Key | Action |
| --- | --- |
| `Space f` | Find files |
| `Space /` | Search text |
| `Space h` | Open Oil file browser |
| `Space b` | Pick a buffer |
| `Space d` | Close the current buffer |
| `Space v` / `Space s` | Split right / down |
| `Space q` | Close the current window |
| `Space t` / `Space T` | Bottom / floating terminal |
| `Space g` | Open LazyGit |
| `Space p` | Format |
| `Space c a` | LSP code action |
| `gd` / `gh` | Definition / hover |
| `H` / `L` | Previous / next buffer |

Completion appears automatically. Press `Enter` to accept the selected item.
