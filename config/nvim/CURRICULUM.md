# Neovim Warrior Curriculum

The mission is to make Hamel a deadly Vim/Neovim warrior: fast in daily work,
clear on the editor's mental model, and able to own the configuration without
unexplained magic.

## Progress Rules

- Core sub-lessons are the main track. Finish them before marking a lesson
  complete.
- Optional deep dives never block the next lesson. They can be completed later
  or skipped permanently.
- Add new depth requested by Hamel under the relevant lesson's **Optional Deep
  Dives** section.
- Check an item only after Hamel practices it and confirms what happened.
- Add the supporting session number beside every completed item and record the
  details in `LEARNING_LOG.md`.
- The next lesson is the first unchecked core sub-lesson in the earliest
  incomplete lesson, unless Hamel explicitly chooses something else.

## Current Checkpoint

- **Lesson:** 3 — Safe Editing and Recovery
- **Next core sub-lesson:** 3.5 — undo with `u`, redo with `Ctrl-r`, and repeat
  with `.`
- **Why Lesson 3 remains open:** undo, redo, repeat, clipboard, modified-buffer
  prompts, and intentional change abandonment remain.

## Lesson 1 — Editor Foundations

- [x] **Core lesson complete** — Session 001

### Core Sub-Lessons

- [x] **1.1** Launch the personal config through a harmless guide file. —
  Session 001
- [x] **1.2** Use `Space` and WhichKey to discover leader commands. — Session
  001
- [x] **1.3** Find and open a file with `Space f` and fuzzy filtering. — Session
  001
- [x] **1.4** Explain file, buffer, and window as separate concepts. — Session
  001
- [x] **1.5** Switch to the previous buffer with `H`. — Session 001
- [x] **1.6** Switch to the next buffer with `L`. — Session 001
- [x] **1.7** List and select open buffers with `Space b`. — Session 001
- [x] **1.8** Explain the roles of Snacks, Oil, and Tree-sitter. — Session 001
- [x] **1.9** In Oil, read the `oil:///` working-directory path and navigate
  with `j`, `Enter`, and `-`. — Session 001
- [x] **1.10** Move upward in Oil with `k`. — Session 001
- [x] **1.11** Create a vertical split with `Space v` and move with `Ctrl-h` and
  `Ctrl-l` in a normal file buffer. — Session 001
- [x] **1.12** Create a horizontal split with `Space s`. — Session 001
- [x] **1.12a** Move between horizontal panes with `Ctrl-j` and `Ctrl-k`. —
  Session 001
- [x] **1.13** Distinguish `Space q` window-close from `Space d` buffer-close. —
  Session 001
- [x] **1.14** Explain that `Space q` exits Neovim when only one window remains.
  — Session 001
- [x] **1.15** Identify that Shortcat captures `Ctrl-Space` before Neovim. —
  Session 001
- [x] **1.16** Use `Escape` to cancel a picker and return from Insert mode to
  Normal mode. — Session 001

### Optional Deep Dives

- [ ] **1.D1** Start with `nvim --clean` and compare the unconfigured editor.
- [ ] **1.D2** Use `Space j`, `Space k`, and `Space l` as window-focus
  alternatives.
- [ ] **1.D3** Resize, equalize, and rotate window layouts.

## Lesson 2 — Project Search and Results

- [x] **Core lesson complete** — Session 001

### Core Sub-Lessons

- [x] **2.1** Open project grep with `Space /` and identify its search root. —
  Session 001
- [x] **2.2** Search for a real symbol or phrase in a repository. — Session 001
- [x] **2.3** Move through results and read the live preview. — Session 001
- [x] **2.4** Open the selected match with `Enter` at the exact line. — Session
  001
- [x] **2.5** Return through jump history with `Ctrl-o` and `Ctrl-i`. — Session
  001
- [x] **2.6** Explain when to use `Space f`, `Space /`, and `Space b`. — Session
  001

### Optional Deep Dives

- [ ] **2.D1** Toggle hidden, ignored, and regex search behavior.
- [ ] **2.D2** Restrict searches with file globs or a narrower directory.
- [ ] **2.D3** Send search results to the quickfix list.
- [ ] **2.D4** Search only the current buffer and compare the workflow.

## Lesson 3 — Safe Editing and Recovery

- [ ] **Core lesson complete**

### Core Sub-Lessons

- [x] **3.1** Create a harmless scratch buffer with `Space n`. — Session 001
- [x] **3.2** Enter and leave Insert mode with the intentional reversed `i` and
  `a` behavior. — Session 001
- [x] **3.3** Demonstrate exact `Escape` behavior: the first press leaves Insert
  mode; a later press in Normal mode saves only a named, modified normal file.
  — Session 001
- [x] **3.4** Save with `Space w` and save-and-quit with `Space x`. — Session
  001
- [ ] **3.5** Undo with `u`, redo with `Ctrl-r`, and repeat with `.`.
- [ ] **3.6** Yank, paste, and use the system clipboard safely.
- [ ] **3.7** Recognize modified buffers and unsaved-change prompts.
- [ ] **3.8** Abandon a practice change intentionally without losing real work.

### Optional Deep Dives

- [ ] **3.D1** Inspect persistent undo across Neovim restarts.
- [ ] **3.D2** Explore completion, snippets, and documentation popups.
- [ ] **3.D3** Recover from swap, backup, or interrupted-write scenarios.
- [x] **3.D4** Diagnose and recover an accidental Oil listing edit without
  changing the file on disk. — Session 001

## Lesson 4 — Motions, Operators, and Text Objects

- [ ] **Core lesson complete**

### Core Sub-Lessons

- [ ] **4.1** Navigate with word, line, file, and matching-pair motions.
- [ ] **4.2** Combine `d`, `c`, and `y` with motions instead of memorized edits.
- [ ] **4.3** Use counts to scale motions and operators.
- [ ] **4.4** Edit with inside and around text objects for words, quotes, and
  brackets.
- [ ] **4.5** Search within a file with `/`, `n`, and `N`.
- [ ] **4.6** Select the full buffer with the custom `Ctrl-a` mapping.
- [ ] **4.7** Indent with `<` and `>`, move with `J` and `K`, and comment with
  `Space c` while a visual selection stays active.

### Optional Deep Dives

- [ ] **4.D1** Master `f`, `F`, `t`, and `T` character motions.
- [ ] **4.D2** Practice sentence, paragraph, and block text objects.
- [ ] **4.D3** Build repeatable editing chains around the `.` command.

## Lesson 5 — Code Navigation with LSP

- [ ] **Core lesson complete**

### Core Sub-Lessons

- [ ] **5.1** Open real Go and Lua projects and verify attachment with
  `:LspInfo`.
- [ ] **5.2** Read symbol information with `gh` hover.
- [x] **5.3** Jump to definitions with `gd` and return with `Ctrl-o`. — Session 008
- [ ] **5.4** Find references with Neovim's native `grr` mapping.
- [ ] **5.5** Search workspace symbols with `Space S`.
- [ ] **5.6** Use completion deliberately and accept the intended item.

### Optional Deep Dives

- [ ] **5.D1** Rename symbols with `grn` and review every affected file.
- [ ] **5.D2** Explore implementations, declarations, and document symbols.
- [ ] **5.D3** Compare Tree-sitter structure with LSP semantic knowledge.
- [x] **5.D4** Verify `vtsls` attachment in a TypeScript/TSX buffer and confirm
  that it uses the project's TypeScript version. — Session 005
- [ ] **5.D5** Add and use the GraphQL language server (`graphql-lsp`) for
  `.graphql` files, with schema-aware features from the project's
  `graphql-config`.

## Lesson 6 — Diagnostics, Code Actions, and Formatting

- [ ] **Core lesson complete**

### Core Sub-Lessons

- [ ] **6.1** Read diagnostic signs, highlights, and messages.
- [ ] **6.2** Move between diagnostics with `[d` and `]d`.
- [ ] **6.3** Open a diagnostic detail float with `Ctrl-w d` without changing
  code.
- [ ] **6.4** Inspect and choose LSP actions with `Space c a`.
- [ ] **6.5** Format Go and Lua manually with `Space p` and review the diff.
- [ ] **6.6** Diagnose formatter availability with `:ConformInfo`.
- [ ] **6.7** Explain the current coverage: Go, Lua, JavaScript, and TypeScript
  have LSP support; Go, Lua, JavaScript, TypeScript, Markdown, and Python have
  manual formatting; ESLint provides project lint diagnostics while automatic
  formatting and lint fixes on save remain disabled.

### Optional Deep Dives

- [ ] **6.D1** Send diagnostics to a location or quickfix list.
- [ ] **6.D2** Filter diagnostics by severity and source.
- [ ] **6.D3** Add a new formatter without introducing hidden auto-formatting.
- [x] **6.D4** Recover broken TypeScript/TSX highlighting by reinstalling the
  Tree-sitter parsers in dependency order. — Session 003
- [x] **6.D5** Format a TSX buffer manually with `Space p` using project-local
  Prettier and verify the indentation change. — Session 004
- [x] **6.D6** Format Markdown manually with `Space p` using dedicated
  `mdformat` instead of Prettier. — Session 004
- [ ] **6.D7** Format Python manually with `Space p` using Ruff installed
  through `uv`.
- [x] **6.D8** Verify a live ESLint unused-variable diagnostic and distinguish
  its `E` sign from Gitsigns' `H` changed-hunk sign. — Session 006

## Lesson 7 — Multi-File Project Workflow

- [ ] **Core lesson complete**

### Core Sub-Lessons

- [ ] **7.1** Recall buffers, windows, and splits without looking at the log.
- [ ] **7.2** Place two different files in a deliberate split layout.
- [ ] **7.3** Change one window's buffer without disturbing the other window.
- [ ] **7.4** Move through buffers, search results, and jump history while
  preserving context.
- [ ] **7.5** Close the intended buffer or window and explain the difference.
- [ ] **7.6** Complete one real edit across multiple files from search to save.

### Optional Deep Dives

- [ ] **7.D1** Use the quickfix list as a persistent project task list.
- [ ] **7.D2** Learn marks for durable local and cross-file positions.
- [ ] **7.D3** Compare Neovim tab pages with Zed-style file tabs.
- [ ] **7.D4** Save and restore a multi-window session.
- [x] **7.D5** Add a bufferline (`bufferline.nvim`) that shows open buffers as a
  Zed-style tab strip, and move along it with `H` and `L`. — Session 008
- [ ] **7.D6** Auto-reload buffers changed on disk by an external tool (e.g. the
  Cursor agent) with `autoread` and a `checktime` autocmd, plus `Space r` to
  reload on demand.

## Lesson 8 — Terminal and Git Workflow

- [ ] **Core lesson complete**

### Core Sub-Lessons

- [ ] **8.1** Open bottom and floating terminals with `Space t` and `Space T`.
- [ ] **8.2** Distinguish terminal-input mode from terminal Normal mode.
- [ ] **8.3** Exit terminal-input mode with Snacks' double-`Escape` behavior and
  the native `Ctrl-\`, `Ctrl-n` fallback while Shortcat owns `Ctrl-Space`.
- [ ] **8.4** Navigate between terminal and editor windows without losing work.
- [x] **8.5** Read Gitsigns gutter changes and current-line blame. — Session 008
- [x] **8.6** Open LazyGit with `Space g` and inspect status and diffs. —
  Session 007
- [ ] **8.7** Exit terminal and Git views while preserving editor buffers.

### Optional Deep Dives

- [ ] **8.D1** Manage multiple named or task-specific terminals.
- [ ] **8.D2** Stage and commit a safe practice change from LazyGit.
- [ ] **8.D3** Build a test-and-return loop around a real project command.
- [ ] **8.D4** Run Neovim inside Herdr with its `Ctrl-b` prefix, verify that one
  `Escape` changes Neovim modes, and verify Herdr navigation independently.

## Lesson 9 — Safe File Operations with Oil

- [ ] **Core lesson complete**

### Core Sub-Lessons

- [ ] **9.1** Create an isolated practice directory before modifying files.
- [ ] **9.2** Recognize that Oil locally maps `Ctrl-h` to open a horizontal split
  and `Ctrl-l` to refresh; leave Oil or use `Ctrl-w h/l` for window focus.
- [ ] **9.3** Create a file and directory through Oil.
- [ ] **9.4** Rename a file and understand Oil's pending-change state.
- [ ] **9.5** Move a file between directories.
- [ ] **9.6** Explain before deletion that this config has
  `delete_to_trash = false`, so an applied Oil deletion is permanent.
- [ ] **9.7** Delete only an isolated practice file with explicit confirmation.
- [ ] **9.8** Apply Oil changes and verify the resulting filesystem state.
- [ ] **9.9** Recover safely from an unintended pending operation.

### Optional Deep Dives

- [ ] **9.D1** Perform a reviewed batch rename or move.
- [ ] **9.D2** Explore hidden files, sorting, permissions, and detail columns.
- [ ] **9.D3** Decide whether to configure a trash-based workflow instead of
  permanent deletion.
- [x] **9.D4** Toggle a Snacks explorer sidebar with `Space e` for a
  Zed/VSCode-style file tree, kept separate from Oil (`replace_netrw = false`). — Session 008

## Lesson 10 — Warrior Techniques and Config Ownership

- [ ] **Core lesson complete**

### Core Sub-Lessons

- [ ] **10.1** Use named registers without clobbering important yanks.
- [ ] **10.2** Set and revisit marks and understand the jump list.
- [ ] **10.3** Record, inspect, and replay a safe macro.
- [ ] **10.4** Perform confirmed project search-and-replace.
- [ ] **10.5** Explain the Lua config structure and the roles of Lazy, Nord,
  Snacks, Oil, Tree-sitter, Blink, friendly-snippets, mini.icons, LSPConfig,
  Conform, and Gitsigns.
- [ ] **10.6** Make and verify one intentional keymap or option change.
- [ ] **10.7** Use `:Lazy`, `:checkhealth`, `:LspInfo`, `:ConformInfo`, and
  `:TSStatus` to troubleshoot independently.
- [ ] **10.8** Complete a real coding task primarily in Neovim and record the
  workflow improvements still needed.

### Optional Deep Dives

- [ ] **10.D1** Build more complex macros with registers and counts.
- [ ] **10.D2** Profile startup and identify slow plugin paths.
- [ ] **10.D3** Add or remove a plugin while keeping the config understandable.
- [ ] **10.D4** Explore Tree-sitter queries and custom captures.
- [ ] **10.D5** Design a personal speed-and-retention practice routine.
