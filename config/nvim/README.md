# Neovim

This is a small, personal Neovim config based on Kuncheng Gui's structure and
Hamel's existing Zed muscle memory.

## Requirements

- Neovim 0.12+, ripgrep, fd, fzf, LazyGit, and the Tree-sitter CLI.
- Go: `gopls` and `gofmt`.
- Lua: `lua-language-server` and `stylua`.
- JavaScript and TypeScript: `vtsls` for language intelligence,
  `vscode-eslint-language-server` for project lint rules, and project-local
  `prettier` for formatting.
- Markdown: `mdformat`, installed through `uv` with GFM, frontmatter, footnote,
  alert, and Obsidian-wikilink plugins.
- Python: `ruff`, installed through `uv tool install ruff@latest`.

Install the Markdown formatter with:

```bash
uv tool install 'mdformat==1.0.0' \
  --with mdformat-gfm \
  --with mdformat-frontmatter \
  --with mdformat-footnote \
  --with mdformat-gfm-alerts \
  --with 'mdformat-wikilink==0.3.0'
```

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
- Herdr uses `Ctrl-b` as its prefix, matching Kuncheng's config, so one
  `Escape` reaches Neovim both directly in Ghostty and inside Herdr.
- In a Snacks picker, the first `Escape` leaves its search-input Insert mode;
  the second `Escape` closes the picker.
- Normal-mode `Escape` saves an existing modified file.
- `Ctrl-a` selects the whole file.

## Main Keys

| Key | Action |
| --- | --- |
| `Space f` | Find files |
| `Space /` | Search text |
| `Space h` | Open Oil file browser |
| `Space e` | Open the file-explorer sidebar (Snacks) |
| `Space b` | Pick a buffer |
| `Space d` | Close the current buffer |
| `Space w` / `Space x` | Save / save and quit |
| `Space v` / `Space s` | Split right / down |
| `Ctrl-h/j/k/l` | Focus window left / down / up / right |
| `Space q` | Close the current window |
| `Space t` / `Space T` | Bottom / floating terminal |
| `Space g` | Open LazyGit |
| `Space p` | Format |
| `Space c a` | LSP code action |
| `Space y p/d/f` | Copy file path / working dir / file folder |
| `Space r` | Reload files changed on disk |
| `gd` / `gh` | Definition / hover |
| `H` / `L` | Previous / next buffer |

`Space g` resolves the repository from the current file. In Oil, it resolves
from the directory being viewed, so it does not depend on Neovim's `:pwd`.

The `Space e` file-explorer sidebar is separate from Oil (`Space h`). From the
tree, `Space l` (or `Ctrl-l`) moves focus to the editor, and `Ctrl-h` moves
focus back to the tree. There is no `Space h` for window-left because `Space h`
opens Oil, so the key to return to the tree is `Ctrl-h`. Press `Space e` again
to close the sidebar.

Completion appears automatically. Press `Enter` to accept the selected item.

`Space p` selects a formatter from the current buffer's filetype: `gofmt` for
Go, `stylua` for Lua, project-local Prettier for JavaScript and TypeScript,
`mdformat` for Markdown, and Ruff for Python. Formatting changes the buffer;
use `Space w` to write it to disk. Format-on-save is not enabled yet.

`vtsls` provides JavaScript and TypeScript diagnostics, completion, hover, and
code navigation. The ESLint language server discovers the nearest workspace
`eslint.config.mjs`, so each Cortana Services app or package uses its shared
`@cortana/tooling` profile. ESLint fixes on save remain disabled.
