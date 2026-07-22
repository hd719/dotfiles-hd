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

### Horizontal Split Navigation

- **Curriculum 1.12a complete:** Hamel used `Ctrl-j` and `Ctrl-k` and confirmed
  that focus moved between the lower and upper panes.
- Mental model: `Ctrl-h/j/k/l` changes the active window in the direction of the
  matching Vim movement key; it does not change or close a buffer.
- **Next:** Curriculum 1.14 — recall what `Space q` does on the final window.

### Retrieval Correction: Final-Window Quit

- Hamel initially described `Space d` behavior when asked about `Space q`.
- Correct model: `Space q` runs `:quit`; with one window remaining it exits
  Neovim.
- `Space d` closes the current buffer, keeps the window, and shows another
  buffer. It does not delete the file from disk.
- Curriculum 1.14 remains open pending a correct recall.
- On the second recall, Hamel chose `Space q` for keeping Neovim open. Reinforce
  the mnemonic: `q` quits the window; `d` dismisses the buffer while preserving
  the window.

### Final-Window Quit Confirmed

- **Curriculum 1.14 complete:** after correction, Hamel confirmed and noted that
  `Space q` quits Neovim when only one window remains.
- **Next:** Curriculum 1.16 — use `Escape` to cancel a picker and return to
  Normal mode.

### Escape Practice: Picker Cancel

- Hamel opened the file picker with `Space f`, filtered for `README`, pressed
  `Escape`, and confirmed that the picker closed.
- Curriculum 1.16 remains open until Hamel also practices leaving Insert mode
  with `Escape`.

### Escape Practice: Return to Normal Mode

- **Curriculum 1.16 complete:** Hamel entered Insert mode, pressed `Escape`, and
  confirmed the transition back to Normal mode.
- **Lesson 1 complete:** every core Editor Foundations sub-lesson has been
  practiced and confirmed.
- **Next:** Curriculum 2.1 — open project grep with `Space /` and identify its
  search root.

### Project Grep Opened

- Hamel pressed `Space /` and confirmed that the Snacks project-grep picker
  opened.
- By default, this picker searches from Neovim's current working directory.
- Curriculum 2.1 remains open until Hamel identifies that directory with
  `:pwd`.
- Screenshot confirmation showed the `Grep` overlay with an active blank input
  and `-- INSERT --`; this is the picker's search-input mode, not the normal
  file-editing view.
- Hamel pressed `Escape` once and confirmed that the Grep picker closed.

### Project Grep Detour: `pwd` as Search Text

- Hamel entered `pwd` in the Grep input and received four project matches with
  a live code preview.
- This was a valid preview of Curricula 2.2 and 2.3, but it was not the `:pwd`
  Ex command and did not reveal the search root.
- Keep 2.2 and 2.3 open until Hamel repeats those actions deliberately and
  confirms the result-navigation behavior.
- The screenshot also showed `README.md [+]`, meaning that buffer has an
  unsaved change. The saved working tree was still clean for that file, so
  leave the buffer open until the change can be inspected safely.

### Correction: Snacks Picker Requires Two Escapes

- Repeated screenshots confirmed that one `Escape` from the Snacks search input
  leaves Insert mode but keeps the picker open.
- A second `Escape`, now in the picker's Normal mode, closes the picker.
- The earlier single-`Escape` description was incomplete. The durable sequence
  is: first `Escape` changes mode, second `Escape` cancels the picker.

### Project Grep Search Root Confirmed

- **Curriculum 2.1 complete:** Hamel closed the picker, ran `:pwd`, and read
  `/Users/hameldesai/Developer/dotfiles-hd` at the bottom of Neovim.
- Mental model: `Space /` searches file contents beneath that current working
  directory unless a narrower directory is configured.
- The earlier `README.md [+]` marker cleared. A working-tree check found no
  accidental README edit; only the intentional picker-Escape documentation was
  present.
- **Next:** Curriculum 2.2 — deliberately search for a real project symbol.

### Deliberate Project Text Search

- **Curriculum 2.2 complete:** Hamel opened `Space /`, searched for
  `node_root`, and received eight content matches across the dotfiles repo.
- `Space f` filters file names and paths when the desired file is known.
- `Space /` searches text inside project files when the desired code or phrase
  is known but its location is not.
- Curriculum 2.6 remains open until `Space b` is included in the comparison.
- **Next:** Curriculum 2.3 — move through the eight results and watch the live
  preview follow the selection.

### Finder Terminology Clarified

- Both `Space f` and `Space /` use the same Snacks picker interface.
- `Space f` is the fuzzy file-name finder.
- `Space /` is live grep: it sends the search text to ripgrep to match file
  contents, with regular-expression and smart-case behavior by default.
- Hamel confirmed the distinction and continued to result navigation.

### Grep Result Navigation

- **Curriculum 2.3 complete:** Hamel used `Ctrl-j` and `Ctrl-k` to move through
  `node_root` matches and confirmed that the preview followed the selection.
- Precision: these keys move between matches, not necessarily different files;
  one file can contain several matching lines.
- **Next:** Curriculum 2.4 — press `Enter` to open the highlighted match at its
  exact file and line.

### Open a Grep Match

- **Curriculum 2.4 complete:** Hamel highlighted a `node_root` match, pressed
  `Enter`, and confirmed that Grep closed and the selected file opened at the
  matching line.
- **Next:** Curriculum 2.5 — use `Ctrl-o` to return to the older location, then
  `Ctrl-i` to move forward to the grep match again.

### Jump-History Mental Model

- `Ctrl-o` moves to an older meaningful cursor location, like a browser Back
  button for code navigation.
- `Ctrl-i` moves forward to a newer jump location.
- The jump list records larger moves such as opening a grep result; it does not
  record every ordinary `h/j/k/l` cursor movement.
- Curriculum 2.5 remains open until both directions are practiced.

### Jump History Practiced

- **Curriculum 2.5 complete:** Hamel used `Ctrl-o` and `Ctrl-i` and confirmed
  that backward and forward jump navigation both worked.
- **Next core lesson:** Curriculum 2.6 — compare `Space f`, `Space /`, and
  `Space b`.

### Oil Icon Safety Diagnosis

- Hamel reported that the icon beside `CONTEXT.md` disappeared in Oil.
- The file is safe: it remains a regular 29,984-byte file and has no Git change.
- MiniIcons still returns the Markdown icon for `CONTEXT.md`, and a fresh Oil
  render includes it. The missing decoration is therefore a transient edit to
  the live Oil listing, not deleted file data.
- Added optional Curriculum 3.D4 for safe Oil-listing recovery. First recovery
  step: press `u` once to undo the most recent Oil-buffer edit.

### Ghostty Blur Tuning

- Paused the Neovim lesson to reduce background distraction in Ghostty.
- Ghostty 1.3.1 documents `background-blur = true` as intensity `20`; changed it
  to numeric intensity `30`.
- Kept `background-opacity = 0.88` and `background-opacity-cells = true` so the
  existing Hamel Nord transparency remains consistent inside Neovim.
- The Ghostty file was later reverted to `background-blur = true`; reapplied
  intensity `30` and revalidated the actively linked configuration.

### Neovim Contrast Tuning

- Screenshots showed Nord's default `#616e88` comments and `#4c566a` inactive
  line numbers blending into the transparent Ghostty background.
- Changed comments to Zed's readable `#b5b5b5` while preserving italics.
- Changed inactive and relative line numbers to Nord frost `#81a1c1`; the
  current line number remains bright `#d8dee9` and bold.

### Picker Border Contrast

- A follow-up screenshot confirmed that comments and relative line numbers were
  readable, but the `Space f` and `Space /` picker outline still blended into
  the background.
- Snacks picker borders inherit Neovim's `FloatBorder`, which Nord colored
  `#4c566a`.
- Changed `FloatBorder` to Nord cyan `#88c0d0` while keeping its background
  transparent, improving the input, results, and preview outlines together.

### Oil Listing Recovered

- **Optional Curriculum 3.D4 complete:** Hamel pressed Normal-mode `u`, restored
  the missing Oil icon, and confirmed that `u` means undo.
- This restored only the editable Oil buffer display; `CONTEXT.md` remained
  unchanged on disk throughout.

### Oil Recovery Reinforced: Mode Matters

- In `config/herdr`, Hamel accidentally typed a folder-looking entry while Oil
  showed `-- INSERT --` and `[+]`.
- Pressing `u` initially inserted another literal `u` because `u` only means
  undo in Normal mode.
- Hamel pressed `Escape`, then Normal-mode `u`, and confirmed that the listing
  was restored.
- Filesystem and Git checks confirmed that no accidental directory was created
  and `config/herdr` remained unchanged.

### Herdr and Neovim Integration Decision

- Desired stack: Ghostty renders the terminal, Herdr optionally manages
  persistent workspaces and panes, and Neovim edits inside a pane.
- Herdr 0.7.3 is running, and the active dotfiles config sets its prefix to bare
  `Escape`.
- [Herdr's keyboard documentation](https://herdr.dev/docs/keyboard/) says the
  prefix is reserved and the following key goes to Herdr instead of the pane.
  Bare `Escape` therefore conflicts with Neovim's primary mode-exit key.
- This likely explains the inconsistent behavior between the direct `nvim .`
  Ghostty tab and the Herdr tab: in Herdr, `Escape` can be consumed before
  Neovim sees it.
- Recommendation: use direct Ghostty for Neovim now. Before daily Neovim use
  inside Herdr, move Herdr to its documented default `Ctrl-b` prefix and verify
  both layers. No Herdr config change was made without Hamel's approval.
- Added optional Curriculum 8.D4 for that integration test.

### Correction: Herdr Can Forward Its Escape Prefix

- Hamel's screenshot showed Herdr PREFIX mode explicitly listing
  `esc send prefix`.
- There is no Neovim configuration-file conflict. The conflict is input
  routing: one physical `Escape` enters Herdr PREFIX mode; `Escape Escape`
  forwards one logical `Escape` to Neovim.
- Inside Herdr, leaving Neovim Insert mode requires two physical `Escape`
  presses. Triggering the custom Normal-mode `Escape` save afterward requires
  two more. A Snacks picker that needs two logical escapes can likewise require
  four physical presses.
- The earlier recommendation not to use Neovim inside Herdr until changing the
  prefix was too strong. It works with `Escape Escape`; changing the prefix is
  an optional ergonomics decision to restore native one-press Vim behavior.
- Revised optional Curriculum 8.D4 to compare both workflows before deciding.

### Herdr Prefix Changed to `Ctrl-b`

- Hamel chose to make Neovim easier inside Herdr by freeing bare `Escape`.
- Kuncheng's current Herdr config uses `prefix = "ctrl+b"`; Hamel chose to
  match it.
- Changed the linked Herdr source config from `Escape` to `Ctrl-b`. Herdr
  commands now start with `Ctrl-b`, while a single `Escape` should reach
  Neovim directly.
- Revised optional Curriculum 8.D4 for a live single-`Escape` and Herdr-prefix
  verification after reload.
- Kuncheng's Neovim config uses native `Escape` to leave Insert mode and maps
  Normal-mode `Escape` to save, matching the same two-step mental model.
- Reloaded the running Herdr 0.7.3 server successfully: status `applied`, zero
  diagnostics, linked config confirmed, and the client/server remained healthy.
- Daily launch workflow: enter or attach to Herdr, move the pane to the project
  directory, and run `nvim .`. Herdr keeps the pane/session alive; Neovim owns
  editing and now receives bare `Escape` directly.
- Optional Curriculum 8.D4 remains open until Hamel verifies one-press
  `Escape` and a `Ctrl-b` Herdr command in the live pane.

### Picker Comparison Retrieval

- Curriculum 2.6 remains open because the three-way comparison was presented
  but not yet recalled from memory.
- Split the retrieval into one prompt at a time before advancing to Lesson 3.
- Recall 1 of 3 correct: Hamel answered `Space f` when the filename is known.
- Recall 2 of 3 correct: Hamel answered `Space /` when text inside project files
  is known.
- On recall 3, Hamel answered `H`/`L`. Those cycle to the previous or next
  buffer; `Space b` opens the searchable list of all open buffers.
- Curriculum 2.6 remains open pending a correct recall of `Space b`.

### Picker Comparison Confirmed

- **Curriculum 2.6 complete:** on retry, Hamel correctly recalled `Space b` for
  the searchable list of open buffers.
- Full model: `Space f` finds a file by name, `Space /` finds text inside project
  files, and `Space b` selects a file that is already open as a buffer.
- **Lesson 2 complete:** every core Project Search and Results sub-lesson has
  been practiced and confirmed.
- **Next:** Curriculum 3.1 — create a harmless unnamed buffer with `Space n`.

### Harmless Scratch Buffer

- **Curriculum 3.1 complete:** Hamel pressed `Space n` and confirmed that a
  blank screen opened.
- `Space n` runs `:enew`: it switches the current window to a new empty,
  unnamed buffer without creating a file on disk.
- Existing buffers remain available through `H`, `L`, or `Space b`.
- **Next:** Curriculum 3.2 — practice the intentional reversed `i` and `a`
  behavior inside this safe buffer.

### Scratch Insert-Mode Practice

- Hamel pressed `i`, typed `hello`, pressed `Escape`, and confirmed the return
  to Normal mode.
- Curriculum 3.2 remains open until the before-cursor and after-cursor behavior
  of the intentionally reversed `a` and `i` mappings is demonstrated.
- With the cursor on `h`, Hamel pressed `a`, inserted `X`, and produced
  `Xhello`, confirming that this custom `a` inserts before the cursor.
- After undoing, Hamel pressed `i` on `h`, inserted `X`, and produced `hXello`,
  confirming that this custom `i` inserts after the cursor.
- **Curriculum 3.2 complete:** both reversed insert mappings and the return to
  Normal mode with `Escape` were practiced.
- **Next:** Curriculum 3.3 — test Normal-mode `Escape` first on this unnamed
  modified buffer, where it must not create or save a file.

### Escape Safety: Unnamed Buffer

- Hamel pressed `Escape` while already in Normal mode on the modified unnamed
  scratch buffer and confirmed that nothing happened.
- This is intentional: the custom Normal-mode `Escape` save only runs for a
  named, modified, ordinary file buffer.
- Curriculum 3.3 remains open until the named-file auto-save case is practiced.
- Hamel ran `:saveas /tmp/nvim-warrior-practice-20260710.txt` and confirmed that
  the scratch buffer was named and saved outside the project repository.
- Hamel then inserted `!`, pressed `Escape` once to leave Insert mode, and
  confirmed that `[+]` appeared beside the filename. This marker means the
  in-memory buffer differs from the saved file on disk.
- Hamel pressed `Escape` again in Normal mode and confirmed that `[+]`
  disappeared. A filesystem check verified the `/tmp` file was updated.
- **Curriculum 3.3 complete:** unnamed buffers are ignored; the first `Escape`
  leaves Insert mode; a later Normal-mode `Escape` saves a named, modified,
  ordinary file buffer.
- **Next:** Curriculum 3.4 — practice explicit save with `Space w`, then
  save-and-quit with `Space x`.

### Herdr Prefix Ergonomics Decision

- Hamel considered a Karabiner hold-`3` shortcut for Herdr's `Ctrl-b` prefix,
  then explicitly declined it before testing.
- No `3` remapping was retained. Herdr continues to use physical `Ctrl-b`.

### Explicit Save with Native `:w`

- Hamel created an unsaved change in the `/tmp` practice file, confirmed the
  `[+]` modified marker, then ran `:w` to save it.
- A filesystem check confirmed that `save-test` was written to disk.
- `:w` is Vim's native write command. The personal `Space w` mapping runs the
  same `:write` command.
- Curriculum 3.4 remains open until Hamel practices both `Space w` and
  `Space x`.

### Leader Save with `Space w`

- Hamel made another practice-file change, pressed `Space w`, and confirmed
  that the `[+]` modified marker disappeared.
- A filesystem check confirmed the new `another-test` line was written to the
  `/tmp` practice file.
- Curriculum 3.4 remains open only for save-and-quit with `Space x`.

### Leader Save-and-Quit with `Space x`

- Hamel pressed `Space x` in the practice-file workflow and confirmed that
  Neovim closed and returned to the Herdr shell.
- `Space x` runs `:x`: it writes when needed, then quits the current Neovim
  window.
- **Curriculum 3.4 complete:** both explicit save with `Space w` and
  save-and-quit with `Space x` were practiced.
- **Next:** Curriculum 3.5 — undo with `u`, redo with `Ctrl-r`, and repeat the
  last change with `.`.

### First Undo with `u`

- Hamel inserted `UNDO`, pressed `u` in Normal mode, and confirmed that the
  inserted text disappeared.
- Repeated `u` presses can walk backward through multiple change blocks; one
  continuous Insert-mode visit normally forms one change block.
- Curriculum 3.5 remains open for multi-step undo, redo with `Ctrl-r`, and
  repeat with `.`.

## 2026-07-11 — Session 002: Multi-Step Undo Setup

### Two Separate Change Blocks

- Hamel inserted `[ONE]` and `[TWO]` during two separate Insert-mode visits and
  confirmed that both markers appeared.
- The two Insert-mode visits create separate change blocks for the next undo
  checkpoint.
- Curriculum 3.5 remains open. Next, press `u` twice to remove `[TWO]` and then
  `[ONE]`, followed by `Ctrl-r` practice and the `.` repeat command.

## 2026-07-11 — Session 003: TypeScript/TSX Highlighting Recovery

### Goal

Restore full Nord syntax highlighting in a `.tsx` file without changing the
Neovim theme or configuration.

### Root Cause and Fix

- Nord was loaded and the filetype was correctly detected as
  `typescriptreact`; the colorscheme was not the problem.
- The installed Tree-sitter TypeScript/TSX parser state was stale or
  mismatched, so most TSX nodes fell back to the plain foreground color.
- Hamel ran `:TSInstall! typescript` first. This refreshed TypeScript parsing,
  but JSX tags still needed the separate TSX parser.
- Hamel then ran `:TSInstall! tsx` and confirmed that the complete TSX syntax
  coloring returned.
- Mental model: Nord chooses the colors, while Tree-sitter identifies which
  pieces of code receive those colors. A `.tsx` file needs both its TypeScript
  and JSX-aware TSX parsing layers.

### Command-Mode Correction

- `:TSInstall!` is an Ex command: leave Insert mode, press `:`, type the command
  in the command line, and press `Enter`.
- During the repair, command text was accidentally inserted into the source
  buffer instead. Normal-mode `u` is the first recovery tool before saving.
- A disk check found the accidental suffix `:TSInstall! tsxuu` on the final
  export line of `apps/mission-control/components/ui/progress.tsx`. That project
  cleanup remains pending and must be reviewed before any write.

### Curriculum and Next Step

- **Optional Curriculum 6.D4 complete:** Hamel recovered TypeScript/TSX
  highlighting by reinstalling the parsers in dependency order.
- The main curriculum checkpoint remains **3.5**: undo, redo, and repeat.
- Immediate safety step: remove only the accidental TSX command suffix and
  verify the project diff before moving to completion or formatting setup.

### Accidental Source Edit Cleaned

- Removed only the accidental `:TSInstall! tsxuu` suffix from
  `apps/mission-control/components/ui/progress.tsx`.
- Verified that `progress.tsx` now matches its Git version with no remaining
  diff.
- No unrelated `cortana-services` changes were modified.

## 2026-07-12 — Session 004: Manual Multi-Language Formatting

### TSX Formatting Confirmed

- Added JavaScript, JSX, TypeScript, and TSX mappings from Conform to
  project-local Prettier.
- Added a root `prettier.config.mjs` bridge in `cortana-services` so editor
  discovery reaches the shared 120-column configuration.
- Hamel reloaded Conform, pressed `Space p` on an intentionally misindented TSX
  prop, and confirmed that Prettier corrected the indentation.
- Mental model: `Space p` asks Conform to select a formatter from the current
  buffer's filetype. It changes the in-memory buffer; `Space w` writes that
  result to disk.
- **Optional Curriculum 6.D5 complete:** manual TSX formatting was practiced
  and confirmed.

### Command-Entry Safety Reinforced

- `:Lazy reload conform.nvim` was briefly typed into the TSX buffer as well as
  run from the command line.
- A disk check confirmed the command text was not saved. Normal-mode `u`
  removed the accidental buffer insertion before formatting continued.

### Dedicated Markdown and Python Formatters Staged

- Hamel chose not to make Markdown depend on Prettier.
- Markdown now maps to dedicated `mdformat`; Python maps to Ruff's formatter.
- Both tools are installed with `uv`. The Markdown tool includes GFM,
  frontmatter, footnote, alert, and wikilink plugins.
- Safety finding: plain `mdformat` escapes Obsidian `[[wikilinks]]`. Adding
  `mdformat-wikilink` preserved normal links, aliases, headings, block links,
  and embeds in an isolated test.
- Headless Conform checks found both formatters and formatted isolated buffers
  successfully. Curricula 6.D6 and 6.D7 remain open until Hamel practices each
  mapping in Neovim.

### Next Checkpoint

- Reload Conform, then test `Space p` on one harmless Markdown formatting
  change. Test Python separately afterward.
- Format-on-save and ESLint remain intentionally unchanged.

### Project Formatting Rules vs Neovim Wiring

- The project owns formatting style such as `printWidth`, wrapping, and
  trailing commas in `packages/tooling/prettier/config.mjs`.
- The root `prettier.config.mjs` only exposes that shared configuration to
  editor discovery and normally should not need editing.
- Neovim owns formatter selection and editor behavior in
  `config/nvim/lua/plugins/lsp.lua`, including filetype mappings, `Space p`,
  and any future format-on-save setting.
- Rule of thumb: change style in the project; change formatter wiring in the
  Neovim configuration. Project rule changes apply on the next `Space p`;
  Neovim wiring changes require a plugin reload or restart.

### Markdown Formatting Confirmed

- `:ConformInfo` confirmed `mdformat` was ready for the Markdown buffer at
  `~/.local/bin/mdformat`.
- A failed Lazy reload used the accidental plugin name `conform.nvim.` with a
  trailing period. The exact plugin name is `conform.nvim`.
- Indenting `- Links:` can turn it into a nested list item, so `mdformat`
  preserves that semantic structure instead of guessing that the indentation
  was accidental.
- The reliable formatting sequence is: make the test edit in Insert mode,
  press `Ctrl-c` to return to Normal mode, then press `Space p`.
- Hamel tested the unambiguous heading `##   Open`; `Space p` normalized it to
  `## Open` and confirmed that dedicated Markdown formatting works.
- **Optional Curriculum 6.D6 complete:** manual Markdown formatting was
  practiced and confirmed.

### Normal-Mode Corrections

- Pressing `q` in a normal file buffer starts macro recording; the
  `recording @u` indicator was stopped safely with another `q`.
- `Space p` formats; it is not an end-of-line or file-navigation command, and
  the cursor can move when formatting rewrites nearby text.
- `G` jumps to the end of the file. `Ctrl-p` does not.

### Next Checkpoint

- Practice `Space p` once on an isolated Python buffer so Curriculum 6.D7 can
  be confirmed.
- Format-on-save and ESLint remain intentionally unchanged.

## 2026-07-12 — Session 005: TypeScript Language Intelligence

### LSP Mental Model Corrected

- `nvim-lspconfig` provides the framework for connecting language servers; it
  is not one universal server for every language.
- The initial configuration enabled only `gopls` for Go and `lua_ls` for Lua.
  Tree-sitter highlighting, Blink buffer suggestions, and Prettier formatting
  made TypeScript feel partially intelligent without a TypeScript LSP client.
- Chose `vtsls` over `typescript-tools.nvim` because it integrates directly
  with the existing native LSP configuration and keeps the plugin set small.
- Installed Homebrew's `vtsls` 0.3.0 and configured it to use each workspace's
  project-local TypeScript version.

### Live Diagnostic Confirmed

- A headless check attached `vtsls` at the `cortana-services` monorepo root and
  reported `Cannot find name 'someVariable'` on line 98.
- Hamel restarted Neovim and confirmed a red `E` beside line 98. The `E` is an
  error-severity diagnostic sign; `E:1` in the status line means the current
  buffer contains one error.
- The test line is an undeclared assignment, so TypeScript reports it. A
  declared-but-unused variable would instead be reported by the configured
  ESLint rule when ESLint runs.
- **Optional Curriculum 5.D4 complete:** TypeScript LSP attachment and live
  diagnostics were practiced and confirmed.

### Safety and Next Checkpoint

- ESLint LSP remains separate and disabled; `vtsls` supplies TypeScript and
  JavaScript diagnostics, completion, hover, and code navigation.
- The temporary `someVariable = 10;` test line was saved during the check. A
  final disk check confirmed that Hamel removed it and the project file once
  again matches Git.
- On the next live diagnostic, place the cursor on its line and open the detail
  with `Ctrl-w d`.

## 2026-07-12 — Session 006: ESLint and Git Signs

### Shared Monorepo ESLint Configuration

- Installed `vscode-eslint-language-server` through Homebrew and enabled the
  native `eslint` client alongside `vtsls`.
- Cortana Services has no root ESLint config by design. Each of its eleven
  JavaScript/TypeScript workspaces has an `eslint.config.mjs` that re-exports a
  profile from `@cortana/tooling`.
- Kept nvim-lspconfig's monorepo defaults: one client roots at the repository's
  `pnpm-lock.yaml`, while `workingDirectory = auto` resolves the nearest
  workspace config and project-local ESLint library for each file.
- Automatic ESLint fixes on save remain disabled. Prettier through Conform
  continues to own JavaScript and TypeScript formatting.

### Cross-Workspace Verification

- Audited all eleven workspace configs and confirmed that the shared
  `@typescript-eslint/no-unused-vars` rule is enabled as an error.
- Headless Neovim probes produced the same live unused-variable diagnostic in
  Mission Control, Service API, and the shared library, covering the Next app,
  Node app, and Node library profiles.
- Root-level `scripts/*.ts` files remain outside ESLint because the repository
  does not include them in a root config or root lint target.

### Live Signs Confirmed

- Hamel restarted Neovim with a temporary unused `const someVar = 10;` line and
  confirmed a red `E` diagnostic sign.
- The status line showed `E:1 H:1`: `E:1` means one diagnostic error, while
  `H:1` means Gitsigns sees one changed Git hunk.
- `H` tracks the working-tree difference and does not describe code validity;
  `E` comes from an attached language or lint server.
- **Optional Curriculum 6.D8 complete:** live ESLint diagnostics and the
  difference between lint and Git signs were practiced and confirmed.

### Safety and Next Checkpoint

- Remove the temporary `someVar` declaration and save the file. Its `E` and
  this file's `H` should disappear once the buffer is clean and matches Git.
- The main curriculum still resumes at 3.5: finish redo with `Ctrl-r` and
  repeat with `.`.

## 2026-07-13 — Session 007: LazyGit Repository Root

### Root Cause

- `Space g` called `Snacks.lazygit()` without a working directory, so LazyGit
  started from Neovim's `:pwd` instead of the repository containing the current
  file.
- When `:pwd` was `/Users/hameldesai`, LazyGit correctly reported that it was
  outside a Git repository. Pressing `N` declined repository creation and
  opened LazyGit's recent-repositories flow; it did not fix the launch root.
- Oil needed separate handling because its buffer name is an `oil://` URI, not
  a normal filesystem path.

### Configuration Fix

- `Space g` now resolves the Git root from the current normal file or from the
  directory currently displayed by Oil, with Neovim's working directory only
  as a fallback.
- Headless checks resolved a Cortana Services TypeScript buffer to
  `/Users/hameldesai/Developer/cortana-services` and the dotfiles Oil view to
  `/Users/hameldesai/Developer/dotfiles-hd`.
- Curriculum 8.6 remains open until Hamel restarts Neovim, presses `Space g`,
  and confirms that the LazyGit dashboard opens without the repository-creation
  prompt.

### Live Confirmation

- **Curriculum 8.6 complete:** after restarting Neovim, Hamel pressed
  `Space g` and confirmed that LazyGit opened the correct repository dashboard
  without the repository-creation prompt.
- The dashboard's Files panel shows repository changes and the Diff panel
  previews the selected change.
- The main curriculum still resumes at 3.5: finish redo with `Ctrl-r` and
  repeat with `.`.

## 2026-07-14 — Session 008: Go to Definition (LSP)

### Goal

Learn to jump to a symbol's definition with `gd` and return, as Hamel
requested (Curriculum 5.3), ahead of the main 3.5 checkpoint.

### Mental Model

- `gd` in Normal mode jumps to the definition of the symbol under the cursor.
- In this config `gd` runs `Snacks.picker.lsp_definitions()`: with a single
  definition it jumps straight there; with several it opens a Snacks picker to
  choose one.
- `gd` relies on an attached language server, not Tree-sitter. Go uses `gopls`,
  Lua uses `lua_ls`, and JavaScript/TypeScript use `vtsls`. In a plain-text or
  Markdown buffer there is no definition to resolve, so `gd` does nothing.
- Return the way you came with `Ctrl-o` (older jump) and go forward again with
  `Ctrl-i` — the same jump list practiced in Curriculum 2.5.
- Related keys for later in Lesson 5: `gh` hover (5.2), native `grr` references
  (5.4), and `Space S` workspace symbols (5.5).

### Confirmed

- **Curriculum 5.3 complete:** Hamel opened a real code file, pressed `gd` on a
  symbol, confirmed the jump to its definition, and returned with `Ctrl-o`.
- Mental model reinforced: `gd` relies on the attached language server
  (`gopls`, `lua_ls`, or `vtsls`), and `Ctrl-o` returns via the jump list.
- Main checkpoint unchanged at 3.5 (undo, redo, repeat); 5.3 was an explicit
  detour Hamel chose. Lesson 5 otherwise remains open (next: `gh` hover in
  5.2, `grr` references in 5.4).

### Bufferline Added (Zed-style tab strip)

- Hamel asked how to get the VSCode/Zed tab strip. Mental model taught:
  Zed/VSCode file tabs map to Neovim **buffers** (already navigable with `H`,
  `L`, and `Space b`). Neovim's own `:tab` pages are whole window layouts, not
  per-file tabs, so they are the wrong tool for this.
- The config had no tab bar (no bufferline/tabline; `showtabline` was default).
- Added `akinsho/bufferline.nvim` in
  `config/nvim/lua/plugins/bufferline.lua`. It renders open buffers as a visual
  tab strip, reuses the existing `mini.icons` through
  `mock_nvim_web_devicons()` (no second icon plugin), shows `nvim_lsp`
  diagnostics per tab, and sets `showtabline = 2` so the bar is always visible.
- `H` and `L` (`bnext`/`bprevious`) already move along the strip in buffer
  order, so no remap was needed. `Space d` closes a buffer and removes its tab.
- **Optional Curriculum 7.D5 complete:** Hamel restarted Neovim, saw the tab
  strip of open buffers appear across the top, and confirmed it looks good with
  the transparent Nord theme. `H`/`L` move along the strip.

### Auto-Reload of External Edits (agent workflow)

- Hamel's work layout: Cursor agents (right), Neovim in Herdr (middle), browser
  (left). Both the agent and Neovim edit the same files, so the filesystem is
  the shared source of truth.
- Mental model: Neovim edits a buffer (in-memory copy). When the agent writes
  the file on disk, the buffer goes stale. `autoread` reloads unmodified
  buffers, but only when Neovim actually checks; Neovim does not poll.
- Added `autoread` plus an autocmd that runs `:checktime` on `FocusGained`,
  `BufEnter`, `CursorHold`, and `TermLeave` (real file buffers only), and a
  `FileChangedShellPost` notification, in `config/nvim/lua/config/options.lua`.
  Added `Space r` (`:checktime`) in `keymaps.lua` for on-demand reload.
- Safety: only unmodified buffers auto-reload; a buffer with unsaved edits still
  raises Neovim's `W12` warning instead of losing work.
- Headless verification on `README.md`: appended a marker to the file on disk,
  ran `:checktime`, and confirmed the buffer reloaded (151 -> 152 lines, last
  line = the marker, still unmodified). Restored the file afterward.
- Added optional Curriculum 7.D6; it stays open until Hamel sees a live external
  edit reload in his running Neovim.

### Real-World Recovery: Accidental README Save

- `README.md` on disk had been corrupted by an accidental edit saved from the
  live Neovim: a duplicated "Current Personal Mac Symlinks" section, an
  "iintentionally" typo, and a merged line. It was already 151 lines before the
  auto-reload test, so the test did not cause it.
- Recovered with `git restore README.md`, returning it to the committed
  124-line version (commit 0d4fe7e). The git safety net made the clean copy one
  command away.
- Live-buffer caution: after restoring the file on disk, reload it in the
  running Neovim with `:e!` before saving, or the stale buffer would re-save the
  corruption. The Escape-to-save mapping makes accidental saves easy, so
  `:e!` / `Space r` and gitsigns review are the guardrails.

### Gitsigns: Signs vs Diagnostics, and Contrast Tuning

- Clarified two overlapping gutter systems on a changed line in a work TSX file:
  - `E` (and status `E:1`) is an LSP diagnostic from vtsls/ESLint about code
    validity (e.g. an unused `const thisIsATest = 10`), not gitsigns.
  - Gitsigns shows `H:1` in the status line (changed hunks) and the
    "Not Committed Yet" current-line blame; its change marker is the gutter `▎`.
- Sign priority: with a single `signcolumn`, the diagnostic sign outranks the
  gitsigns bar, so a line with an error shows `E`, not the bar. This reinforces
  the Session 006 `E` (code validity) vs `H` (git change) distinction.
- Contrast tuning: the gitsigns bars were hard to see on the transparent Nord
  background. Added explicit high-contrast highlights in
  `config/nvim/lua/plugins/colorscheme.lua` `on_highlights`: `GitSignsAdd`
  `#a3be8c` (green), `GitSignsChange` `#88c0d0` (cyan), `GitSignsDelete`
  `#bf616a` (red), with transparent bg. Verified they survive gitsigns' default
  links (gitsigns sets highlights with `default = true`, so explicit
  definitions win).
- **Curriculum 8.5 complete:** after restarting Neovim, Hamel confirmed he can
  see the gitsigns change bar in the gutter (on an uncommitted line in README)
  alongside the "Not Committed Yet" current-line blame. The contrast tweak made
  the bar visible; green = add, cyan = change, red = delete.

### Clipboard Path Keymaps

- The verbose `:let @+ = expand('%:p')` commands were hard to remember, so we
  turned them into discoverable keymaps in `config/nvim/lua/config/keymaps.lua`,
  listed by WhichKey under `Space y`:
  - `Space y p` -> yank the current file's full path (`expand('%:p')`)
  - `Space y d` -> yank the working directory / pwd (`getcwd()`)
  - `Space y f` -> yank the current file's folder (`expand('%:p:h')`)
- Each writes to the `+` (system clipboard) register and shows a "Copied ..."
  toast for feedback. Nothing to memorize: press `Space y` and WhichKey shows
  the choices. All three maps verified registered with their descriptions.

### Snacks Explorer Sidebar (Zed/VSCode-style)

- Clarified that Oil is a buffer-as-directory editor (`Space h`), not a
  persistent sidebar. For a Zed/VSCode-style file tree, added the Snacks
  explorer, which already ships with snacks.nvim (no new plugin).
- Enabled with `explorer = { replace_netrw = false }` in
  `config/nvim/lua/plugins/navigation.lua` so Oil stays the directory handler
  and the explorer never hijacks directory buffers. Bound `Space e` to
  `Snacks.explorer()`.
- Oil (`Space h`) and the explorer (`Space e`) now coexist: Oil for fast
  buffer-based edits, the explorer for a persistent browsing sidebar.
- **Optional Curriculum 9.D4 complete:** Hamel opened the sidebar with `Space e`
  and used it alongside Oil.
- Focus-navigation gotcha (also documented in `config/nvim/README.md` so it is
  easy to find): from the tree, `Space l` / `Ctrl-l` moves focus to the editor,
  and `Ctrl-h` moves focus back to the tree. There is no `Space h` for
  window-left because `Space h` opens Oil, so the return key is `Ctrl-h`.
  `Space e` again closes the sidebar.
- **Hidden files gotcha (dotfiles):** the sidebar and Oil are two different
  explorers with different defaults. Oil shows dotfiles because we set
  `view_options.show_hidden = true`; the Snacks explorer defaults to
  `hidden = false` and `ignored = false`, so `.zshrc`, `.config/`, and anything
  in `.gitignore` are filtered out of the tree (the file itself is untouched —
  only the sidebar hides it). Toggle live in the tree with `H` (dotfiles) and
  `I` (gitignored). Made dotfiles show by default via
  `picker.sources.explorer = { hidden = true, ignored = false }` in
  `navigation.lua`, so the sidebar now matches Oil while still hiding gitignored
  noise. Verified `Snacks.config.picker.sources.explorer.hidden == true`.

### GraphQL Language Server (research + setup + bugs)

Goal: add a GraphQL LSP for `.graphql` files, reproducibly on any machine.

- Research decision: use the official `graphql-language-service-cli` (binary
  `graphql-lsp`), the same engine VSCode's official GraphQL extension uses.
  Rejected alternatives: `@0no-co/graphqlsp` (a TypeScript plugin for embedded
  ``gql`` in `.ts/.tsx`, configured via `tsconfig` - complements, does not cover
  standalone `.graphql` files) and Apollo's LSP (needs `apollo.config.json`,
  which the repo does not use). The `resilience-pargasite` repo already has a
  root `graphql.config.ts` and `@apollo/client`, so the official server gets
  full schema-aware features via that config.
- BUG #1 (install location): `npm i -g` invoked through the Homebrew Node keg
  execpath installed `graphql-lsp` into `/opt/homebrew/Cellar/node/<version>/bin`
  - not on `PATH`, and it would vanish on the next `node` upgrade. Root cause:
  fnm shadows the `PATH` `node`, and npm's global prefix follows the invoking
  node's execpath, so global installs are node-version-specific.
- FIX: install to a fixed, node-version-independent prefix and reference it by
  absolute path (no `PATH` edits, no Homebrew pollution, survives Node upgrades):
  `npm install -g --prefix "$HOME/.local/graphql-lsp" graphql-language-service-cli`.
  Binary lands at `~/.local/graphql-lsp/bin/graphql-lsp`.
- Config: `config/nvim/lua/plugins/lsp.lua` defines `graphql` with an absolute
  `cmd` (`~/.local/graphql-lsp/bin/graphql-lsp server -m stream`) and
  `filetypes = { "graphql" }` (scoped to `.graphql`; keeps it off the tsx/jsx
  buffers that already run vtsls + ESLint). Added `graphql` to the Tree-sitter
  parser and filetype lists in `config/nvim/lua/plugins/editor.lua` and compiled
  the parser.
- Verification: opening the real `RiskIntelligence.graphql` attaches the
  `graphql` client rooted at the repo (where `graphql.config.ts` lives), with no
  errors in the LSP log; filetype is `graphql` and Tree-sitter highlighting is
  active. The `.ts` config-loading concern did not materialize.
- Reproducibility: install command documented in
  `setup/mac-resilience/README.md` (dependency + verify steps) and in
  `config/nvim/README.md` requirements. Schema-aware completion/validation
  depends on the project's `graphql-config`; that is a work-repo concern and was
  not modified.
- **Curriculum 5.D5 complete:** confirmed live schema-aware validation. Opening
  a query with unused variables surfaced real diagnostics - `Variable "$limit"
  is never used in operation "GetClientQuestionnaire"` (same for `$offset` and
  `$order_by`) - proving `graphql-lsp` parses operations against the schema
  resolved from the repo's `graphql.config.ts`. The messages now show inline via
  virtual text.

### Diagnostics: Inline Messages + Picker

- Reading diagnostics only through the `Ctrl-w d` float was tedious. Two
  additions (work for any source: eslint, vtsls, graphql):
  - Enabled inline `virtual_text` in `vim.diagnostic.config`
    (`config/nvim/lua/plugins/lsp.lua`): `{ spacing = 2, source = "if_many" }`,
    so the message shows at the end of the offending line (VSCode/Zed-style),
    naming the source when more than one server reports on a line.
  - Added Snacks diagnostics-picker keymaps in
    `config/nvim/lua/plugins/navigation.lua`: `Space c d` (current buffer) and
    `Space c D` (project) - a searchable problems list with preview, matching
    the other Snacks pickers.
- Other built-in ways recorded in the README: `]d` / `[d` jump to the next /
  previous diagnostic; `Ctrl-w d` still opens the detail float.

### Tier 1 + 2 Additions: More LSPs, SchemaStore, Auto-Pairs, Surround

- Tier 1 (free - the servers already shipped with `vscode-langservers-extracted`,
  installed for ESLint): enabled `jsonls`, `cssls`, and `html` in `lsp.lua`.
  Added `b0o/schemastore.nvim` and wired `jsonls` to
  `require('schemastore').json.schemas()` for schema-aware `package.json` /
  `tsconfig.json` completion and validation. Verified `jsonls` attaches to a
  `.json` buffer.
- Tier 2:
  - Installed `bash-language-server` via Homebrew (added to the Brewfile) and
    enabled `bashls`; verified it attaches to a `.sh` buffer. High value given
    how much shell the dotfiles and `hd-*.sh` launchers involve.
  - Added `mini.pairs` (auto-close brackets/quotes on `InsertEnter`) and
    `mini.surround` for add/change/delete of surrounding pairs, under a `gs`
    prefix so the native `s` (substitute) is preserved: `gsa` add, `gsd` delete,
    `gsr` replace, `gsf`/`gsF` find, `gsh` highlight.
- Reproducibility: `bash-language-server` in the Brewfile and the verify step;
  `schemastore.nvim` / `mini.pairs` / `mini.surround` pinned in
  `lazy-lock.json`; all documented in the Neovim README. `jsonls`/`cssls`/`html`
  need no new install.
- Added optional Curriculum 4.D4 (surround); it stays open until Hamel practices
  `gsa`/`gsd`/`gsr` and confirms.

### Statusline (lualine, Tier 3)

- Replaced Neovim's built-in statusline with `nvim-lualine/lualine.nvim`. Nord
  theme, `globalstatus = true` (one bar at the bottom, `laststatus = 3`).
  Sections: mode | git branch + diff (from Gitsigns' buffer data) | filename
  (relative) | diagnostics + attached LSP client(s) + filetype | encoding |
  line:col + progress. Reuses `mini.icons` for filetype icons.
- Biggest gains over the default bar: git branch/diff, the attached LSP names,
  and a colored mode indicator. Per Hamel, format-on-save stays off.
- Verified lualine loads with no theme errors and owns the statusline
  (`laststatus = 3`); pinned in `lazy-lock.json`.

### Markdown Rendering (render-markdown.nvim, Tier 3)

- Added `MeanderingProgrammer/render-markdown.nvim` for in-editor Markdown
  rendering: headings, `- [ ]`/`- [x]` as ☐/✓, code blocks, tables, and quotes.
  Loads on the `markdown` filetype; `Space m` toggles raw vs rendered. Reuses the
  already-installed markdown Tree-sitter parsers and `mini.icons` (no
  nvim-treesitter dependency added, since the config uses a forked
  `neovim-treesitter/nvim-treesitter`).
- Hamel tested it on `CURRICULUM.md` / `AGENTS.md` and chose to keep it.
- Aside during testing: a stale Neovim swap for `AGENTS.md` (from a killed
  session) plus an accidental `config/fastfetch` -> `config/` edit were cleaned
  up with `git restore` and by removing the swap; `:e!` reloads the clean buffer.
  Reminder: cleanly `:qa` sessions to avoid leftover swap prompts.

### Guarded Escape-to-Save (accidental-edit fix)

- After the README and AGENTS.md accidental-save incidents, guarded the
  Normal-mode Escape-to-save so it only writes changes actually made in Insert
  mode (`config/nvim/lua/config/keymaps.lua`). An `InsertLeave` autocmd sets a
  per-buffer `save_on_esc` flag when the buffer was really edited, `BufWritePost`
  clears it, and the `<Esc>` mapping saves only when the flag is set.
- Effect: a stray Normal-mode edit (fat-finger `dw`, `x`, paste, etc.) is no
  longer silently written on the next Escape. Deliberate Insert-mode edits still
  auto-save on the second Escape as before, so the muscle memory is unchanged.
- Trade-off: an intentional Normal-mode edit (e.g. `dd`) now needs a manual
  `Space w`. Verified on a scratch file: an `x` edit leaves `save_on_esc` unset
  (guard skips), while `iHELLO<Esc>` sets it (guard saves).
- Added a "Saved <file>" toast (via the Snacks notifier) when the Escape
  auto-save fires, so the automatic write is visible instead of silent.

### Free Snacks Modules (bigfile, words, indent)

- Enabled three already-bundled Snacks modules in
  `config/nvim/lua/plugins/navigation.lua` (no new plugins):
  - `bigfile` - disables heavy features (LSP, Tree-sitter, etc.) on very large
    files so they stay responsive.
  - `words` - highlights the other occurrences of the symbol under the cursor.
  - `indent` - indent guides plus current-scope highlighting.
- Verified all three report `enabled = true` and the config loads clean.

### Tree-sitter Folding + Space z Keys

- Enabled structure-aware folding in `config/nvim/lua/config/options.lua`:
  `foldmethod = expr`, `foldexpr = v:lua.vim.treesitter.foldexpr()`, and
  `foldlevel`/`foldlevelstart = 99` so files open fully unfolded (fold on
  demand). Verified a real Lua file computes fold levels (max depth 8).
- Added discoverable Space z fold maps in `keymaps.lua`: `Space z a` toggle fold,
  `Space z o` open all, `Space z c` close all. Native `za` / `zR` / `zM` still
  work.

### Centered Cursor (scrolloff = 999)

- Set `scrolloff = 999` in `config/nvim/lua/config/options.lua` so the cursor
  line stays vertically centered while moving up/down (the "always-centered"
  look from the video). Left `sidescrolloff = 8`. It is a reversible one-liner;
  a toggle between `999` and `8` is the fallback if it feels like too much.

### Start Dashboard (Snacks)

- Enabled the Snacks `dashboard` (start screen shown when Neovim opens with no
  file) in `config/nvim/lua/plugins/navigation.lua`: a custom NVIM header, a
  shortcut menu wired to the existing tools (`f` files, `/` grep, `r` recent,
  `e` explorer, `n` new, `g` LazyGit, `c` config, `l` Lazy, `q` quit), a
  recent-files section, and startup stats. No new plugin (Snacks module).
  Verified it reports enabled and `Snacks.dashboard.open()` runs without error.
- This is separate from the lazy.nvim install UI, which only appears on a fresh
  machine when plugins need installing.
- **Header = fastfetch anon mask.** Replaced the block "NVIM" banner with the
  Guy Fawkes / anon mask from `config/fastfetch/logo-anon.txt` (the same logo
  fastfetch renders). Instead of copy-pasting the Braille art, the header is read
  at startup by `anon_header()` in `navigation.lua`: it resolves the real path of
  `~/.config/nvim` (a symlink into the dotfiles repo) with `vim.fn.resolve`, walks
  up to `config/fastfetch/logo-anon.txt`, reads it, and strips fastfetch's `$N`
  color codes with `gsub("%$%d+", "")`. This keeps a single source of truth (edit
  the logo once, both fastfetch and the dashboard update) and stays reproducible
  because it reads from the repo, not `~/.config/fastfetch` (which the work Mac
  does not symlink). Falls back to `"NVIM"` if the file is missing. The dashboard
  renders it in one highlight color (fastfetch's per-line gradient is dropped).

### PDF and Image Viewing (Snacks)

- Neovim does not render PDFs by itself. The already-installed Snacks plugin
  can convert and display images and PDF pages inside terminals that support
  the Kitty graphics protocol; Ghostty is supported.
- Enabled the Snacks `image` module in
  `config/nvim/lua/plugins/navigation.lua`. Opened images and PDFs are rendered
  as read-only views, so this does not turn the binary file into editable text.
- Added ImageMagick (`magick`) and Ghostscript (`gs`) to the Resilience
  Brewfile and verification loop. ImageMagick performs conversion; Ghostscript
  is specifically required for PDF rendering.
- Herdr needed `experimental.kitty_graphics = true` before the converted image
  could reach Ghostty. Hamel restarted Herdr and confirmed real PDFs rendered.
- Explorer preview had queued conversions for every highlighted PDF. Set its
  previewer to `none`; pressing `Enter` still opens the selected PDF directly.
- Very tall PDFs produced graphics frames above Herdr's 32 MB limit. Reduced
  PDF conversion to 120 DPI and capped output at 1920x1080. A measured example
  dropped from 4.9 seconds to 1.5 seconds.
- Snacks is useful as a quick read-only preview, but it lacks proper zoom,
  search, and page navigation. Added `Space o` using `vim.ui.open()` to open the
  current file in its default macOS app; PDFs normally open in Preview.
- **Optional Curriculum 10.D6 complete:** Hamel opened real PDFs in
  Herdr/Ghostty and distinguished the rendered preview from a full PDF reader.

### Oil and Explorer Entry Points

- `nvim .` starts Neovim with the current directory as its target, so Oil opens
  that directory in the main editing window.
- `Space e` toggles the separate Snacks explorer sidebar, intended to remain
  visible beside a file while editing.
- Keep both workflows, but normally use one at a time: use `nvim .` or
  `Space h` for full-window directory work, then use `Space e` when a persistent
  sidebar is useful beside an open file.

### Warrior Gap Assessment

- The config already has enough tools. Adding more plugins now would produce
  less benefit than building fast, durable editing habits.
- Highest-leverage gaps: safe recovery and repeat (`u`, `Ctrl-r`, `.`), Vim's
  operator-plus-motion grammar, text objects, registers, macros, multi-file
  edits, and completing real search-edit-test-Git loops inside Neovim.
- The next checkpoint remains Curriculum 3.5: finish undo/redo/repeat before
  moving into Lesson 4's motions, operators, and text objects.

### Maintenance: Safe Escape Auto-Save and Config Cleanup

- Kept Hamel's preferred Normal-mode `Escape` auto-save for Insert-mode edits.
- Corrected the guard to compare Neovim's per-buffer `changedtick`. If a Normal
  command changes the buffer before saving, `Escape` now refuses to write it;
  use `Space w` after checking the edit.
- Removed the obsolete Mini Surround `gsn` option. The installed plugin no
  longer supports that setting, so it never created a keymap.
- Confirmed the Bash and GraphQL language servers are installed. An LSP is the
  background helper that provides code errors, completion, hover details, and
  go-to-definition for its language.
- Ran StyLua on the dashboard actions in `navigation.lua`.

### Maintenance: pnpm-only GraphQL LSP installation

- Superseded Session 008's npm install command. The GraphQL LSP is now installed
  with pnpm under the same fixed `~/.local/graphql-lsp` home.
- The stable Neovim entry point remains
  `~/.local/graphql-lsp/bin/graphql-lsp`; changing package managers does not
  change the LSP keymaps or behavior.
- npm and npx remain available for Node ecosystem compatibility, but pnpm is the
  default installer for JavaScript/TypeScript packages and global tools.

## 2026-07-16 — Session 009: Undo, Redo, and Repeat

### Safe Scratch Buffer

- Resumed the main curriculum at 3.5 after the intervening configuration deep
  dives.
- Hamel pressed `Space n` and confirmed that a blank unnamed buffer opened.
- Next: create two separate Insert-mode change blocks, then practice repeated
  `u`, `Ctrl-r`, and `.` without touching a real file.

### First Change Block

- Hamel inserted `[ONE]` and returned to Normal mode.
- Clarification: an unnamed buffer has no disk path, so `[ONE]` remains only in
  Neovim memory unless the buffer is later given a filename.
- Next: create `[TWO]` during a second Insert-mode visit so each marker has its
  own undo block.

### Second Change Block

- Hamel inserted `[TWO]` during a separate Insert-mode visit and confirmed that
  `[ONE][TWO]` were both visible.
- Because the markers came from separate Insert-mode visits, Normal-mode `u`
  should undo `[TWO]` first while leaving `[ONE]` intact.

### First Multi-Step Undo

- Hamel pressed `u` once and confirmed that the newest change block, `[TWO]`,
  was undone while `[ONE]` remained.
- Next: press `u` again to walk one more step backward and remove `[ONE]`.

### Repeated Undo Confirmed

- Hamel pressed `u` a second time and confirmed that `[ONE]` disappeared,
  leaving the scratch buffer blank.
- Mental model: each Normal-mode `u` walks backward by one change block, so two
  separate Insert-mode visits required two undo presses.
- Next: use `Ctrl-r` to redo the change blocks one at a time.

### `r` Versus `Ctrl-r`

- Hamel asked what plain `r` does before practicing redo.
- In Normal mode, `r{character}` replaces the single character under the cursor
  and stays in Normal mode. For example, `rX` replaces the current character
  with `X`.
- `Ctrl-r` is unrelated to replacement; it walks forward through changes that
  were undone.
- Added optional Curriculum 4.D5 for hands-on single-character replacement.
- The active 3.5 checkpoint remains one `Ctrl-r` press to restore `[ONE]`.

### Replacing a Whole Word

- Hamel asked whether plain `r` can replace an entire word.
- `r` is limited to one character. `ciw` means “change inside word”: it removes
  the word under the cursor and enters Insert mode for the replacement.
- Example: with the cursor anywhere in `hello`, `ciwgoodbye<Escape>` produces
  `goodbye`.
- Curriculum 4.4 remains unchecked until Hamel practices the text object.
- Return to Curriculum 3.5: press `Ctrl-r` once to restore `[ONE]`.

### First Redo Confirmed

- Hamel pressed `Ctrl-r` once and confirmed that `[ONE]` returned.
- Mental model: `Ctrl-r` walks forward through undone change blocks, one step
  per press.
- Next: press `Ctrl-r` once more to restore `[TWO]`.

### Repeated Redo Confirmed

- Hamel pressed `Ctrl-r` a second time and confirmed that `[ONE][TWO]` were
  visible again.
- Repeated `Ctrl-r` walks forward through the redo stack one change block at a
  time, mirroring repeated `u` in the opposite direction.
- Undo and redo are confirmed; Curriculum 3.5 remains open for `.` repeat.

### Preparing a Controlled Repeat

- Hamel pressed `0` in Normal mode and confirmed that the cursor moved to the
  first character of the line, the opening `[` in `[ONE][TWO]`.
- This previews the start-of-line motion from Curriculum 4.1 without marking
  that future lesson complete.
- Next: delete that opening bracket with `x` to create a simple repeatable
  change.

### Repeatable Change Created

- Hamel pressed `x` on the first `[` and confirmed that `[ONE][TWO]` became
  `ONE][TWO]`.
- That single-character deletion is now Neovim's most recent repeatable change.
- Next: move one character with `l`, then press `.` to repeat the deletion at
  the new cursor position.

### What `.` Repeats

- Hamel paused before pressing `.` and asked what it does.
- In Normal mode, `.` repeats the most recent text-changing command at the
  current cursor position.
- Cursor movement such as `l` is not a text change, so in this exercise `.`
  will repeat the earlier `x` deletion instead of repeating the movement.
- Curriculum 3.5 remains unchecked until Hamel performs and confirms `.`.

### Coding Use Case for `.`

- Hamel asked for a durable note and a coding use case for the dot command.
- Example: when several nearby lines contain the same extra comma, delete the
  first comma with `x`, move to the next extra comma, and press `.` to repeat
  the deletion there.
- `.` is best for repeating small mechanical edits. A project-wide semantic
  symbol rename should use the LSP rename workflow instead.
- Added `u`, `Ctrl-r`, and `.` plus this coding example to `README.md` for quick
  reference.

### Dot Repeat Confirmed

- Hamel moved one character right with `l`, pressed `.`, and confirmed that the
  earlier `x` deletion repeated at the new cursor position: `ONE][TWO]` became
  `OE][TWO]`.
- Curriculum 3.5 is complete: repeated `u`, repeated `Ctrl-r`, and `.` were all
  performed and confirmed in an unnamed scratch buffer.
- Next core checkpoint: Curriculum 3.6, safe yank, paste, and system clipboard.

### Safe Yank-and-Paste Scratch

- Hamel opened a fresh unnamed buffer with `Space n` for Curriculum 3.6.
- The buffer has no disk path, so the yank-and-paste exercise cannot overwrite
  a real file.
- Next: insert one practice line, then use `yy` and `p` to copy and paste it.

### Yank Practice Line

- Hamel inserted `alpha beta` into the unnamed buffer and returned to Normal
  mode.
- Next: press `yy` to yank the whole current line without changing its visible
  text.

### Whole-Line Yank Confirmed

- Hamel pressed `yy` and confirmed the yank.
- `yy` copies the entire current line without deleting it; the brief highlight
  comes from this config's `TextYankPost` feedback.
- Because this config sets `clipboard=unnamedplus`, the unnamed yank also goes
  to the macOS system clipboard.
- Next: press `p` to paste the line below the current line.

### Whole-Line Paste Confirmed

- Hamel pressed `p` and confirmed that the yanked `alpha beta` line was pasted
  below the current line.
- Because `yy` yanks a whole line, lowercase `p` pastes it on the next line.
- Next: paste into the Codex message box with macOS `Cmd-v` to verify the yank
  crossed the Neovim boundary through the system clipboard.

### macOS Clipboard Confirmed

- Hamel used `Cmd-v` in the Codex message box and confirmed that the same
  `alpha beta` text yanked with `yy` appeared outside Neovim.
- This verifies the full path: `yy` writes through `clipboard=unnamedplus` to
  the macOS clipboard, `p` pastes inside Neovim, and `Cmd-v` pastes in other
  applications.
- Curriculum 3.6 is complete. Next is 3.7: modified buffers and unsaved-change
  prompts.

### Modified Buffer Marker

- Hamel found `[+]` beside the unnamed buffer's name in the status line.
- `[+]` means the buffer contains changes that have not been written to disk;
  for this unnamed scratch, there is not yet a filename to write.
- Next: press `Space q` once. The normal `:quit` command should refuse to close
  the modified buffer and show a no-write warning, preserving the scratch.

### Unsaved-Change Refusal Confirmed

- Hamel pressed `Space q` and confirmed that Neovim refused to close the
  modified scratch buffer and displayed its no-write warning.
- `Space q` runs normal `:quit`; without `!`, Neovim protects unsaved work
  instead of silently discarding it.
- Curriculum 3.7 is complete. Next is 3.8: intentionally abandon only this
  known disposable scratch buffer with `:bd!`.

### Intentional Scratch Abandonment Confirmed

- Hamel ran `:bd!` and confirmed that the disposable modified scratch buffer
  closed and the previous buffer appeared.
- `bd` removes the buffer from Neovim; `!` explicitly discards that buffer's
  unsaved changes. It does not delete a named file from disk.
- Useful case: abandon accidental edits in a known disposable scratch or test
  buffer after carefully confirming the current buffer is the intended target.
- Added the safety note to `README.md` at Hamel's request.
- Curriculum 3.8 and all of Lesson 3 are complete. Next is Lesson 4.1: motions.

## 2026-07-16 — Session 010: In-File Search

### Search the Current File

- Hamel asked how to search the current file for the word `mason`.
- `/mason<Enter>` searches forward inside the current buffer. This is different
  from `Space /`, which searches file contents across the project.
- Curriculum 4.5 is being practiced early at Hamel's request and remains
  unchecked until `/`, `n`, and `N` are all performed and confirmed.
- First checkpoint: run `/mason<Enter>` in a file that contains `mason`.

### Cycle Through Search Matches

- Hamel asked how to move after the first in-file match.
- In Normal mode, `n` moves to the next match in the current search direction;
  `N` moves to the previous match in the opposite direction.
- Curriculum 4.5 remains unchecked until both directions are performed and
  confirmed.

### Current-File Diagnostics Detour

- Hamel asked how to view ESLint issues or warnings in the current file.
- `Space c d` opens the current buffer's diagnostics picker. It includes ESLint
  and any other attached diagnostic source, such as the TypeScript language
  server.
- `Space c D` is the project-wide version, but the first checkpoint is only the
  current-file picker.
- Curriculum 6.1 is being previewed early and remains unchecked until Hamel
  opens and reads a real diagnostic.

### Safe Current-File Replace

- Hamel asked how to replace every occurrence of a word such as `java` in the
  current file.
- Safe template: `:%s/\<java\>/replacement/gc`.
- `%` selects the whole file, `s` substitutes, `\<java\>` matches the exact
  word instead of text inside a larger word, `g` replaces every match on each
  line, and `c` asks for confirmation at every occurrence.
- At the confirmation prompt: `y` replaces, `n` skips, `a` replaces all
  remaining matches, and `q` or `Escape` stops.
- Normal-mode `u` can undo the substitution if the result is wrong.
- Added optional Curriculum 4.D6; it remains unchecked until Hamel practices
  the substitution safely and confirms the result.

### Easier Replacement Workflow Research

- Hamel rejected the `:%s/...` syntax as too cumbersome and asked for primary-
  source research into an easier workflow.
- Native fallback after `/java`: use `cgn`, type the replacement, press
  `Escape`, then press `.` for each next match. This reuses the dot-repeat skill
  from Curriculum 3.5 but remains one-at-a-time.
- Snacks provides grep but no replacement UI, and Kuncheng's current Neovim
  config does not include a search-and-replace plugin.
- Recommended option: add `grug-far.nvim` on `Space R`, prefilled with the word
  under the cursor and limited to the current file. It provides editable search
  and replacement fields plus a diff to review before applying changes.
- The earlier substitute command remains a fallback, not the preferred lesson.
  Revised optional Curriculum 4.D6 to track the visual workflow.
- Full primary-source findings are in `SEARCH_REPLACE_RESEARCH.md`. No plugin or
  keymap change has been made without Hamel's approval.

### Visual Replacement Installed for Testing

- With Hamel's approval, installed `grug-far.nvim` and added `Space R` as an
  experimental current-file replacement workflow.
- The mapping requires a named, saved file; it pre-fills the word under the
  cursor, the current file path, and exact literal whole-word flags, then puts
  the cursor in the Replace field.
- Headless validation confirmed Neovim startup, plugin loading, the `Space R`
  mapping, all prefills, current-file scope, exact-word flags, and replacement-
  field focus.
- Lazy's two unrelated plugin updates were removed; the lockfile adds only
  `grug-far.nvim`.
- No commit or push will happen until Hamel completes the live test and decides
  the workflow is useful. Curriculum 4.D6 remains unchecked until then.

### Safe Live Replacement Fixture

- Hamel opened `/tmp/nvim-replace-test.txt`, inserted
  `java javascript java`, and returned to Normal mode.
- The two standalone `java` words should match; the `java` inside `javascript`
  should remain untouched, proving the whole-word guard works.
- Next: save the temporary file before opening the disk-backed replacement UI.

### Replacement Fixture Saved

- Hamel saved `/tmp/nvim-replace-test.txt` with `:w` and confirmed the write.
- The cursor remains on the final standalone `java`, ready to test the
  word-under-cursor prefill.

### First Grug Far View and Visual Refinement

- Hamel pressed `Space R` and confirmed that Grug Far opened with `java`, the
  temporary file path, exact-word flags, and two matches. The `java` inside
  `javascript` was correctly excluded.
- Hamel found the default full-screen form visually noisy and asked for a more
  polished interface before continuing the usefulness test.
- Reworked the experimental UI into a centered rounded Nord panel with compact
  inputs, no example-text clutter, no fold gutter or result-number badge, and a
  footer showing `Space r` apply, `Space c` close, and `g?` help.
- Added Nord-specific result, diff, border, and input colors. The replacement
  behavior and current-file safety scope are unchanged.
- Headless validation confirmed the styled float, compact layout, replacement-
  field focus, two exact matches in one file, clean close, and no per-open
  hidden-buffer leak.
- Live visual approval and the actual replacement are still pending. Nothing
  has been committed or pushed.

### Refined Panel Approved

- Hamel reopened `Space R` and approved the centered compact Nord panel.
- The live screen showed search `test`, an active empty Replace field, the
  current temporary-file path, exact-word flags, and exactly two matches while
  leaving `javascript` unmatched.
- The actual replacement and post-apply file check remain before Curriculum
  4.D6 can be completed or the experimental config can be committed.

### Visual Current-File Replacement Confirmed

- Hamel entered `hi` as the replacement and applied it with `Space r`.
- Grug Far reported `replace completed`; the file reloaded from disk and showed
  `hi javascript hi`.
- Both standalone `test` matches changed while the text inside `javascript`
  stayed untouched, confirming the exact whole-word and current-file guards.
- Hamel completed optional Curriculum 4.D6. The tested config remains
  uncommitted until Hamel explicitly chooses to keep it.

### Workflow Accepted

- Hamel confirmed the workflow is useful and asked to keep, commit, and push
  the configuration and complete session notes.
- Best next core lesson remains Curriculum 4.1: word, line, file, and matching-
  pair motions.

### Resilience Work Mac Update Path

- Hamel asked how the new plugin reaches the already-configured Resilience work
  laptop.
- When `~/.config/nvim` already links to
  `~/Developer/dotfiles-hd/config/nvim`, run `git pull --ff-only` in the
  dotfiles repo, then `nvim --headless '+Lazy! restore' +qa` to install the
  newly locked Grug Far version.
- If the Neovim link has never been created on that laptop, first follow
  `setup/mac-resilience/README.md` and run its scoped link script; do not use the
  personal Mac bootstrap there.
- Hamel confirmed that pulling the latest `dotfiles-hd` changes succeeded on
  the Resilience work laptop. Plugin restoration remains the final update
  check.

### Understanding the Headless Plugin Restore

- Hamel asked what `nvim --headless '+Lazy! restore' +qa` does instead of
  copying the command blindly.
- `nvim` starts Neovim and loads the linked config; `--headless` runs it without
  opening the editor interface.
- `+Lazy! restore` runs Lazy's `restore` command after startup. It installs
  missing plugins and makes installed plugins match the exact commits recorded
  in `lazy-lock.json`; it does not update them to arbitrary latest versions.
- The `!` tells Lazy to wait until restoration finishes. `+qa` then runs
  `quitall`, closing the headless Neovim process only after that wait.
- Mental model: reproduce the repo's locked plugin set on another machine, then
  exit automatically.

### Installed Versus Loaded Plugins

- Hamel compared Lazy on the Resilience and personal Macs and initially read
  `mini.surround` under `Not Loaded` as missing.
- In Lazy, `Not Loaded` contains installed plugins that are waiting for their
  configured trigger. A genuinely missing plugin appears under `Not Installed`.
- `mini.surround` is key-triggered, so it stays unloaded until a mapping such as
  `gsa`, `gsd`, or `gsr` is used. The personal screenshot showing it under
  `Not Loaded` is healthy and saves startup work.
- The same rule applies to `grug-far.nvim` before `Space R`, `mini.pairs` before
  entering Insert mode, and Conform before a configured file or formatting
  action triggers it.
- Clarification from Hamel: on the Resilience work laptop, every other plugin
  had already loaded; only `mini.surround` remained installed-but-unloaded.
  This is still expected because none of its `gs` mappings had been used yet.
- Hamel asked whether the personal Mac should force the same loaded state. It
  should not: loaded counts depend on which actions and file types occurred in
  that Neovim session, so healthy machines can show different counts.
- The useful cross-machine check is that nothing appears under `Not Installed`;
  Lazy should load each installed plugin naturally when its trigger is used.

### Plugin Catalog and Responsibility Map

- Hamel asked what every plugin in the 20-plugin Lazy view does and whether
  those responsibilities were documented anywhere.
- `lazy-lock.json` is the exact-version record, and `lua/plugins/*.lua` is the
  behavior and trigger source of truth. Neither was a quick plain-English
  reference by itself.
- Added a complete plugin catalog to `README.md`, including the purpose and load
  trigger or main action for all 20 installed plugins.
- Mental groups: Lazy/Nord/icons are foundation and appearance; Snacks, Oil,
  bufferline, lualine, and WhichKey are navigation and interface; LSPConfig,
  Blink, snippets, SchemaStore, Tree-sitter, its parser registry, Conform, and
  Gitsigns support coding; pairs, surround, Grug Far, and render-markdown add
  focused editing workflows.
- No curriculum item was checked off because this was documentation and an
  explanation, not a hands-on plugin-recall exercise.

### How Lazy Loads Each Plugin

- Hamel followed up by asking how and when each plugin moves from installed to
  loaded.
- Lazy reads all plugin recipes during startup, but a recipe can run now or
  register a trigger for later. A key-triggered recipe leaves a lightweight
  placeholder mapping so the first keypress can load the plugin and then run
  the requested action. Once loaded, the plugin stays loaded until Neovim exits.
- Bootstrap: `lazy.nvim` loads first so it can manage everything else.
- Every startup (`lazy = false`): Nord, Snacks, Blink, LSPConfig, Tree-sitter,
  and Oil.
- Startup dependencies: friendly-snippets loads for Blink, SchemaStore for
  LSPConfig, the parser registry for Tree-sitter, and mini.icons for Oil.
- Just after startup (`VeryLazy`): bufferline, lualine, and WhichKey.
- File events: Conform and Gitsigns load on the first file read or new file;
  Conform can also load from `Space p` or `:ConformInfo`.
- On-demand: mini.pairs waits for Insert mode, mini.surround waits for a `gs`
  action, Grug Far waits for `Space R`, and render-markdown waits for a Markdown
  buffer or `Space m`.
- This previews Curriculum 10.5, but no checkbox was marked because Hamel has
  not yet done the later plugin-role recall exercise.

### IDE-Style Debugging Deferred

- Hamel asked whether Neovim can provide an IDE-style debugger with
  breakpoints, stepping, variables, call stacks, watches, and a console.
- The current config has no DAP/debugger plugin or language adapter installed.
- Added optional Curriculum 10.D7 for a future `nvim-dap` workflow with a
  visual debugger UI and one real language adapter. It remains optional so it
  does not interrupt the core curriculum.
- No plugin or debugger was installed and no keymap was added.
- Resume the main track at Curriculum 4.1: word, line, file, and matching-pair
  motions.

### IDE Parity Gap Assessment

- Hamel asked whether anything important was still missing from the IDE
  experience and noted that curiosity can pull him ahead of the current lesson.
- The daily coding loop is already covered: files and search, buffers and
  splits, completion and snippets, LSP navigation and refactors, diagnostics,
  formatting and linting, Git, terminals, replacement, folds, and previews.
- Genuine future options are the already-deferred DAP debugger, a dedicated
  test explorer if terminal-based testing becomes painful, and a Python LSP if
  substantial Python work begins. None is required for the current workflow.
- Curriculum 8.D3 already preserves a test-and-return exercise, and 7.D4
  already preserves session restoration; no new plugin was added for either.
- Corrected stale Curriculum 6.7 wording so it records all currently configured
  language servers and the actual Python gap.
- Decision: stop plugin shopping and add IDE conveniences only when a repeated
  real-work problem identifies the need. Future-looking questions can be
  captured as optional deep dives without interrupting the main track.
- Resume Curriculum 4.1 with the pending `w` motion checkpoint.

### Python Language Support Decision

- Hamel clarified that he rarely writes Python.
- Keep the existing Ruff formatter for occasional Python edits; do not add a
  Python language server without a real recurring need.
- The missing Python LSP is therefore an accepted scope choice, not a blocker
  or an incomplete IDE setup.

## 2026-07-17 — Session 011: Faint Current-Line Tint

- Hamel noticed the "dark lines" in the UI and asked to identify them. Mapping:
  the editor's current-line bar is `cursorline` (the `CursorLine` group); the
  highlighted row in the file tree is the Snacks explorer's current row
  (`SnacksPickerListCursorLine` when the explorer is focused, `CursorLine` when
  it is not); the vertical lines are the Snacks `indent` guides + scope.
- He wanted the editor bar (#1) and the tree row (#2) less prominent. We first
  tried full transparency (`bg = none`), then he chose a faint tint instead.
- Set both `CursorLine` and `SnacksPickerListCursorLine` to Nord `nord0`
  (`#2E3440`, `colors.polar_night.origin`) — one shade below the default `nord1`
  (`#3B4252`) — in the `on_highlights` hook of
  `config/nvim/lua/plugins/colorscheme.lua`. The bold, bright `CursorLineNr`
  still marks the active line, so the line is easy to spot without a heavy bar.
- Why the override sticks: nord applies every key in its highlights table
  (including ones we add) via `nvim_set_hl`, and Snacks defines
  `SnacksPickerListCursorLine` with `default = true`, so our explicit color wins
  and is not clobbered when the explorer first opens.
- Gotcha: an earlier transparent edit was silently reverted when a stale open
  buffer of `colorscheme.lua` saved over it (the Escape-to-save workflow). Re-did
  it cleanly on a clean working tree. Verified both groups resolve to `#2E3440`
  with `nvim_get_hl`.
- Left the Snacks `indent` vertical lines (#3) untouched.
- Decision history: the tint was briefly removed (Hamel first said he did not like
  it), but once the alternative was the default dark bar he preferred the subtle
  tint after all, so it was restored. Net result: the nord0 (`#2E3440`) tint is
  the active, committed state.

## 2026-07-17 — Session 012: Transparent Bufferline

### Bufferline Background Refinement

- Hamel identified the dark strip behind the open filenames at the top of
  Neovim and asked for it to blend into Ghostty's transparent background.
- The strip belongs to `bufferline.nvim`, not Ghostty.
- Configured every Bufferline background state, including active, visible,
  inactive, diagnostic, icon, separator, and fill areas, to use `NONE` while
  preserving the existing Nord foreground colors for readable filenames.
- Live visual confirmation is still pending. Resume the curriculum at 4.1 with
  the pending `w` motion checkpoint after confirming the tab bar appearance.

### Base Tabline Fallback Correction

- After restarting, Hamel confirmed the empty dark strip still appeared while
  Oil was the only visible buffer.
- The remaining color came from Neovim's base `TabLineFill` highlight, which
  Bufferline falls back to when it has no filename tabs to draw.
- Made `TabLine`, `TabLineFill`, and `TabLineSel` transparent in the Nord theme.
- A second live visual confirmation is pending.

### Snacks Explorer Selection Contrast

- Hamel confirmed the base tabline correction removed the dark strip.
- Hamel then asked for the selected file row in Snacks Explorer to be lighter.
- Changed only `SnacksPickerListCursorLine` to Nord's lighter `polar_night.brightest`
  shade so the current file is easier to spot without changing the explorer's
  transparent background.
- Live visual confirmation of the lighter selected row is pending.

### Cross-Background Explorer Selection Trial

- The lighter gray still blended into Ghostty when the blurred content behind
  the transparent window changed between light and dark.
- Started a live trial using Nord frost blue `#81A1C1` with dark `#2E3440`
  bold text for the selected Snacks Explorer row.
- The selection color is intentionally opaque so its contrast stays stable
  while the surrounding terminal remains transparent and blurred.
- Keep or revise this trial after Hamel checks it over both backgrounds.

### Explorer Icon Contrast Correction

- Hamel confirmed the frost-blue row worked against the changing background,
  but its color was too close to the cyan folder icons.
- Replaced the trial with neutral Nord `#434C5E` and removed the forced text
  color so Snacks can preserve each icon and filename's native color.
- The row remains bold and opaque; live confirmation over both backgrounds is
  pending.

### Final Visual Confirmation

- Hamel confirmed the final result looks good.
- Final state: Bufferline and Neovim's fallback tabline are transparent; the
  Snacks Explorer selection uses bold Nord `#434C5E` while preserving native
  icon and filename colors.
- Resume Curriculum 4.1 with the pending `w` motion checkpoint.

### Focused Editor Color Alignment

- When focus moved from Snacks Explorer into the editor, the selected tree row
  fell back to the global `CursorLine` color from Session 011.
- Hamel asked for the editor current line and the focused or unfocused Explorer
  row to use the same neutral Nord `#434C5E` background.
- Updated `CursorLine` to `polar_night.brighter`; the focused Explorer row keeps
  that same background plus bold text, while native editor and icon colors stay
  intact.
- This supersedes Session 011's earlier `#2E3440` active-state decision.
- Headless highlight verification passed; live confirmation after restart is
  pending.

### Transparent Editor Line With Persistent Explorer Selection

- After trying the shared `#434C5E` color, Hamel decided the editor's full-width
  current-line bar was distracting and asked for the terminal background to
  show through instead.
- Set the global editor `CursorLine` background to `NONE`; the cursor and bright
  current line number still show the editing position.
- Decoupled Snacks picker windows from the global fallback: their window-local
  `CursorLine` mapping now stays on `SnacksPickerListCursorLine` after focus
  moves into the editor.
- Final intent: editor current line transparent; Explorer selection remains
  bold Nord `#434C5E` with native icon and filename colors.
- Live visual confirmation after restart is pending.

### Final Transparent Editor Confirmation

- Hamel restarted Neovim and confirmed this split treatment looks much cleaner.
- Accepted final state: the editor current line blends into Ghostty, while the
  Explorer selection remains visible across focus changes.
- Resume Curriculum 4.1 with the pending `w` motion checkpoint.

### Git Blame Contrast Trial

- The inline Git blame text still used Nord's muted `#616E88`, which became too
  faint over light content behind Ghostty's transparent background.
- Raised only `GitSignsCurrentLineBlame` to brighter Nord `#D8DEE9` while
  keeping its background transparent.
- Live confirmation over both light and dark backgrounds is pending.

### Subtle Git Blame Gray Trial

- Hamel confirmed `#D8DEE9` made inline blame compete with normal code text.
- Replaced it with neutral light gray `#A7ADB7`, keeping the background
  transparent and the blame readable without making it prominent.
- Live confirmation over both light and dark backgrounds is pending.

### Final Git Blame Confirmation

- Hamel confirmed the subtle light gray looks right.
- Accepted final state: inline blame uses transparent `#A7ADB7`, remaining
  readable without competing with the code.
- Resume Curriculum 4.1 with the pending `w` motion checkpoint.

## 2026-07-17 — Session 013: Neovim and Ghostty Visual Polish

### Cursor Row and Neovim Launch Shortcut

- Hamel decided to restore a highlight on the editor row containing the cursor.
- The crosshair effect does not require a plugin: Neovim provides `cursorline`
  for the row and `cursorcolumn` for the column.
- Enabled only the row with opaque Nord `#3B4252`, so its contrast stays stable
  over both light and dark content behind Ghostty. The column remains off until
  Hamel chooses to test the busier full crosshair.
- Added the shared shell alias `v='nvim'`. Examples: `v`, `v .`, and
  `v README.md`.
- Run `exec zsh` once in an existing terminal to load the new alias.
- Live visual and shell confirmation are pending.

### Full Cursor Crosshair Trial

- Hamel confirmed the row highlight stays visible over both light and dark
  backgrounds, then asked why the vertical crosshair was missing.
- Enabled Neovim's built-in `cursorcolumn` option and matched `CursorColumn` to
  the row's opaque Nord `#3B4252` background.
- The cursor now marks both its row and column without adding a plugin.
- Live confirmation of the full crosshair is pending.

### Cross-Background Crosshair Color Trial

- The initial `#3B4252` crosshair was clear over light blurred content but
  blended into Ghostty when the content behind it was dark.
- Changed both `CursorLine` and `CursorColumn` to the middle Nord shade
  `#434C5E`, which sits between the observed light and dark terminal states.
- Live confirmation over both backgrounds is pending.

### Wrapped-Line Crosshair Gap Explained

- Hamel noticed a short break in the vertical crosshair beside a long Markdown
  list item.
- The line was soft-wrapped onto another screen row. Native `cursorcolumn`
  follows the buffer's virtual column, so it does not repeat the stripe at the
  same screen position on that wrapped continuation row.
- This is normal Neovim rendering, not missing text or a theme failure.
- Keeping readable Markdown wrapping preserves this small visual gap; an
  uninterrupted screen ruler would require disabling wrapping or custom
  rendering.

### Muted Blue Crosshair Trial

- Neutral `#434C5E` remained too close to Ghostty's darkest observed background.
- Changed the row and column to muted Nord blue `#526A88`. Its blue hue creates
  separation from both the light and dark gray backgrounds without using a
  bright accent color.
- Live confirmation over both backgrounds is pending.

### Toggle Word Wrap

- `:set wrap!` toggles visible line wrapping in the current window.
- `:set wrap` explicitly enables it; `:set nowrap` disables it.
- Wrapping changes only how long lines display. It does not modify the file.
- This config already enables `linebreak`, so wrapped prose breaks at word
  boundaries when possible.

### Graphite-Plum Crosshair Trial

- Hamel found muted Nord blue `#526A88` too colorful for the editor crosshair.
- Replaced it with quieter graphite-plum `#554D5E`. The warm tint separates it
  from both light and dark blue-gray terminal backgrounds without looking like
  an accent color.
- Live confirmation over both backgrounds is pending.

### Neutral Gray Crosshair Trial

- Hamel rejected the blue and graphite-plum directions and chose a colorless
  crosshair instead.
- Set both `CursorLine` and `CursorColumn` to true neutral gray `#5B5B5B`.
- Live confirmation over both light and dark backgrounds is pending.

### Balanced Steel Gray Crosshair Trial

- True neutral gray `#5B5B5B` did not fit the surrounding Nord UI.
- Changed both crosshair directions to balanced steel gray `#60656D`, which is
  slightly lighter than both observed terminal backgrounds without becoming a
  bright accent.
- Live confirmation over both backgrounds is pending.

### Dusty Blue-Gray Crosshair Trial

- Balanced steel gray `#60656D` still felt too neutral.
- Hamel asked for a slightly lighter grayish blue, so both crosshair directions
  now use desaturated dusty blue-gray `#687483`.
- Live confirmation over both backgrounds is pending.

### Darker Blue-Gray Crosshair Trial

- Hamel asked to make dusty blue-gray `#687483` slightly darker and bluer.
- Adjusted both crosshair directions to `#5C6A7D`, retaining more gray than the
  earlier saturated Nord blue trial.
- Live confirmation over both backgrounds is pending.

### Final Crosshair Confirmation

- Hamel confirmed darker blue-gray `#5C6A7D` looks right.
- Accepted final state: built-in `cursorline` and `cursorcolumn` use the same
  opaque blue-gray background for a consistent crosshair across Ghostty's light
  and dark blurred backdrops.
- Resume Curriculum 4.1 with the pending `w` motion checkpoint.

### Markdown Code Panel and Statusline Trial

- Rendered Markdown code inherited Nord `#3B4252` from `ColorColumn`, which
  blended into Ghostty over dark content.
- Changed fenced, border, fallback, and inline rendered-code backgrounds to
  opaque Nord `#2E3440` so they remain distinct over both light and dark
  backdrops.
- Simplified lualine by making its center transparent, removing the redundant
  `utf-8` segment, and combining cursor location and progress into one display
  such as `150:1 · 85%`.
- The mode and position edge pills remain opaque for stable contrast.
- Live visual confirmation is pending.

### Statusline Percentage Escape Fix

- The first combined `line:column · progress%` component returned a bare `%`.
  Neovim interpreted it as statusline control syntax and rejected the whole
  lualine render with `E539`, leaving only an empty strip.
- Escaped the percent sign as `%%`, restoring the full statusline while keeping
  the compact display.
- Live confirmation after restarting Neovim is pending.

### Transparent Statusline Center Fix

- The lualine center component had no background of its own, but Neovim's base
  `StatusLine` highlight still painted Nord `#434C5E` underneath it.
- Made `StatusLine` and `StatusLineNC` transparent. The `oil:///...` or filename
  center now shows Ghostty's background while the mode, Git, and position pills
  remain opaque.
- Live confirmation over both light and dark backgrounds is pending.

### Session 013 Corrections and Ghostty Update

- Correction: native `cursorcolumn` marks the cursor's screen column. The gap
  observed beside wrapped Markdown was a rendering limitation in that layout,
  not evidence that it follows a buffer virtual column.
- The crosshair, rendered-code panels, and statusline edge pills use fixed
  background colors. Ghostty still applies its configured 90% cell opacity, so
  the earlier word `opaque` was imprecise.
- Ghostty now uses `background-opacity = 0.90` and `background-blur = 20`.
- `ghostty +validate-config` passes. A full Ghostty quit and restart is still
  required before judging the opacity and blur change visually.
- The custom statusline now uses `charcol()` so its column number stays correct
  when a line contains multibyte characters.

### Zsh Autosuggestion Investigation

- The Homebrew `zsh-autosuggestions` plugin is installed, sourced, and active.
- In a fresh interactive shell, typing `git st` produced the history suggestion
  `atus`, proving the plugin still works.
- The suggestion uses palette color 8 (`#4C566A`), which is too close to the
  Nord background (`#3B4252`) after Ghostty transparency and blur.
- No autosuggestion color was changed yet. The proposed next test is muted
  steel blue-gray `#7B8496`.

## 2026-07-17 — Session 014: Shared Zsh Autosuggestion Contrast

- Set `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#7B8496'` in the shared
  `setup/mac-vm/zsh-config/prompt.zsh` file.
- The personal Mac, Mac mini, and repo-managed Resilience shell entry points all
  source that file before loading `zsh-autosuggestions`.
- Fresh-shell checks confirmed all three entry points inherit `fg=#7B8496`.
- Run `exec zsh`, then type the beginning of a command from shell history to
  judge the new muted steel blue-gray suggestion color.
- Live visual confirmation is pending; nothing is committed yet.

### Shared Autosuggestion Confirmation

- Hamel confirmed the muted steel blue-gray suggestion color looks good.
- Accepted final state: `#7B8496` lives in shared `prompt.zsh`, so the personal
  Mac, Mac mini, and repo-managed Resilience shell entry points inherit it.
- After pulling on another machine, run `exec zsh` to load the new color.

### Resilience Boundary and Next Lesson

- The personal Mac and Mac mini are guaranteed to load the shared setting from
  their repo-managed shell entry points.
- The repo's Resilience entry point also loads it, but the real work `.zshrc`
  is intentionally preserved. A pull alone changes the work shell only if that
  live file already sources the shared `prompt.zsh`.
- After pulling on the work Mac, run `exec zsh`, then
  `print -r -- "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE"`. The expected result is
  `fg=#7B8496`; a blank result means the protected work shell needs a small,
  explicit follow-up edit.
- Best next lesson: resume Curriculum 4.1 at the pending `w` motion checkpoint.

### Work-Specific Autosuggestion Override

- Hamel clarified that Resilience should keep its work-specific shell settings
  instead of depending on every shared personal-Mac choice.
- Added `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#7B8496'` directly to
  `setup/mac-resilience/.zshrc`, before its deferred plugin loader.
- The shared value remains for the personal Mac and Mac mini; the Resilience
  profile now owns an explicit matching override that can diverge later.
- Best next lesson remains Curriculum 4.1 at the pending `w` motion checkpoint.

### Work-Specific Neovim Shortcut

- Mirrored the existing `v='nvim'` shortcut directly in
  `setup/mac-resilience/.zshrc` so the work profile owns it independently.
- No separate `nv` alias exists in the current dotfiles, so no new shortcut was
  invented.
- After pulling on the work Mac, run `exec zsh`; `v`, `v .`, and
  `v README.md` then launch Neovim.
- Best next lesson remains Curriculum 4.1 at the pending `w` motion checkpoint.

## 2026-07-17 — Session 015: Catppuccin Markdown and Hunk

- Kept Neovim's transparent Nord base and applied Catppuccin Mocha only to
  rendered Markdown headings, code, tables, bullets, and links.
- Shortened heading bands with block width and one-cell side padding; trimmed
  table cells to reduce unnecessary width and wrapping.
- Hamel visually confirmed the rendered Markdown result.
- Switched Hunk from the hand-maintained Hamel Nord palette to Hunk's built-in
  `catppuccin-mocha` theme while preserving its transparent background.
- Mental model: plugin-specific highlights can use another palette without
  replacing the editor's main colorscheme, and a built-in Hunk theme avoids a
  duplicate local color map.
- `Space m` still toggles raw and rendered Markdown. Restart Hunk to load its
  new theme after pulling on another machine.
- Best next lesson remains Curriculum 4.1 at the pending `w` motion checkpoint.

## 2026-07-19 — Session 016: Motions

### Resume Point

- Resumed the clean `master` branch at Curriculum 4.1: word, line, file, and
  matching-pair motions.
- First checkpoint: open a fresh unnamed buffer with `Space n`, add controlled
  practice text, then use native Normal-mode `w` to move to the next word.
- Curriculum 4.1 remains unchecked until every motion group is practiced and
  confirmed.

### Safe Motion Scratch

- Hamel pressed `Space n` and confirmed that a blank unnamed buffer opened.
- Next: insert `alpha beta gamma` and return to Normal mode so word motions have
  predictable targets.

### Word-Motion Fixture

- Hamel inserted `alpha beta gamma` and returned to Normal mode.
- Next: press `0` to move to the first character of the line before testing
  forward word motion with `w`.

### Start-of-Line Motion Confirmed

- Hamel pressed `0` and confirmed that the cursor moved to the first `a` in
  `alpha`.
- `0` moves to column zero, the literal first character of the current line.
- Next: press `w` once to move to the start of `beta`.

### Forward Word Motion Confirmed

- Hamel pressed `w` and advanced to the start of `beta`.
- `w` moves forward to the start of the next word; it changes only the cursor,
  not the text.
- Next: press `e` to move from the start to the end of `beta`.

### End-of-Word Motion Confirmed

- Hamel pressed `e` and advanced to the final `a` in `beta`.
- `e` moves forward to the end of the current or next word.
- Next: press `b` to move backward to the start of `beta`.

### Backward Word Motion Confirmed

- Hamel pressed `b` and returned to the first `b` in `beta`.
- `b` moves backward to a word start; `w`, `e`, and `b` now cover next start,
  next end, and previous start.
- Next: press `$` to jump to the final character of the current line.

### End-of-Line Motion Confirmed

- Hamel pressed `$` and advanced to the final `a` in `gamma`.
- `$` jumps to the final character of the current line.
- Next: add two more practice lines so `gg` and `G` can demonstrate whole-file
  movement.

### File-Motion Fixture

- Hamel added `second line` and `third line`, producing a three-line unnamed
  scratch buffer, then returned to Normal mode.
- Next: press `gg` to jump from the third line to the first line.

### Top-of-File Motion Confirmed

- Hamel pressed `gg` and confirmed the cursor jumped to line 1.
- `gg` moves to the first line of the file.
- Next: press `G` to jump back to the last line.

### Bottom-of-File Motion Confirmed

- Hamel pressed `G` and confirmed the cursor jumped to the last line.
- `G` moves to the final line of the file.
- Next: add a pair of parentheses for matching-pair motion practice.

### Matching-Pair Fixture

- Hamel used `o` to add `call(alpha, beta)` below the current line, then
  returned to Normal mode.
- Next: press `%` from the closing parenthesis to jump to its opening match.

### Matching-Pair Motion Explained

- `%` jumps between matching delimiters such as `()`, `[]`, and `{}`.
- Coding use case: quickly move between the opening and closing edges of a
  function call, array, or code block, especially when nesting is deep.
- Pressing `%` again jumps back to the other side of the pair.

### Matching-Pair Motion Confirmed

- Hamel used `%` to jump from the closing `)` to its opening `(`, then pressed
  `%` again and confirmed the cursor returned to the closing `)`.
- Curriculum 4.1 is complete: Hamel practiced word, line, whole-file, and
  matching-pair motions.
- Next: begin Curriculum 4.2 by combining operators with those motions.

## 2026-07-20 — Session 017: Operators and Motions

### Operator-Motion Setup

- Hamel pressed `gg` and returned to the first line, `alpha beta gamma`.
- Vim editing follows an operator-plus-motion grammar: choose an action, then
  describe the text that action should cover.
- First combination: `dw` means delete (`d`) through the next-word motion
  (`w`), removing `alpha ` and leaving `beta gamma`.

## 2026-07-21 — Session 018: Operator-Motion Practice

### Delete With a Motion Confirmed

- Hamel pressed `dw` on `alpha beta gamma` and confirmed that `alpha ` was
  deleted, leaving `beta gamma`.
- Mental model: `d` chooses the delete operator and `w` supplies its range.
- Next: use `cw` on `beta` to change that word while preserving its trailing
  space.

### Change With a Motion Confirmed

- Hamel pressed `cw`, typed `delta`, and returned to Normal mode; `beta gamma`
  became `delta gamma`.
- `c{motion}` deletes the motion's range and immediately starts Insert mode.
- `cw` is a useful special case: it changes the current word without consuming
  its trailing space.
- Next: combine `y` with `w`, then paste the yanked range to verify it.

### Yank With a Motion Confirmed

- Hamel pressed `0`, `yw`, and `P`; the yanked `delta ` was pasted before the
  cursor, producing `delta delta gamma`.
- `y{motion}` copies the motion's range without deleting it; `P` pastes before
  the cursor, while lowercase `p` pastes after it.
- Curriculum 4.2 is complete: Hamel combined `d`, `c`, and `y` with `w` rather
  than treating each edit as an unrelated command.
- Next: begin Curriculum 4.3 by adding a count before a motion.

### Counted Motion Confirmed

- Hamel pressed `0`, then `2w`, and confirmed the cursor moved two word starts
  from the first `delta` to `gamma`.
- A count scales the motion that follows it: `2w` performs `w` twice.
- Next: combine the same count with `dw` to delete two words in one command.

### Counted Operator Confirmed

- Hamel pressed `0`, then `2dw`, and confirmed that both `delta ` words were
  deleted in one command, leaving `gamma`.
- Counts scale operator-motion commands as well as standalone motions.
- Curriculum 4.3 is complete: Hamel practiced both `2w` and `2dw`.
- Next: begin Curriculum 4.4 with the `iw` inner-word text object.

### Inner-Word Text Object Confirmed

- Hamel moved to the end of `gamma`, pressed `ciw`, typed `omega`, and returned
  to Normal mode; the whole word changed even though the cursor was not at its
  start.
- `ciw` reads as change inside word. In this operator-pending command, `i`
  means inner; it is unrelated to Hamel's reversed Normal-mode Insert mapping.
- Next: compare `iw` with `aw`, which includes surrounding whitespace.

### Around-Word Text Object Confirmed

- Hamel moved to `second line` and pressed `daw`; Neovim deleted `second` plus
  its adjacent space, leaving `line` without extra whitespace.
- `iw` targets only the word; `aw` targets the word and nearby whitespace.
- Coding use case: on `async function run()`, put the cursor anywhere in
  `async` and press `daw` to leave `function run()` cleanly. Use `ciw` when a
  local variable or argument needs replacing from anywhere inside its name.

### Parentheses Text-Object Setup

- Next target: the existing `call(alpha, beta)` line.
- `ci(` reads as change inside parentheses: it replaces the contents while
  preserving the surrounding `(` and `)`.
- Navigation clarification: `G` and `w` are separate commands. `G` jumps to
  the last line; `w` then moves from `call` to the word inside its parentheses
  so the cursor is within the text object.

### Inner-Parentheses Text Object Confirmed

- Hamel pressed `ci(` from inside `call(alpha, beta)`, typed `omega`, and
  returned to Normal mode; the result was `call(omega)`.
- `i(` excluded the delimiters, so `c` replaced only the argument contents and
  preserved both parentheses.
- Coding use case: replace an entire function argument list from anywhere
  inside it without manually selecting the arguments.
- Next: use `a(` to include the parentheses themselves.

### Around-Parentheses Text Object Confirmed

- Hamel pressed `da(` inside `call(omega)` and confirmed that Neovim removed
  `(omega)`, leaving `call`.
- `i(` targets only the contents; `a(` includes both parentheses.
- Coding use case: remove an entire parenthesized wrapper while refactoring,
  including its delimiters, without selecting it by hand.
- Next: create a quoted-string fixture for `i"` and `a"` practice.

### Quoted-String Fixture

- Hamel used `o` to add `const mode = "dark"`, then returned to Normal mode
  with the cursor on the closing quote.
- Next: use `ci"` to change only the text inside the quotes while preserving
  both quote characters.

### Inner-Quote Text Object Confirmed

- Hamel pressed `ci"`, typed `light`, and returned to Normal mode; the result
  was `const mode = "light"`.
- `i"` excludes the quote delimiters, just as `i(` excludes parentheses.
- Coding use case: replace a configuration value or string argument without
  manually selecting its contents or disturbing its quotes.
- Next: use `a"` to include the quotes themselves.

### Around-Quote Text Object Confirmed

- Hamel pressed `da"` inside `const mode = "light"` and confirmed that Neovim
  removed the quoted string, both quote delimiters, and the adjacent space,
  leaving `const mode =`.
- Curriculum 4.4 is complete: Hamel practiced inside and around text objects
  for words, parentheses, and quotes.
- Next: begin Curriculum 4.5 with a forward search for `line` in the scratch
  buffer, which contains two matches.

### Forward-Search Prompt Explained

- Hamel pressed `/` and saw the command/search prompt appear at the bottom.
- This is expected: `/` opens Neovim's search command line rather than Insert
  mode. Type the search text directly after `/`, then press `Enter`.

### Forward Search Confirmed

- Hamel entered `/line` and pressed `Enter`; Neovim jumped to a `line` match in
  the current buffer.
- `/` searches the current file, unlike `Space /`, which opens project-wide
  grep.
- Next: press `n` to repeat the search in the same direction.

### Next Search Match Confirmed

- Hamel pressed `n` and confirmed that Neovim advanced to the next `line`
  match, inside `third line`.
- `n` repeats the latest search in its original direction.
- Next: press uppercase `N` to repeat that search in the opposite direction.

### Previous Search Match Confirmed

- Hamel pressed uppercase `N` and confirmed that Neovim returned to the
  previous `line` match.
- `N` repeats the latest search in the opposite direction.
- Curriculum 4.5 is complete: Hamel practiced `/`, `n`, and `N` and can
  distinguish current-file search from project grep with `Space /`.
- Next: begin Curriculum 4.6 with the custom `Ctrl-a` full-buffer selection.

### Full-Buffer Selection Exit Explained

- After `Ctrl-a` highlighted the whole buffer in Visual Line mode, Hamel asked
  how to clear the selection.
- Press `Escape` to leave Visual mode without changing the selected text.

### Search Highlight Clarification

- Hamel clarified that the remaining highlight came from a search such as
  `/beta`, not from Visual mode.
- Type `:noh` and press `Enter` to hide current search highlighting. This does
  not forget the search pattern; `n` and `N` can still navigate its matches.
- Distinction: `Escape` exits a Visual selection, while `:noh` clears search
  highlighting.

### Search Highlight Clearing Confirmed

- Hamel typed `:noh`, pressed `Enter`, and confirmed that the `/beta` search
  highlight disappeared.
- The earlier question referred to search highlighting, so Curriculum 4.6 is
  still pending an explicit `Ctrl-a` full-buffer selection confirmation.

### Full-Buffer Selection Confirmed

- Hamel pressed `Ctrl-a` and confirmed that the whole buffer entered Visual
  Line selection, then pressed `Escape` and confirmed the selection cleared
  without changing text.
- Curriculum 4.6 is complete.
- Next: begin Curriculum 4.7 by selecting two full lines and indenting them
  while keeping the selection active.

### Visual Indent Confirmed

- Hamel pressed `gg`, `V`, `j`, then `>`; the first two lines indented and
  remained selected.
- The custom Visual-mode `>` mapping reapplies the selection after indenting,
  which makes repeated alignment edits possible without selecting again.
- Next: press `<` while the same lines remain selected to outdent them.

### Visual Outdent Confirmed

- Hamel pressed `<`; the same two lines outdented and remained selected.
- The custom Visual-mode `<` mapping also reapplies the selection.
- Next: press uppercase `J` to move the selected two-line block down one line.

### Visual Block Move Down Confirmed

- Hamel pressed uppercase `J`; the selected two-line block moved down one line
  and remained selected.
- Coding use case: reorder adjacent statements or configuration entries as a
  block without cutting, pasting, or rebuilding the selection.
- Next: press uppercase `K` to move the selected block back up one line.

### Normal-Mode `K` Correction

- Pressing uppercase `K` opened a manual page, proving Neovim was in Normal
  mode rather than Visual mode at that moment.
- Native Normal-mode `K` looks up documentation for the word under the cursor;
  the custom block-move `K` mapping applies only while text is visually
  selected.
- Recovery plan: close the manual, return to the scratch buffer, press `gv` to
  reselect the previous Visual area, then retry uppercase `K`.

### Manual Recovery Confirmed

- Hamel pressed `q`, closed the manual, and returned to the scratch buffer.
- Next: press `gv` in Normal mode to restore the most recent Visual selection.

### Previous Visual Selection Restored

- Hamel pressed `gv` and confirmed that the previous two-line Visual selection
  was highlighted again.
- `gv` is the recovery command when a Visual selection is lost or exited.
- Next: retry uppercase `K` while the block is visibly selected.

### `gv` Mode-State Clarification

- Hamel reported that `gv` appeared to stop working after the retry.
- A headless reproduction with the real config confirmed that Visual-mode `K`
  leaves Neovim in Visual Line mode; the mapping itself is working.
- Root cause: `gv` is meant to restore a prior selection from Normal mode. If
  the block is already selected, `gv` exchanges Visual areas and can appear to
  do nothing.
- Deterministic reset: press `Escape` to enter Normal mode, then press `gv`
  once to restore the last selection.

### Visual-Move Top-Boundary Diagnosis

- Retrying uppercase `K` produced `E16: Invalid range`.
- A headless reproduction with the real config confirmed the root cause: the
  selected block was already at line 1, so there was no valid line above it.
  The mapping was active; this was a boundary error, not the manual-page
  behavior from Normal-mode `K`.
- The error exits Visual mode. The verified recovery sequence is `gv`, `J`,
  then `K`: reselect the block, move it down once, then move it back up.

### Visual Block Move Up Confirmed

- Hamel ran the recovery sequence `gv`, `J`, then `K`; the selected block moved
  down and back up successfully.
- Visual-mode `J` and `K` are now confirmed. `K` only fails at the top boundary
  because no earlier line exists.
- The unnamed scratch buffer has no filetype or `commentstring`, so the next
  drill first assigns the Lua filetype before testing `Space c`.
- Config verification showed that `Space c` comments the active selection and
  then returns to Normal mode; unlike `<`, `>`, `J`, and `K`, it does not keep
  the selection active afterward.

### Comment-Drill Selection Diagnosis

- The `Escape`, `:setfiletype lua`, `gv` setup did not restore the expected
  two-line selection.
- Live Neovim state confirmed that `:setfiletype lua` succeeded and the buffer
  was in Normal mode, but its remembered Visual range had become a one-character
  selection on line 1. Therefore `gv` could not recreate the earlier two-line
  block.
- Recovery: build the intended selection explicitly with `gg`, `V`, `j`
  instead of relying on stale Visual-selection history.

### Lesson Value Reset

- Hamel stopped the drill and asked what practical goal it served.
- Goal: test `Space c` on an active multi-line code selection. The exercise
  drifted into artificial filetype and stale-selection setup because the
  unnamed scratch buffer was not real code.
- Decision: stop this scratch-buffer detour. Practice `Space c` later in a real
  Lua or Go file where comments are naturally useful.
- Confirmed Curriculum 4.7 skills so far: visual indent/outdent with `>` and
  `<`, and visual block movement with `J` and `K`. Multi-line commenting remains
  pending.

### Comment Drill Retained

- Hamel clarified that multi-line commenting is useful; only the artificial
  setup detour was not.
- Live Neovim state confirmed that the current buffer is now Lua, has
  `commentstring=-- %s`, and is in Normal mode.
- Simplified drill: use `Ctrl-a` for a fresh full-buffer selection, then press
  `Space c` to toggle comments on the selected nonblank lines.

### Visual Comment Confirmed

- Hamel pressed `Ctrl-a`, then `Space c`, and confirmed that the selected
  nonblank Lua lines received `--` comments before Neovim returned to Normal
  mode.
- Curriculum 4.7 is complete: Hamel practiced visual indent/outdent, block
  movement, selection recovery, boundary behavior, and multi-line commenting.
- Lesson 4 core is complete. Next: Curriculum 5.1, real Go and Lua buffers with
  verified LSP attachment through `:LspInfo`.

## 2026-07-21 — Session 019: Lesson 5 Go Practice Module

### Safe LSP Fixture Prepared

- Hamel chose a purpose-built fake Go module for Lesson 5 instead of practicing
  navigation and completion in production code.
- Created the persistent local module at
  `~/Developer/nvim-warrior-practice/lesson-05-go` with a small `main` package,
  a documented `greeting` package, repeated `Greet` call sites, and a test.
- The symbols intentionally support every Lesson 5 drill: `gh` hover, `gd`
  definition jumps, `grr` references, `Space S` workspace symbols, and method
  completion after `greeter.`.
- Verified `gofmt`, `go test ./...`, `go vet ./...`, and `gopls check`.
- Verified headlessly with the real Neovim config that `gopls` attaches to
  `main.go`.
- Curriculum 5.1 remains unchecked until Hamel personally verifies attachment
  in both this Go module and a real Lua config buffer.
- Next: open the Go fixture's `main.go`, run `:LspInfo`, and describe the
  attached client.

### Fixture Moved Into Dotfiles

- Hamel decided that this curriculum-owned fixture should travel with the
  dotfiles rather than remain a separate local project.
- Moved it to
  `~/Developer/dotfiles-hd/config/nvim/practice/lesson-05-go`; the live Neovim
  symlink also exposes it at `~/.config/nvim/practice/lesson-05-go`.
- This keeps the practice code, curriculum, and learning log versioned together.

### Practice Project Opened

- Hamel launched Neovim in the Lesson 5 Go practice directory and continued
  from its file listing.
- Next: open `main.go`, then inspect its attached language server.

### Go Buffer Opened

- Hamel opened `main.go` from the practice project's file listing.
- Next: run `:LspInfo` and inspect whether `gopls` is attached.

### Neovim 0.12 LSP Command Correction

- Hamel correctly reported that `:LspInfo` is not an available command.
- Reproduced with the live Neovim 0.12.4 config: `gopls` attached successfully,
  while `exists(':LspInfo')` returned `0`.
- Root cause: Neovim 0.12 supplies the built-in `:lsp` command, so the current
  `nvim-lspconfig` plugin exits before creating its legacy `:LspInfo` alias.
- The supported status command is `:checkhealth vim.lsp`; earlier `:LspInfo`
  instructions in this append-only log are superseded by this correction.
- Updated the curriculum, config README, and practice README.
- Next: run `:checkhealth vim.lsp` from `main.go` and look for `gopls`.

### Go LSP Attachment Confirmed

- Hamel ran `:checkhealth vim.lsp` from `main.go` and confirmed that `gopls`
  appeared in the report.
- `:checkhealth` runs Neovim diagnostics; the `vim.lsp` argument limits the
  report to language-server configuration and active clients.
- Seeing `gopls` means the Go buffer has semantic code intelligence for hover,
  definitions, references, workspace symbols, diagnostics, and completion.
- Curriculum 5.1 remains open until Lua attachment is also confirmed.
- Next: close the health report, open a real Lua config file, and check for
  `lua_ls`.

### LSP Health Report Closed and Documented

- Hamel pressed `q` and closed the LSP health report.
- Added the `:checkhealth vim.lsp` mental model and the meaning of an attached
  `gopls` client to both the main Neovim README and the Lesson 5 practice README
  so future agents and machines retain the correction.

### Herdr Pane Versus Neovim Split

- Hamel already opened the Lua side of the exercise through a Herdr pane.
- A Herdr pane contains a separate terminal or Neovim process; `:vsplit` creates
  two windows inside one Neovim process. Either layout works for this attachment
  check.
- Next: run `:checkhealth vim.lsp` in the Neovim instance showing `lsp.lua` and
  look for `lua_ls`.

### Lua LSP Attachment Confirmed

- Hamel ran the LSP health report from the real `lsp.lua` config buffer and
  found the attached `lua_ls` client.
- Together with the confirmed `gopls` client in `main.go`, this completes
  Curriculum 5.1 for both Go and Lua.
- Next: close the health report and practice `gh` hover on a documented Go
  symbol for Curriculum 5.2.

### Go Hover Confirmed

- Hamel returned to `main.go`, placed the cursor on `Greet`, pressed `gh`, and
  saw its type definition in the LSP hover window.
- `gh` answers “what is this symbol?” without leaving the current location.
- Coding use case: check a function's parameters, return type, and documentation
  before calling it instead of jumping into another file.
- Curriculum 5.2 is complete. Curriculum 5.3 was completed earlier, so the next
  core checkpoint is 5.4: find every reference with `grr`.

### Go References Confirmed

- Hamel placed the cursor on `Greet`, pressed Neovim's native `grr`, and saw a
  small bottom window listing files that reference the method.
- That bottom window is the quickfix references list. Each row is one matching
  usage; move with `j` and `k`, then press `Enter` to jump to a selected usage.
- Coding use case: inspect a function's impact before changing or renaming it.
- Curriculum 5.4 is complete. Next: workspace-symbol search with `Space S`.

### Reference Jump Confirmed

- From the focused references list, Hamel pressed `j`, then `Enter`, and landed
  on another line where `greeter.Greet(...)` is called.
- This confirms the full `grr` workflow: collect usages, select one, and jump to
  its exact file and line.
- Added `grr` to the main Neovim README quick-reference row.

### Quickfix Close Mapping Added

- Hamel chose `Space c q` as an easier replacement for typing `:cclose` after
  navigating LSP references.
- Added `Space c q` to close only the quickfix/references list.
- `Space c q` is targeted: it runs `:cclose` and preserves the code window.
  `Space q` is general: it runs `:quit` and closes whichever Neovim window is
  currently focused.
- Documented the mapping in both Neovim READMEs. It remains unconfirmed until
  Hamel reloads the config and successfully closes the visible references list.

### Quickfix Close Mapping Confirmed

- Hamel restarted the Go Neovim session, reopened the references list with
  `grr`, and confirmed that `Space c q` closed the list while preserving the Go
  code window.
- The new mapping is now taught, documented, and live-verified.
- Next: Curriculum 5.5, workspace-symbol search with `Space S`.

### Search-Scope Mental Model

- Hamel opened the LSP workspace-symbol picker with `Space S` and asked how it
  differs from `/` and `Space f` before continuing.
- `/` searches ordinary text only inside the current file.
- `Space /` searches ordinary text across project files.
- `Space f` fuzzy-searches project filenames and paths.
- `Space S` asks the attached LSP for named code definitions across the project,
  such as functions, methods, types, and variables.
- Concrete example: `Space S`, then `Goodbye`, finds the `Goodbye` method as a
  Go symbol even though the method is never called.
- Added this four-scope search mental model to the main Neovim README.
- Curriculum 5.5 remains open until Hamel searches for and opens a workspace
  symbol.

### Search Scopes Marked for Reinforcement

- Hamel said distinguishing `/`, `Space /`, `Space f`, and `Space S` is a
  recurring difficulty and asked that it be preserved explicitly.
- Added optional Curriculum 5.D6 so future teaching sessions revisit the four
  search scopes until Hamel can identify them from memory.
- The optional review does not block completion of Lesson 5's core track.

### Workspace-Symbol Search Confirmed

- In the `Space S` LSP workspace-symbol picker, Hamel searched for `Goodbye`,
  saw the method result, and pressed `Enter` to open its definition in
  `greeting/greeter.go`.
- This differs from plain-text grep: `gopls` identified `Goodbye` as a Go method
  even though nothing calls it.
- Curriculum 5.5 is complete. Next: Curriculum 5.6, deliberate completion and
  acceptance of the intended item.

### Jump-History Mental Model Revisited

- Before returning from `greeter.go`, Hamel asked what `Ctrl-o` does.
- Mental model: the jump list behaves like browser history. `Ctrl-o` goes Back
  to an older meaningful code location; `Ctrl-i` goes Forward again.
- In this drill, `Space S` jumped from `main.go` to the `Goodbye` definition, so
  `Ctrl-o` should return to `main.go` without closing either file or buffer.
- Added the Back/Forward reminder to the main Neovim quick-reference table.

### Jump Back Confirmed

- Hamel pressed `Ctrl-o` and confirmed that Neovim returned from the `Goodbye`
  definition in `greeter.go` to the earlier location in `main.go`.
- This reinforced `Ctrl-o` as code-location Back, not a close or buffer-delete
  command.
- Next: add one harmless call in `main.go` and deliberately accept the intended
  LSP completion item for Curriculum 5.6.

### Open Line Above Confirmed

- From the final `}` in `main.go`, Hamel pressed uppercase `O` and confirmed
  that Neovim created a blank line above it and entered Insert mode.
- Mental model: lowercase `o` opens below; uppercase `O` opens above. Both start
  Insert mode immediately.
- Coding use case: from a closing brace, use `O` to add one more statement
  inside the block without manually creating or repositioning a line.
- Added the `o` / `O` pair to the main Neovim quick-reference table.

### Working Directory Versus Current File

- During completion-drill recovery, Hamel asked why
  `:echo expand('%:t')` was needed instead of `:pwd`.
- `:pwd` answers “which folder is Neovim working from?” Both `main.go` and
  `greeter.go` can share that same directory.
- `:echo expand('%:t')` answers “which file is this buffer showing?” `%` is the
  current file and `:t` selects only its tail filename.
- Memory aid: **PWD = place; `%:t` = current file's tail name.**
- Added both commands and the mnemonic to the main Neovim troubleshooting notes.

### Completion Wrong-File Recovery

- Hamel deliberately selected and accepted the `Goodbye` LSP completion item,
  but the call was first inserted into `greeter.go` because the earlier
  `Ctrl-o` jump was assumed to have returned to `main.go` without verifying the
  status-line filename.
- The resulting `fmt` undefined, `greeter` undefined, unreachable-code, and
  missing-return diagnostics were consequences of the correct call being placed
  after `Goodbye`'s `return`, not missing imports or a need for another return.
- `Space w` only saves the current buffer; it never adds missing code or fixes a
  diagnostic automatically.
- Recovery: identify the current buffer with `:echo expand('%:t')`, explicitly
  open `greeting/greeter.go`, delete only the accidental line with `dd`, and save
  with `Space w`.
- The intended completion-created call is now correctly saved in `main.go` as
  `fmt.Println(greeter.Goodbye("Grace"))`.
- Verified the recovered fixture with `go test ./...` and `gopls check`; both
  pass with no Go diagnostics.
- Curriculum 5.6 and all Lesson 5 core checkpoints are complete. Next: Lesson
  6.1, reading diagnostics deliberately in this safe practice module.

### Diagnostic Typo Setup and Cursor Recovery

- To create a safe diagnostic, Hamel searched `main.go` for `Goodbye` and used
  `r` with lowercase `g`.
- On the first attempt, the cursor was actually on the final `)`, so `rg`
  changed the line ending to `Goodbye("Grace")g` and produced the syntax error
  `missing ',' in argument list`.
- Hamel pressed `u` once and confirmed that the clean line and zero-diagnostic
  state returned without saving the mistake.
- On the retry, the live cursor position was verified on the capital `G` before
  applying `rg`.

### Diagnostic Signals Confirmed

- The intentional `Goodbye` to `goodbye` typo produced
  `greeter.goodbye undefined`.
- Hamel identified the three diagnostic surfaces: `E` in the gutter for error
  severity, the highlight/underline on the exact broken symbol, and inline text
  explaining the problem.
- Go identifiers are case-sensitive, so `goodbye` and `Goodbye` are different
  method names.
- Added the three-part diagnostic mental model to the main Neovim README.
- Curriculum 6.1 is complete. The typo remains intentionally unsaved for the
  diagnostic-navigation drills in Curriculum 6.2 and 6.3.

### Next Diagnostic Confirmed

- A second intentional typo changed `Greet` to `greet`, producing two active
  Go errors on lines 12 and 14.
- Hamel pressed `]d` from the first error and confirmed that Neovim jumped
  forward to the lowercase `goodbye` diagnostic.
- Memory aid: `]` moves forward, `[` moves backward, and `d` means diagnostic.
- Hamel identified this as a high-use coding workflow, so the mnemonic and use
  case were added to the main Neovim README.
- Curriculum 6.2 remains open until `[d` is also practiced and confirmed.

### Previous Diagnostic Confirmed

- Hamel pressed `[d` from the lowercase `goodbye` error and confirmed that
  Neovim returned backward to the lowercase `greet` error.
- Curriculum 6.2 is complete: `]d` moves to the next diagnostic and `[d` moves
  to the previous diagnostic.
- The two unsaved practice errors remain available for Curriculum 6.3.

### Diagnostic Detail Float Confirmed

- With the cursor on lowercase `greet`, Hamel pressed `Ctrl-w d` and saw the
  full Go diagnostic in a small floating window.
- `Ctrl-w d` is the focused “show me the full error” workflow when inline text
  is truncated or more context is needed; it does not change the code.
- Curriculum 6.3 is complete. Next: inspect LSP code actions with `Space c a`.

### Break Checkpoint

- Hamel paused after completing Curriculum 6.1 through 6.3.
- Next unconfirmed action: press `Space c a` on one intentional diagnostic and
  inspect the available LSP code actions without selecting blindly.
- The saved Go fixture remains clean and passes `go test ./...` plus
  `gopls check`.
- The live `main.go` buffer intentionally remains modified but unsaved with
  `greet` and `goodbye` lowercase so the two diagnostics are ready for Lesson
  6.4. Do not press `Space w` on that buffer unless the typos are fixed first.
- Safe cleanup if the diagnostic fixture is no longer wanted: press `u` twice
  and verify both errors disappear before saving, or reload only after
  confirming there are no other wanted unsaved edits.

## 2026-07-22 — Session 020: PDF Preview Limits

### Inline Preview Versus PDF Reader

- A real three-page Letter PDF rendered as one large white image inside
  Neovim. The source PDF is healthy; the awkward view comes from Snacks
  rasterizing only a page for a quick terminal preview.
- Snacks automatically fits that image to the available Neovim window, but it
  does not provide the normal multi-page navigation, text search, or zoom of a
  PDF reader.
- The existing `Space o` mapping opens the current PDF in its default macOS
  application (normally Preview). This is the intended workflow for reading;
  keep the inline view for a quick visual check.
- Pending confirmation: Hamel should press `Space o` from the PDF buffer and
  confirm that Preview opens the same file.
- The first `Space o` attempt happened while focus was still in the Snacks
  Explorer. The `[No Name]` filename and `snacks_picker_list` filetype in the
  status line proved that the current buffer was the Explorer list, not the
  PDF.
- Recovery checkpoint: press `Space l` from Explorer to focus the PDF window,
  verify that the PDF filename appears in the status line, and only then use
  `Space o`.
- Clarification: `Space l` only changes which Neovim window receives the next
  key. After focus reaches the PDF, `Space o` opens macOS Preview as a separate
  application; the readable PDF will not remain inside the terminal.

### Full Terminal PDF Viewer Research

- Correction: Ghostty can host a full terminal PDF viewer because it supports
  the Kitty graphics protocol. The limitation belongs to Snacks' lightweight
  image preview, not to the terminal itself.
- `fancy-cat` is the best current fit to evaluate: Homebrew packages it, its
  documentation names Ghostty as supported, and it provides page navigation,
  zoom, panning, fit-width, a status bar, dark recoloring, and Vim-like keys.
- It is a standalone terminal application rather than a Neovim image plugin.
  The safest integration is to run it directly in a Ghostty/Herdr terminal
  surface and only wire Neovim to launch it after a real compatibility test.
- No viewer was installed and no keymap was changed yet; Hamel's approval and
  a Ghostty/Herdr smoke test are the next steps.

### fancy-cat Installed and Snacks PDF Preview Disabled

- Hamel approved installing `fancy-cat` and explicitly asked to remove the
  annoying Snacks PDF preview.
- Installed Homebrew's bottled `fancy-cat` `0.6.0_1`; recorded it in both the
  shared personal-Mac and Resilience editor Brewfiles.
- A direct Herdr smoke test opened the real three-page PDF in a new tab. The
  viewer status line reported page `1:3`, proving that the full document loaded
  through Herdr's enabled Kitty-graphics path.
- Snacks remains enabled for ordinary image and video formats, but `pdf` was
  removed from its configured format list. It will no longer rasterize PDFs in
  a Neovim buffer.
- Added a PDF `BufReadCmd`: opening a PDF launches `fancy-cat` in a focused
  Herdr tab, or in a new Ghostty window when Neovim is outside Herdr. Neovim
  keeps only a small instruction buffer rather than the former white preview.
- `Space o` now reopens a PDF in `fancy-cat`; non-PDF files still open in their
  normal macOS application.
- Viewer keys: `n` / `p` change pages, `i` / `o` zoom, `j` / `k` pan, `w` fits
  width, `z` toggles dark recoloring, and `:q` quits. These mappings belong to
  `fancy-cat`, not Neovim.
- Scroll clarification: lowercase `j` / `k` move down / up; uppercase `J` / `K`
  make the same moves in larger steps. Confirmation remains pending.
- Pending visual confirmation: restart Neovim, open a PDF from Explorer, and
  confirm that no Snacks raster preview appears and the new Herdr PDF tab
  opens automatically.
- Headless verification confirmed that Snacks' effective format list excludes
  `pdf` and that opening the real PDF produces the `pdf_launcher` instruction
  buffer without starting a GUI during automated checks.
- StyLua, both Brewfile parse checks, whitespace validation, and the Mac
  bootstrap test suite pass. The Resilience Brewfile is fully satisfied on this
  Mac; the shared personal Brewfile still reports only the unrelated missing
  Zed cask.

### fancy-cat Status Bar Transparency

- Hamel asked to remove the opaque black strip without losing `VIS`, the PDF
  filename, or the current and total page numbers.
- fancy-cat defaults that row to explicit black. Its managed config now sets
  only the status-bar background to libvaxis' terminal-default color, so
  Ghostty's existing opacity shows through while all status text remains.
- Pending visual confirmation: quit and reopen the PDF viewer, then confirm the
  row blends into the surrounding Ghostty background.

### Terminal PDF Viewer Comparison

- Researched fancy-cat, Bookokrat, tdf, MeowPDF, termpdf.py, Sioyek, and
  Zathura against Hamel's Ghostty, Herdr, macOS, and Vim-key workflow.
- **Bookokrat is the strongest modern terminal-reader candidate:** it explicitly
  supports Ghostty, installs from Homebrew, and adds PDF search, links, table of
  contents, bookmarks, jump history, app-side annotations, Markdown export,
  Vim normal mode, and SyncTeX integration.
- **fancy-cat remains the cleaner quick viewer:** it launches one PDF directly,
  hot-reloads, has simple modal controls, and is easy to theme, but it lacks
  text search, links, bookmarks, and annotations.
- tdf is an active middle option with asynchronous rendering and search, but
  it lacks Bookokrat's richer reading features and fancy-cat's configurability.
- MeowPDF is modern but officially targets Kitty and has no Homebrew formula;
  termpdf.py is legacy alpha software with an aging Python stack.
- Sioyek and Zathura are separate GUI applications rather than Herdr-native
  viewers. Sioyek is the stronger optional research-paper app; neither replaces
  an in-terminal viewer for this workflow.
- Decision pending: keep fancy-cat as the default unless Hamel approves a
  side-by-side Bookokrat smoke test. No package or keymap changed during this
  research pass.

### Bookokrat Selected, Tested, and Themed

- Hamel chose Bookokrat as the full terminal reader after comparing it with
  fancy-cat and tdf. Homebrew's `bookokrat` `0.3.12` is now installed, and
  `fancy-cat` plus its no-longer-needed Homebrew dependencies were removed.
- The real three-page course PDF opened successfully in a focused Herdr tab.
  Hamel visually confirmed the result looked good; Bookokrat reported all three
  pages and rendered through Herdr's enabled Kitty-graphics transport.
- Added a managed `Hamel Nord` Base16 theme using the same core colors as
  Ghostty and Zed. Bookokrat's startup log confirmed that it loaded and applied
  `Hamel Nord`, inherited a transparent background, detected Ghostty truecolor,
  and enabled PDF scrolling and comments.
- Durability correction: Bookokrat atomically replaces `config.yaml` when it
  saves settings, so a single-file symlink does not survive. The bootstrap now
  links the whole `~/.config/bookokrat` directory; Bookokrat can safely rewrite
  its settings while the tracked Nord theme remains the source of truth.
- Neovim's PDF launcher now calls Bookokrat inside Herdr or a new Ghostty
  window. Snacks PDF raster previews remain disabled, and `Space o` reopens the
  current PDF in Bookokrat.
- Everyday Bookokrat keys: `j` / `k` scroll, `h` / `l` change pages, `+` / `-`
  zoom, `z` / `Z` fit height / width, `/` searches, `?` opens help, and `q`
  quits. If `NORMAL` is visible, press `n` to leave Bookokrat's Vim normal mode
  before `q`.
- The personal and Resilience Brewfiles, link scripts, bootstrap tests, setup
  inventories, Neovim guide, and optional curriculum checkpoint now reproduce
  Bookokrat and its managed theme instead of fancy-cat.
- Optional checkpoint `10.D8` remains open until Hamel personally practices the
  core navigation, search, zoom, and quit flow from Neovim.

### Bookokrat Background Adjustment

- Hamel found the first Nord document canvas slightly too dark. Kept
  `transparent_background: true` so Bookokrat's interface continues to inherit
  Ghostty's opacity and blur.
- Lightened only the custom theme's `base00` document surface from `#3B4252`
  to `#434C5E`, one restrained Nord step brighter. This preserves the terminal's
  transparent feel without making the PDF text area washed out.

### Bookokrat Canvas Blend

- Hamel later preferred the PDF canvas to disappear into the surrounding
  Ghostty window. Bookokrat cannot make the rasterized PDF image truly
  transparent, so the managed theme now matches both `base00` and `base01` to
  Ghostty's exact Nord background, `#3B4252`.
- The PDF remains an opaque image, but its canvas should visually blend with
  Ghostty instead of appearing as a separate lighter rectangle.
- Visual verification showed that matching Ghostty's configured base color was
  insufficient: the opaque PDF stayed at `#3B4252`, while Ghostty's 90% opacity
  composited the surrounding area to approximately `#4F5462`. Screenshot pixel
  sampling confirmed that difference, so `base00` and `base01` now use the
  visible composite color `#4F5462` instead.
- A second screenshot proved why that approach cannot hold: the Bookokrat page
  correctly changed to `#4F5462`, but Ghostty's transparent surroundings had
  shifted to approximately `#3C4251` because the content behind the window was
  different. An opaque PDF raster cannot track a dynamic translucent terminal
  background. Restored the last readable canvas color, `#434C5E`, and stopped
  treating color matching as true transparency.

### Bookokrat Mouse-Selection Lag

- Hamel confirmed that dragging across PDF text in Bookokrat feels severely
  delayed inside Herdr. The live logs confirmed this is real rather than a
  trackpad or Ghostty problem.
- Bookokrat `0.3.12` sends an update for every mouse-drag event. Its Kitty
  graphics path then rebuilds and uploads the full PDF page instead of only the
  small selection overlay. One captured drag caused 29 page invalidations, 151
  stale renders, and 26 fresh image uploads.
- Herdr `0.7.4` amplifies the problem: the same drag exceeded its fixed 32 MiB
  graphics-frame limit 70 times and saturated its input queue, dropping 1,447
  mouse events. Herdr `0.7.5` keeps the same 32 MiB limit, so upgrading alone
  does not fix this workflow.
- Practical workaround: avoid long mouse drags. Press `n` for Bookokrat normal
  mode, then use `v` or `V` plus Vim motions to select; press `H` to highlight,
  `d` to add a note, or `c` to copy. Double-clicking a word or triple-clicking a
  paragraph also produces a single selection update instead of a render storm.
- Hamel tested zooming out twice before dragging. It did not improve the lag,
  so reducing `pdf_scale` is not a viable workaround for this PDF and setup.
- For less laggy mouse dragging, open Bookokrat directly in Ghostty outside
  Herdr. This removes Herdr's graphics-frame and input-queue bottlenecks,
  although the upstream Bookokrat full-page rerender behavior still exists.

### tdf Side-by-Side PDF Trial

- Hamel asked to test `itsjunetime/tdf` after Bookokrat's mouse-selection lag.
  Installed Homebrew's stable `tdf` `0.5.0` bottle and opened the same course
  PDF directly in a separate Ghostty window. Bookokrat remains installed and
  the Neovim launcher has not changed while the comparison is pending.
- `tdf` is designed as a responsive image-based reader with asynchronous
  rendering, search, hot reload, Vim-like navigation, and Kitty zoom/pan.
- Important limitation: `tdf` does not implement selectable PDF text, copying,
  annotations, or persistent highlights. Its mouse code handles scrolling and
  zooming only. `/` can search extracted text and paint search matches, but a
  mouse drag cannot create the kind of highlight Bookokrat supports.
- Hamel launched the real PDF in `tdf` and confirmed that mouse dragging cannot
  select or highlight its text. This is expected behavior, not a configuration
  problem, and makes `tdf` unsuitable as the annotation-focused replacement.
- Final decision: keep Bookokrat and remove `tdf`. Homebrew's `tdf` `0.5.0`
  bottle was uninstalled; it was never added to the Brewfiles or Neovim PDF
  launcher, so no persistent setup rollback was needed.
- Trial keys: `h` / `l` move one page, `j` / `k` move a screenful, `/` searches,
  `n` / `N` move between matches, `z` toggles fit/fill, `?` opens help, and `q`
  quits. Keep `tdf` only if its reading and search speed is valuable enough to
  use alongside Bookokrat.

### Bookokrat Final Persisted Defaults

- Closed the temporary test viewers before the final dotfiles commit so their
  in-memory settings could not overwrite the managed configuration.
- Restored `pdf_scale: 1` and `pdf_render_mode: scroll`. The temporary 78% zoom
  and page mode came from lag and canvas experiments; neither was chosen as a
  permanent preference.
- Final appearance: Bookokrat's interface inherits Ghostty transparency, while
  the PDF page stays an opaque, readable Nord `#434C5E` canvas.
- Bookokrat is the sole managed PDF viewer. `fancy-cat` and `tdf` are removed;
  their earlier entries and key lists remain historical test notes only.
- Direct Ghostty removes Herdr's measured graphics-frame and input-queue
  bottlenecks, but Hamel has not yet confirmed how much it improves mouse
  selection. Bookokrat's full-page rerender still occurs either way.
- Removed `ghostscript` from both Mac Brewfiles and the current Mac because it
  was only used by the retired Snacks PDF renderer; Bookokrat does not need it.

## 2026-07-22 — Session 021: Snacks Picker Tab Selection Gotcha

- While searching the full home directory with `Space f`, Hamel pressed `Tab`
  expecting shell-style path completion. The picker showed `(5)`, meaning five
  results were selected.
- Before the fix, Snacks mapped `Tab` to **select this result and move down**;
  it did not complete directory names. Pressing `Enter` then created buffers
  for every selected result, and each PDF could request its own
  Ghostty/Bookokrat launch when its buffer was visited.
- The live preview was not the cause. Snacks reads ordinary file previews
  without opening them as editor buffers; the repeated launches came from the
  five confirmed selections.
- Recovery: cancel the pending Ghostty prompts, close the picker, reopen it with
  `Space f`, type fuzzy fragments such as `stevens submission`, and press
  `Enter` on one result without using `Tab`.
- Original mental model before remapping `Tab`: **typing narrows; `Ctrl-j` /
  `Ctrl-k` moves; `Enter` opens; `Tab` builds a multi-file selection.**
- The next checkpoint at that stage was confirming that a fuzzy-fragment retry
  opened only the intended PDF once.
- A second launcher issue amplified the five selections outside Herdr. Neovim
  currently passes `-e`, the Bookokrat executable, and the PDF as separate
  arguments through macOS `open`; Ghostty 1.3.1 can receive those absolute
  paths as open-file events, prompt before executing each one, and use its
  default `macos-dock-drop-behavior = new-tab` behavior.
- At the diagnosis checkpoint, the planned fix was to pass Bookokrat and the
  PDF as one Ghostty `initial-command` configuration argument. No launcher code
  had changed yet; the implementation and checks are recorded below.
- Precision: `Enter` creates buffers for all selected results but immediately
  loads only the first; the others can launch when later visited. The paired
  Bookokrat-path and PDF-path prompts from one load come from the Ghostty
  argument bug, not five simultaneous Bookokrat processes.
- Hamel clarified the acceptance rule: pressing `Enter` on one PDF must create
  exactly one Bookokrat viewer, never five.
- Fixed `Space f` specifically: `Tab` now moves down and `Shift-Tab` moves up in
  both the input and result list without selecting files. Other Snacks pickers
  keep their defaults, so this change is limited to the reported workflow.
- Fixed the direct Ghostty launcher by replacing the separate `-e`, executable,
  and PDF arguments with one shell-quoted `--initial-command=...` argument.
  Ghostty therefore receives no bare executable or PDF path to interpret as a
  macOS file-open event.
- Headless regression checks confirmed the effective file-picker mapping,
  preserved the unrelated grep-picker default, captured exactly one `open`
  call, and verified that a PDF path containing spaces remains inside the one
  initial-command argument. Ghostty 1.3.1 also accepts that argument format.
- Human verification remains pending. Restart Neovim so the loaded Snacks
  configuration resets, search with fuzzy fragments, optionally press `Tab`,
  and press `Enter` once on the PDF; expect one viewer and no execution prompt.
- Computer Use could not control Ghostty because terminal apps are blocked by
  its safety policy. Chronicle's latest frame was stale, so no visual prompt
  result was claimed.
- A real patched `Space o` launch created exactly one new Ghostty process and
  one Bookokrat child for the PDF. Its process arguments contained one
  `--initial-command=...` and no separate executable or PDF file-open arguments.
- The test Bookokrat process was stopped afterward, which closed only its
  dedicated Ghostty window. Hamel's existing viewer was left untouched.
- Remaining human check: restart the open Neovim, use `Space f`, press `Tab`
  once, then press `Enter` on the PDF and visually confirm there is no security
  prompt.

## 2026-07-22 — Session 022: Duplicate PDF Autocmd Match

- Hamel confirmed that running `bookokrat "<pdf-path>"` directly created one
  viewer, while opening the same PDF from Oil created multiple viewers.
- An isolated Neovim UI test intercepted the Ghostty command without opening
  real windows. One `Enter` in Oil produced two identical launcher calls even
  though only one PDF `BufReadCmd` autocmd was defined.
- Root cause: macOS Neovim sets `fileignorecase=true`. The autocmd registered
  both `*.pdf` and `*.PDF`, so the lowercase PDF matched both patterns and ran
  the same callback twice.
- Fixed the source of the duplicate by replacing the two-pattern list with one
  portable mixed-case pattern: `*.[pP][dD][fF]`.
- Put the launcher autocmd in a named group that clears on config reload, so
  sourcing the keymap file cannot stack additional PDF callbacks.
- The exact Oil UI regression test now reports one matching pattern and one
  launcher call from one `Enter`.
- Mental model: Oil and the Snacks file picker hand the selected path to a
  Neovim buffer; Tree-sitter parses code and is not part of PDF navigation.
- Human checkpoint: restart Neovim, open the PDF once from Oil, and confirm
  that exactly one Bookokrat viewer appears.

## 2026-07-22 — Session 023: Bookokrat in a Ghostty Tab

- Hamel chose to keep Neovim open and launch Bookokrat in a new tab of the
  current Ghostty window instead of a separate macOS window.
- The previous direct launcher used `open -na Ghostty.app`; `-n` starts a new
  Ghostty application instance, so a separate window was expected behavior.
- Ghostty 1.3.1 exposes a native AppleScript API for creating a tab with its
  own command and working directory. Neovim now uses that API and targets
  Ghostty's front window; no simulated keyboard input or focus timing is used.
- Bookokrat's executable, PDF path, and directory are passed as separate
  `osascript` arguments. AppleScript quotes the command values, so paths with
  spaces remain one argument.
- First correction: Ghostty's CLI-only `shell:` prefix does not belong in the
  AppleScript `command` property. It made Bash search for a program named
  `shell:exec`. The launcher now passes the executable and PDF directly.
- A short `/usr/bin/touch` smoke test did execute successfully, but Ghostty
  showed its quick-exit screen because that test command ended immediately.
  The exact test tab was closed afterward; it was not a Bookokrat failure.
- Automated checks confirm one launcher request, preserved paths with spaces,
  valid AppleScript syntax, clean Lua formatting, and clean Neovim startup.
- Human checkpoint: restart Neovim, open one PDF from Oil, and confirm
  Bookokrat opens once in a new tab beside the Neovim tab.

## 2026-07-22 — Session 024: Integrated Ghostty Tabs

- Hamel confirmed the Bookokrat launcher now opens in a tab beside Neovim.
- The native macOS tab strip looked like a large opaque gray second bar even
  though Ghostty used `macos-titlebar-style = transparent`. That option makes
  the titlebar transparent but does not style the separate native tab strip.
- Switched to `macos-titlebar-style = tabs`, Ghostty's custom titlebar that
  integrates the tabs into one compact row and matches the terminal background.
- Kept the accepted `background-opacity = 0.90` and `background-blur = 20`.
  No macOS glass effect was added yet, so this test changes only the tab layout.
- Ghostty's config validator passed, and its effective configuration reports
  `macos-titlebar-style = tabs`.
- Ghostty applies titlebar-style changes only to new windows. Open a new window
  or restart Ghostty to judge the result.
- Hamel's visual check confirmed the integrated style removed the separate
  titlebar row, but the selected tab still looked like the same gray pill.
  Ghostty 1.3.1 has no separate tab-pill color or opacity setting.
- Started an uncommitted macOS 26 trial with
  `background-blur = macos-glass-clear`. The existing `0.90` opacity remains;
  this makes the whole Ghostty window glassier, not only the selected tab.
- Human checkpoint: fully restart Ghostty, compare terminal readability and
  the active tab against the previous screenshot, then keep or revert the
  glass trial.
- Hamel rejected the clear-glass trial because it did not improve the tab
  appearance. Restored the accepted `background-blur = 20`; integrated tabs
  remain enabled because they still remove the extra titlebar row.
