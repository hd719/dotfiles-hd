# Neovim

This is a small, personal Neovim config based on Kuncheng Gui's structure and
Hamel's existing Zed muscle memory.

## Profiles

- `full` is the default and preserves the complete development editor on
  Ubuntu, full personal Macs, and Resilience.
- `thin` is selected by `DOTFILES_NVIM_PROFILE=thin`. It keeps the shared
  editing behavior, Nord, Bufferline, Lualine, WhichKey, Oil, Mini pairs and
  surround, Gitsigns, rendered Markdown with wrapped tables, Obsidian, slim
  Snacks pickers and
  Explorer, Snacks terminals, Tree-sitter Markdown parsing, Marksman, and
  Bookokrat PDF reading.

Both profiles use this directory and the same `lazy-lock.json`. Disabled
full-only plugins are not restored on a thin machine. An unknown profile stops
startup instead of silently choosing the wrong tool boundary.

## Full Profile Requirements

- Neovim 0.12+, ripgrep, fd, fzf, LazyGit, and the Tree-sitter CLI.
- Go: `gopls` and `gofmt`.
- Lua: `lua-language-server` and `stylua`.
- JavaScript and TypeScript: `vtsls` for language intelligence,
  `vscode-eslint-language-server` for project lint rules, and project-local
  `prettier` for formatting.
- Markdown: `marksman` for language intelligence and `mdformat`, installed
  through `uv` with GFM, frontmatter, footnote, alert, and Obsidian-wikilink
  plugins.
- Python: `ruff`, pinned through `uv`.
- GraphQL: `graphql-lsp` (from `graphql-language-service-cli`), installed to a
  fixed prefix and referenced by absolute path. Schema-aware features need a
  `graphql-config` (e.g. `graphql.config.ts`) in the project.
- JSON, CSS, and HTML: `jsonls`, `cssls`, and `html` from
  `vscode-langservers-extracted` (already installed for ESLint); JSON schemas
  come from `SchemaStore.nvim`.
- Shell: `bash-language-server` for shell-script diagnostics and completion.
- Images: ImageMagick (`magick`) converts supported files for Snacks previews.
- PDFs: `bookokrat` provides search, page navigation, zoom, table-of-contents
  browsing, bookmarks, annotations, and Vim-style reading inside Ghostty or a
  dedicated Herdr tab.
- Editing: `mini.pairs` auto-closes brackets and quotes; `mini.surround` adds,
  changes, and deletes surrounding pairs with a `gs` prefix.

The thin profile requires Neovim 0.12+, Bookokrat, ripgrep, Marksman, and the
Tree-sitter CLI used to build its two Markdown parsers.

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

## Plugin Catalog

The full profile installs all 22 plugins below. The thin profile installs only
the subset listed above. In `:Lazy`, **Loaded** means a plugin's trigger has
happened in this session; **Not Loaded** means it is installed and waiting for
that trigger. `lazy-lock.json` pins exact versions, while the Lua files under
`lua/plugins/` define their behavior.

Lazy reads every plugin recipe at launch. A recipe can load immediately with
`lazy = false`, wait for an event/filetype/key/command, or load as a dependency
immediately before another plugin needs it. Key-triggered plugins still have
their placeholder mapping available before the plugin itself loads. Once a
plugin loads, it stays loaded until that Neovim session ends.

| Plugin                       | What it does here                                                                                | Exact load trigger                                       |
| ---------------------------- | ------------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| `blink.cmp`                  | Autocomplete from LSP, paths, snippets, and buffer words                                         | Every startup: `lazy = false`                            |
| `bufferline.nvim`            | Shows open buffers across the top                                                                | Just after startup: `VeryLazy` event                     |
| `friendly-snippets`          | Ready-made snippets consumed by Blink                                                            | Immediately before Blink as its dependency               |
| `lazy.nvim`                  | Installs, pins, restores, and lazy-loads plugins                                                 | Bootstrapped before all managed plugins                  |
| `lualine.nvim`               | Bottom status line for mode, Git, diagnostics, LSP, and location                                 | Just after startup: `VeryLazy` event                     |
| `markdown-table-wrap.nvim`   | Reflows wide Markdown table cells in a protected reader without changing the source              | First Markdown buffer                                    |
| `mini.icons`                 | File and folder icons shared by other plugins                                                    | Immediately before startup-loaded Oil as its dependency  |
| `nord.nvim`                  | Transparent Nord colors and custom highlights                                                    | Early every startup: `lazy = false`, priority `1000`     |
| `nvim-lspconfig`             | Connects installed language servers to matching files                                            | Every startup: `lazy = false`                            |
| `nvim-treesitter`            | Structure-aware highlighting and folding                                                         | Every startup: `lazy = false`                            |
| `obsidian.nvim`              | Vault-aware note search, backlinks, links, tags, and Obsidian app integration                    | First Markdown buffer, `Space o …`, or `:Obsidian`       |
| `oil.nvim`                   | Editable directory browser and file manager                                                      | Every startup: `lazy = false`                            |
| `schemastore.nvim`           | JSON schemas for files such as `package.json` and `tsconfig.json`                                | Immediately before LSPConfig as its dependency           |
| `snacks.nvim`                | Dashboard, finders, explorer, diagnostics, LazyGit, terminals, notifications, and image previews | Early every startup: `lazy = false`, priority `1000`     |
| `treesitter-parser-registry` | Catalog that tells Tree-sitter where language parsers and queries live                           | Immediately before Tree-sitter as its dependency         |
| `which-key.nvim`             | Shows available mappings after a key prefix                                                      | Just after startup: `VeryLazy` event                     |
| `conform.nvim`               | Runs gofmt, StyLua, Prettier, mdformat, and Ruff                                                 | First file read/new file, `Space p`, or `:ConformInfo`   |
| `gitsigns.nvim`              | Git add/change/delete gutter marks and current-line blame                                        | First file read or new file: `BufReadPre` / `BufNewFile` |
| `grug-far.nvim`              | Reviewed, exact-word replacement in the current file                                             | First `Space R`                                          |
| `mini.pairs`                 | Automatically closes brackets and quotes                                                         | First entry into Insert mode: `InsertEnter`              |
| `mini.surround`              | Adds, deletes, or replaces quotes, brackets, and tags                                            | First `gsa`, `gsd`, `gsr`, `gsf`, `gsF`, or `gsh`        |
| `render-markdown.nvim`       | Decorates Markdown headings, lists, checkboxes, and code blocks                                  | First Markdown buffer or its profile-specific toggle     |

Configuration map:

- `lua/config/profile.lua`: strict `full` or `thin` profile selection.
- `lua/config/lazy.lua`: Lazy bootstrap.
- `lua/plugins/colorscheme.lua`: Nord.
- `lua/plugins/editor.lua`: WhichKey and Tree-sitter.
- `lua/plugins/navigation.lua`: Snacks, Oil, and icons.
- `lua/plugins/lsp.lua`: completion, LSP, schemas, and formatting.
- `lua/plugins/obsidian.lua`: safe vault navigation and explicit daily notes.
- `lua/plugins/git.lua`, `bufferline.lua`, `statusline.lua`,
  `markdown.lua`, and `editing.lua`: their matching focused features.

## Safety Net

- `nvim --clean` starts Neovim without this config.
- `:Lazy` shows installed plugins and their status.
- `:checkhealth` runs Neovim's diagnostics.
- `:checkhealth snacks` verifies image tools and terminal graphics support.
- `:checkhealth obsidian` verifies the vault, picker, and required tools.
- `:Obsidian check` runs obsidian.nvim's configuration check.
- `:checkhealth vim.lsp` runs Neovim's LSP diagnostics on Neovim 0.12+.
  Seeing a client such as `gopls` confirms that language intelligence is
  attached to the current buffer. Use this instead of the legacy `:LspInfo`.
- `:pwd` shows Neovim's current working directory; remember **PWD = place**.
- `:echo expand('%:t')` shows the current buffer's filename only; `%` means the
  current file and `:t` asks for its tail name.
- `:ConformInfo` shows formatter status.
- `:TSStatus` shows Tree-sitter parsers.
- `[+]` beside a buffer name means it has unsaved changes. Normal `Space q`
  refuses to close that buffer instead of silently discarding them.
- `:bd!` removes only the current buffer from Neovim and discards its unsaved
  changes; it does not delete the file from disk. Use it only after confirming
  the current buffer is disposable.

For a calm first run, open this file with `nvim ~/.config/nvim/README.md`, then
press `Space` to see the available commands immediately. Press `Escape` to
close WhichKey; an extra `Space` is ignored instead of moving the cursor.

## Curriculum and Learning Log

- [CURRICULUM.md](CURRICULUM.md) tracks core sub-lessons and optional deep dives
  with checkboxes.
- [LEARNING_LOG.md](LEARNING_LOG.md) is the required append-only session record.
- Lesson 5 uses the harmless Go module at
  `~/Developer/dotfiles-hd/config/nvim/practice/lesson-05-go` for LSP drills.

Every agent teaching Neovim must read and update both files.

## Key Differences From Normal Vim

- `i` inserts after the cursor and `a` inserts before it, matching Zed.
- `Escape` is the primary mode-exit key. Shortcat currently captures
  `Ctrl-Space` before it reaches Neovim.
- Herdr uses `Ctrl-b` as its prefix, matching Kuncheng's config, so one
  `Escape` reaches Neovim both directly in Ghostty and inside Herdr.
- In a Snacks picker, the first `Escape` leaves its search-input Insert mode;
  the second `Escape` closes the picker.
- In the Snacks file picker, `Tab` / `Shift-Tab` move down / up without
  selecting multiple files. Type fuzzy path fragments separated by spaces,
  then press `Enter` once to open only the highlighted result.
- Normal-mode `Escape` auto-saves a named file only when every unsaved change
  came from Insert mode. After a Normal-mode edit, use `Space w`.
- `Ctrl-a` selects the whole file.

## Main Keys

| Key                                      | Action                                                                        |
| ---------------------------------------- | ----------------------------------------------------------------------------- |
| `Space f`                                | Open the Find menu                                                            |
| `Space f f/r/l/w/g/d/t`                  | Files / recent / current lines / cursor word / Git changes / dotfiles / TODOs |
| `Space /`                                | Search text                                                                   |
| `Space S`                                | Search named code symbols with the attached LSP                               |
| `Space h`                                | Open Oil file browser                                                         |
| `Space e`                                | Open the file-explorer sidebar (Snacks)                                       |
| `Space b`                                | Pick a buffer                                                                 |
| `Space b`, then `Space d`                | Close the highlighted buffer; empty replacement buffers stay hidden           |
| `Space d`                                | Close the current buffer                                                      |
| `Space w` / `Space x`                    | Save / save and quit                                                          |
| `Space R`                                | Replace the word under the cursor in the current file                         |
| `Space C`                                | Open the Crosshair menu                                                       |
| `Space C c/v`                            | Toggle the full crosshair / vertical line only; the row stays on              |
| `u` / `Ctrl-r` / `.`                     | Undo / redo / repeat the last change                                          |
| `o` / `O`                                | Open a new line below / above and enter Insert mode                           |
| `w` / `e` / `b`                          | Next word start / word end / previous word start                              |
| `2w` / `2dw`                             | Move two words / delete two words                                             |
| `0` / `$` / `gg` / `G`                   | Line start / line end / file top / file bottom                                |
| `%`                                      | Jump between matching `()`, `[]`, or `{}`                                     |
| `d{motion}` / `c{motion}` / `y{motion}`  | Delete / change / yank a motion's range                                       |
| `ciw` / `daw`                            | Change inner word / delete a word plus adjacent space                         |
| `ci(` / `da(`                            | Change inside / delete around parentheses                                     |
| `ci"` / `da"`                            | Change inside / delete around quotes                                          |
| `/`, then `n` / `N`                      | Search current file, then next / previous match                               |
| `:noh`                                   | Clear current search highlighting                                             |
| `Ctrl-a`                                 | Select the whole buffer                                                       |
| `yy` / `p` / `P`                         | Yank current line / paste after / paste before                                |
| Visual `<` / `>` / `J` / `K` / `Space c` | Outdent / indent / move down / move up / comment                              |
| `Space v` / `Space s`                    | Split right / down                                                            |
| `Space 0`, then `H` / `L`                | Move current buffer left / right; three idle seconds or `Escape` exits        |
| `Space W d`                              | Show diagnostics under the cursor                                             |
| `Space W h/j/k/l`                        | Focus window left / down / up / right                                         |
| `Space W H/J/K/L`                        | Move the current window to the far left / bottom / top / right                |
| `Space W s/v/T`                          | Split horizontally / vertically / move the window to a new tab                |
| `Space W q/o/w/x`                        | Quit / close others / switch / swap windows                                   |
| `Space W +/-/</>/=/_`                    | Resize, equalize, or maximize window height                                   |
| `Space u w`                              | Toggle word-aware wrapping in the current window                              |
| `Ctrl-h/j/k/l`                           | Focus window left / down / up / right                                         |
| `Ctrl-o` / `Ctrl-i`                      | Jump-history Back / Forward                                                   |
| `Space q`                                | Close the current window                                                      |
| `Space t` / `Space T`                    | Bottom / floating terminal                                                    |
| `Space g`                                | Open LazyGit                                                                  |
| `Space p`                                | Format                                                                        |
| `Space c a`                              | LSP code action                                                               |
| `Space c f`                              | Show the diagnostic under the cursor                                          |
| `Space c q`                              | Close only the quickfix/references list                                       |
| `Space c r`                              | Restart Neovim and restore open buffers/windows                               |
| `Space c d` / `Space c D`                | Diagnostics list (buffer / project)                                           |
| `]d` / `[d`                              | Next / previous diagnostic                                                    |
| `Space y a/p/d/f`                        | Copy whole buffer / file path / working dir / file folder                     |
| `Space r`                                | Reload files changed on disk                                                  |
| `Space o`                                | Open the Obsidian menu                                                        |
| `Space o q/s/b/l`                        | Quick switch / search / backlinks / links from this note                      |
| `Space o d`                              | Open or create today's private daily note                                     |
| `Space o o/t/c`                          | Open in Obsidian / tags / table of contents                                   |
| `Space o p`                              | Export the current vault note to PDF through Obsidian                         |
| `Space o m`                              | Open the Marksman menu                                                        |
| `Space o m a/d/h`                        | Marksman actions / definition / hover                                         |
| `Space o m m/n`                          | Toggle Marksman diagnostics / rename                                          |
| `Space o m r/s`                          | Marksman references / symbols                                                 |
| `Space o e`                              | Open the current file externally; PDFs use Bookokrat                          |
| `Space m m`                              | Toggle Marksman for the current Markdown file                                 |
| `Space m r`                              | Toggle Markdown rendering                                                     |
| `Space m R`                              | Refresh Markdown tables from Source, Inline, Reader, or another pane          |
| `Space u`                                | Built-in `z` actions: folds, viewport, and spelling                           |
| `gd` / `gh` / `grr`                      | Definition / hover / references                                               |
| `gsa` / `gsd` / `gsr`                    | Surround add / delete / replace                                               |
| `H` / `L`                                | Previous / next buffer                                                        |

The four search scopes are different: `/` searches text in the current file,
`Space /` searches text across the project, `Space f f` searches project
filenames, and `Space S` asks the LSP for named code symbols such as functions,
methods, types, and variables. `Space f` is a discoverable Find menu: pause
after it to see file, recent, current-line, cursor-word, Git-change, dotfiles,
and TODO pickers.

The `Space f g` Git picker keeps unchanged diff context transparent and uses
Hunk's Dracula semantic palette: green additions, red deletions, and cyan
modified-file markers. This styling is scoped to the Snacks Git picker; the
rest of the editor remains Nord.

Use `.` for repeated mechanical code edits. For example, if several lines have
the same extra comma, delete the first comma with `x`, move to the next one, and
press `.` to repeat that deletion. Use LSP rename for project-wide symbol
renames instead of repeating manual edits.

`Space c q` runs `:cclose`, so it closes the quickfix list created by commands
such as `grr` while keeping the code window open. `Space q` runs `:quit` and
closes whichever Neovim window is currently focused.

This config sets `clipboard=unnamedplus`, so regular yanks such as `yy` also
reach the system clipboard. In an SSH session, Neovim uses OSC 52 to send the
yank through the terminal to the Mac clipboard for `Cmd-v` in other
applications. `Space y a` copies the entire current buffer, including unsaved
changes, without moving the cursor or entering Visual mode.

For visual current-file replacement, save the file, put the cursor on the exact
word, and press `Space R`. Type the replacement, review the diff, then press
`Space r` inside Grug Far to apply it. The search is limited to that file and
does not match the word inside a larger word.

`Space g` resolves the repository from the current file. In Oil, it resolves
from the directory being viewed, so it does not depend on Neovim's `:pwd`.

`Space o` is the Obsidian menu for the vault at `~/Developer/hd`. The initial
setup is navigation-first: automatic frontmatter changes, completion-based note
creation, link renames, checkbox creation, and sync are disabled. `Space o d`
is the explicit exception: it creates today's note in
`Knowledge/_private/daily` from the matching private-daily template. Private
work under `Knowledge/_private`, `Knowledge/raw/_work`, and
`Knowledge/raw/_drawings` remains excluded from Obsidian pickers.
Obsidian `![[image.png]]` embeds are resolved to their real attachment path and
rendered automatically by Snacks; there is no separate key.

`marksman` provides Markdown and `[[wikilink]]` diagnostics, completion, hover,
go-to-definition, references, and rename support. The vault's
`.marksman.toml` keeps completion filename-based and disables the create-missing
file action so note creation remains explicit. Press `Space o m` to discover
its actions.

### Using Marksman in the vault

Open a Markdown note under `~/Developer/hd` and press `Space m m`. Marksman
attaches only to that file; press it again to detach. Put the cursor on a
`[[wikilink]]`, then use:

- `Space o m h` to preview the target.
- `Space o m d` to open the target.
- `Space o m r` to find references to it.
- `Space o m s` to browse headings in the current note.
- `Space o m n` to rename a target, or `Space o m a` for available actions.

`Space o m m` shows or hides only Marksman's diagnostics for the current note;
navigation remains available while diagnostics are muted.

The `Space e` file-explorer sidebar is separate from Oil (`Space h`). From the
tree, `Space W l` moves focus to the editor, and `Space W h` moves focus back
to the tree. The existing `Space l` and `Ctrl-h/l` shortcuts remain available,
but the `Space W` group works consistently even where a plugin owns a plain
Control mapping. Press `Space e` again to close the sidebar. The sidebar shows
dotfiles by default (matching Oil) but hides `.gitignore`d files; inside the
tree press `H` to toggle dotfiles and `I` to toggle gitignored files.

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
Use `]d` / `[d` to jump between them, `Space c f` for the detail float, and
`Space c d` / `Space c D` for a searchable list of the current buffer's or the
project's diagnostics. `Space W d` mirrors native `Ctrl-w d` inside the Windows
menu.

Diagnostic-navigation mnemonic: `]d` moves forward to the next diagnostic,
`[d` moves backward to the previous one, and `d` means diagnostic. This is the
fast everyday loop for stepping through errors without opening a list.

Read an inline diagnostic in three parts: the gutter letter such as `E` gives
its severity, the underline/highlight marks the exact broken code, and the
virtual text explains the problem.

The statusline (lualine) keeps its center transparent while showing the current
mode, Git branch and diff, filename, diagnostics, attached LSP client(s),
filetype, and compact cursor location/progress.

In Markdown files, render-markdown decorates headings, checkboxes, code blocks,
tables, and quotes in the editor. `Space m r` toggles it in either profile.
Those decorations use Catppuccin Mocha accents over Neovim's transparent Nord
base, with compact heading bands and trimmed table cells.

Snacks also provides indent guides with scope highlighting, highlights other
uses of the symbol under the cursor, and disables heavy features on very large
files for performance.

Opening an image renders it in Neovim through Snacks when the terminal supports
the Kitty graphics protocol. PDFs are deliberately excluded from Snacks: opening
one launches Bookokrat in a focused Herdr tab and leaves a small instruction
buffer in Neovim instead of a raster preview. Outside Herdr on macOS, it opens
a new tab in the current Ghostty window. Use `j` / `k` to scroll, `h` / `l` for
pages, `+` / `-` to zoom, `z` / `Z` to fit height / width, `/` to search, and
`?` for full help.
Press `q` to quit; if `NORMAL` is shown, press `n` first. `Space o e` reopens
the current PDF, while non-PDF files still use their default macOS app. The
managed `Hamel Nord` theme lets Bookokrat's interface inherit Ghostty's
transparency.
The rendered PDF page remains an opaque `#434C5E` canvas because Kitty images
cannot inherit terminal transparency. Long mouse drags can lag, especially in
Herdr; use `n`, then `v` / `V` plus motions and `H` for keyboard highlighting.

Folding is Tree-sitter based and files open unfolded. Press `Space u` for the
same fold, viewport, and spelling actions normally reached through `z`.

The cursor line stays vertically centered as you move up and down
(`scrolloff = 999`). A blue-gray row-and-column crosshair marks the cursor
position without an extra plugin. Press `Space C` to open its menu: `c` toggles
the full crosshair, and `v` toggles only the vertical line while keeping the row
highlighted.

Opening Neovim with no file shows a start dashboard (Snacks) with shortcuts
(find, grep, recent, explorer, new, LazyGit, config, Lazy, quit), a recent-files
list, and startup stats. Open a file and it disappears. The header is the anon
mask read from `config/fastfetch/logo-anon.txt` (shared with fastfetch), so
editing that logo updates both.
