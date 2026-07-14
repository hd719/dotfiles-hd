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
