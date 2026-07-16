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
- Python: `ruff`, pinned through `uv`.
- GraphQL: `graphql-lsp` (from `graphql-language-service-cli`), installed to a
  fixed prefix and referenced by absolute path. Schema-aware features need a
  `graphql-config` (e.g. `graphql.config.ts`) in the project.
- JSON, CSS, and HTML: `jsonls`, `cssls`, and `html` from
  `vscode-langservers-extracted` (already installed for ESLint); JSON schemas
  come from `SchemaStore.nvim`.
- Shell: `bash-language-server` for shell-script diagnostics and completion.
- Images and PDFs: ImageMagick (`magick`) converts supported files and
  Ghostscript (`gs`) renders PDF pages through Snacks inside Ghostty.
- Editing: `mini.pairs` auto-closes brackets and quotes; `mini.surround` adds,
  changes, and deletes surrounding pairs with a `gs` prefix.

Install the Markdown formatter with:

```bash
uv tool install 'mdformat==1.0.0' \
  --with 'mdformat-gfm==1.0.0' \
  --with 'mdformat-frontmatter==2.1.2' \
  --with 'mdformat-footnote==0.1.3' \
  --with 'mdformat-gfm-alerts==2.0.0' \
  --with 'mdformat-wikilink==0.3.0'

uv tool install 'ruff==0.15.21'
```

Install the GraphQL language server (no Homebrew formula) to a fixed,
node-version-independent prefix that this config references by absolute path:

```bash
GRAPHQL_LSP_HOME="$HOME/.local/graphql-lsp"
mkdir -p "$GRAPHQL_LSP_HOME/bin"
PATH="$GRAPHQL_LSP_HOME/bin:$PATH" PNPM_HOME="$GRAPHQL_LSP_HOME" \
  MISE_NO_CONFIG=1 mise exec node@24.18.0 pnpm@11.2.2 -- \
  pnpm add --global --global-dir "$GRAPHQL_LSP_HOME/global" \
  'graphql-language-service-cli@3.5.0'
MISE_NO_CONFIG=1 mise exec node@24.18.0 -- \
  "$GRAPHQL_LSP_HOME/bin/graphql-lsp" --version | grep -Fx '3.5.0' && \
  printf '%s\n' 'graphql-language-service-cli@3.5.0 via pnpm@11.2.2' \
    > "$GRAPHQL_LSP_HOME/.pnpm-managed-version"
```

## Safety Net

- `nvim --clean` starts Neovim without this config.
- `:Lazy` shows installed plugins and their status.
- `:checkhealth` runs Neovim's diagnostics.
- `:checkhealth snacks` verifies image tools and terminal graphics support.
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
- Normal-mode `Escape` auto-saves a named file only when every unsaved change
  came from Insert mode. After a Normal-mode edit, use `Space w`.
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
| `Space c d` / `Space c D` | Diagnostics list (buffer / project) |
| `]d` / `[d` | Next / previous diagnostic |
| `Space y p/d/f` | Copy file path / working dir / file folder |
| `Space r` | Reload files changed on disk |
| `Space o` | Open the current file in its macOS app |
| `Space m` | Toggle Markdown rendering (in Markdown files) |
| `Space z a/o/c` | Fold: toggle / open all / close all |
| `gd` / `gh` | Definition / hover |
| `gsa` / `gsd` / `gsr` | Surround add / delete / replace |
| `H` / `L` | Previous / next buffer |

`Space g` resolves the repository from the current file. In Oil, it resolves
from the directory being viewed, so it does not depend on Neovim's `:pwd`.

The `Space e` file-explorer sidebar is separate from Oil (`Space h`). From the
tree, `Space l` (or `Ctrl-l`) moves focus to the editor, and `Ctrl-h` moves
focus back to the tree. There is no `Space h` for window-left because `Space h`
opens Oil, so the key to return to the tree is `Ctrl-h`. Press `Space e` again
to close the sidebar. The sidebar shows dotfiles by default (matching Oil) but
hides `.gitignore`d files; inside the tree press `H` to toggle dotfiles and `I`
to toggle gitignored files.

Completion appears automatically. Press `Enter` to accept the selected item.

`Space p` selects a formatter from the current buffer's filetype: `gofmt` for
Go, `stylua` for Lua, project-local Prettier for JavaScript and TypeScript,
`mdformat` for Markdown, and Ruff for Python. Formatting changes the buffer;
use `Space w` to write it to disk. Format-on-save is not enabled yet.

`vtsls` provides JavaScript and TypeScript diagnostics, completion, hover, and
code navigation. The ESLint language server discovers the nearest workspace
`eslint.config.mjs`, so each Cortana Services app or package uses its shared
`@cortana/tooling` profile. ESLint fixes on save remain disabled.

`graphql-lsp` provides schema-aware validation, completion, hover, and
go-to-definition for `.graphql` files, resolving the schema from the project's
`graphql-config` (for example `graphql.config.ts`).

Diagnostics from any server show inline at the end of the line (virtual text).
Use `]d` / `[d` to jump between them, `Ctrl-w d` for the detail float, and
`Space c d` / `Space c D` for a searchable list of the current buffer's or the
project's diagnostics.

The statusline (lualine) shows the current mode, git branch and diff,
diagnostics, the attached LSP client(s), filetype, encoding, and cursor
location.

In Markdown files, render-markdown decorates headings, checkboxes, code blocks,
tables, and quotes in the editor; `Space m` toggles between raw and rendered.

Snacks also provides indent guides with scope highlighting, highlights other
uses of the symbol under the cursor, and disables heavy features on very large
files for performance.

Opening an image or PDF renders it in Neovim through Snacks when the terminal
supports the Kitty graphics protocol. Ghostty is supported; ImageMagick and
Ghostscript provide the conversion tools. This is a quick, read-only preview,
not a full PDF reader. Use `Space o` to open the current file in its default
macOS app; PDFs normally open in Preview for zoom, search, and page navigation.

Folding is Tree-sitter based and files open unfolded. Use `Space z` (toggle /
open all / close all) or the native `za` / `zR` / `zM`.

The cursor line stays vertically centered as you move up and down
(`scrolloff = 999`).

Opening Neovim with no file shows a start dashboard (Snacks) with shortcuts
(find, grep, recent, explorer, new, LazyGit, config, Lazy, quit), a recent-files
list, and startup stats. Open a file and it disappears. The header is the anon
mask read from `config/fastfetch/logo-anon.txt` (shared with fastfetch), so
editing that logo updates both.
