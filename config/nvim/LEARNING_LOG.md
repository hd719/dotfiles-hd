# Neovim Learning Log

This is an append-only record of Hamel's Neovim lessons. Add a dated session
instead of rewriting older entries so the learning path stays recoverable.

Every agent must read this file before teaching Neovim and update it with every
concept, key, workflow, conflict, or correction taught during the session. Chat
history is not the source of truth.

## Mission

Make Hamel a deadly Vim/Neovim warrior: fast and confident in daily work, able
to explain the editor's mental model, and capable of changing the configuration
without relying on unexplained magic. Lessons stay hands-on and move one small
checkpoint at a time.

## 2026-07-10 — Session 001: First-Run Basics

### Goal

Become comfortable navigating the personal Neovim setup without losing the Vim
knowledge and Zed muscle memory already in place.

### Mental Model

- **File:** the copy stored on disk.
- **Buffer:** an open file held in Neovim's memory, similar to a Zed tab.
- **Window:** a pane that displays one buffer. Multiple windows can display the
  same buffer.
- **Plugin:** an added capability. Plugins do not replace Neovim's core buffer
  and window model.

### What We Practiced

#### Starting Safely

- Open the guide with `nvim ~/.config/nvim/README.md`.
- `nvim --clean` starts Neovim without the personal config.
- `Escape` returns to Normal mode. In Normal mode, the custom `Escape` mapping
  saves an existing modified file.

#### Leader Menu and Finding Files

- `Space` is the leader key.
- Pause after `Space` to open WhichKey and discover available commands.
- `Space f` opens the Snacks file finder.
- Type part of a filename to fuzzy-filter the results, then press `Enter` to
  open the selected file.

#### Buffers

- `H` and `L` move to the previous and next buffer.
- `Space b` opens the Snacks buffer picker.
- `Space d` closes the current buffer but never deletes its file from disk.
- If a buffer has unsaved changes, `Space d` asks whether to save, discard, or
  cancel.

#### Plugin Responsibilities

- **Snacks:** file picker, buffer picker, grep, terminal, notifications, and
  LazyGit integration.
- **Oil:** filesystem browsing and file operations through an editable buffer.
- **Tree-sitter:** parses code for accurate syntax highlighting and structure.
- Oil and Tree-sitter are both active; they solve unrelated problems.

#### Oil Navigation

- `Space h` opens Oil at Neovim's current working directory.
- The `oil:///...` status line shows the directory being viewed.
- Names ending in `/` are directories; `../` is the parent directory.
- `j` and `k` move through entries.
- `Enter` opens a directory or file.
- `-` moves to the parent directory.
- Avoid editing filenames in Oil until file operations are covered in a later
  lesson.

#### Windows and Splits

- `Space v` creates a vertical split to the right.
- `Space s` creates a horizontal split below.
- `Ctrl-h`, `Ctrl-j`, `Ctrl-k`, and `Ctrl-l` focus the left, lower, upper, and
  right windows.
- `Space q` closes the active window while leaving its buffer available.
- `Space d` closes a buffer while preserving the window layout.

### Important Key Conflict

`Ctrl-Space` is configured as a Neovim fallback escape key, but Shortcat owns
that macOS shortcut. Shortcat receives it before Ghostty or Neovim, so it does
not currently work inside Neovim. Use `Escape`. Decide later whether to move the
Shortcat shortcut or assign Neovim a different fallback.

### Next Lessons

- Project-wide grep with `Space /`.
- Editing, saving, formatting, and undo history.
- Go and Lua language-server features: hover, definitions, and code actions.
- Integrated terminals and LazyGit.

## Lesson Plan

This roadmap is ordered around daily coding usefulness. A lesson may take more
than one session; accuracy and confidence matter more than speed.

1. **Editor foundations — completed in Session 001**
   Modes, leader commands, files, buffers, windows, splits, plugin roles, and
   safe navigation with Oil.
2. **Project search and result navigation — next**
   Use `Space /` to grep a real repository, narrow results, preview matches, and
   open the right location without losing context.
3. **Safe editing and recovery**
   Insert and Normal mode, save behavior, undo and redo, repeat, clipboard,
   unsaved-change protection, and recovery commands.
4. **Motions, operators, and text objects**
   Combine movement with delete, change, yank, inside, and around so edits become
   composable instead of shortcut memorization.
5. **Code navigation with LSP**
   Hover, definitions, references, symbols, and moving through real Go and Lua
   code with language-server awareness.
6. **Diagnostics, code actions, and formatting**
   Read errors, move between diagnostics, use `Space c a`, and format safely
   with `Space p`.
7. **Multi-file project workflow**
   Build a fast loop across buffers, splits, search results, jumps, and the
   quickfix list while preserving context.
8. **Terminal and Git workflow**
   Use `Space t`, `Space T`, and `Space g` without losing editor state.
9. **Safe file operations with Oil**
   Create, rename, move, and delete files while understanding exactly when Oil
   applies changes to disk.
10. **Warrior techniques and config ownership**
    Registers, marks, jump lists, macros, search and replace, troubleshooting,
    plugin health, and confidently changing the Lua configuration.

## Curriculum Tracking Note

The checkable core track and optional deep dives now live in
`CURRICULUM.md`. This file remains the append-only evidence of what was actually
practiced in each session. The original lesson plan above is preserved as the
historical planning snapshot that led to the detailed curriculum.

### Retrospective Accuracy Corrections

- The detailed curriculum uses atomic evidence. Session 001 did not explicitly
  confirm `L`, Oil `k`, `Space s`, `Ctrl-j/k`, or an `Escape` mode transition,
  so those core boxes remain open even though related behavior was explained.
- `Space h` opens Oil at Neovim's current working directory, not necessarily the
  directory containing the current file.
- `Space q` closes a window when another remains, but exits Neovim when used on
  the final window.
- In Oil, local `Ctrl-h` and `Ctrl-l` override the global window-focus mappings.
- Oil currently uses `delete_to_trash = false`; applied deletions are permanent.
  File-operation lessons must use an isolated practice directory.

## 2026-07-10 — Session 001 Continued Practice

### Confirmed Progress

- **Curriculum 1.6:** Hamel pressed `L` and confirmed that Neovim opened the
  next buffer.
- Mental model: `H` and `L` move backward and forward through open buffers;
  neither command closes or deletes a buffer.

### Next Checkpoint

- **Curriculum 1.10 complete:** Hamel moved down one Oil entry with `j`, then
  pressed `k` and confirmed the cursor returned to the original entry.
- Mental model: Oil is still a Neovim buffer, so normal `j` and `k` vertical
  motions work on its directory entries.
- **Next:** Curriculum 1.12 — create a horizontal split with `Space s` and move
  with `Ctrl-j/k`.

### Clarification: Window Close vs Buffer Close

- `Space q` runs `:quit`: it closes the active window/pane. If that is the last
  window, it exits Neovim.
- `Space d` runs Snacks buffer delete: it removes the current buffer from the
  open-buffer list, preserves the window layout, and never deletes the file
  from disk.
- A modified buffer receives a save, discard, or cancel prompt before
  `Space d` closes it.

### Horizontal Split Progress

- **Curriculum 1.12 complete:** Hamel pressed `Space s` and confirmed that
  `README.md` appeared in two horizontal panes.
- Mental model: the split creates another window showing the same buffer; it
  does not duplicate the file.
- **Next:** Curriculum 1.12a — move between the lower and upper panes with
  `Ctrl-j/k`.
