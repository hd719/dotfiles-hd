# AGENTS.md

Be concise. This repo is Hamel's source of truth for rebuilding personal machines.

## Mental Model

- `config/` contains portable app and tool configuration.
- `setup/` contains machine bootstrap scripts and machine-specific setup files.
- The current personal Mac symlink inventory lives in `README.md`.

## Before Editing

1. Run `git status --short --branch`.
2. Inspect the live path and the dotfiles source before changing anything.
3. Use `readlink`, `cmp`, `diff`, or `find` to understand whether a path is already linked, equal, different, or app-managed runtime state.

## Symlink Rules

- If Hamel explicitly asks to symlink a tool, do it.
- Always back up an existing live file or directory before replacing it.
- Use timestamped backups beside the live path, like `path.backup-YYYYMMDD-HHMMSS`.
- Verify the link after creating it with `readlink` and basic `test -f` or `test -d` checks.
- Update the README inventory in the same change whenever symlink state changes.

## Current Intended Links

Whole directory links:

- `~/.config/btop` -> `config/btop`
- `~/.config/fastfetch` -> `config/fastfetch`
- `~/.config/karabiner` -> `config/karabiner`
- `~/.config/mise` -> `config/mise`
- `~/.config/nvim` -> `config/nvim`

Single file or subdirectory links:

- `~/Library/Application Support/com.mitchellh.ghostty/config` -> `config/ghostty/config`
- `~/.config/herdr/config.toml` -> `config/herdr/config.toml`
- `~/.config/zed/settings.json` -> `config/zed/settings.json`
- `~/.config/zed/keymap.json` -> `config/zed/keymap.json`
- `~/.config/zed/themes` -> `config/zed/themes`

## Do Not Blindly Symlink

- `~/.config/tmux` because live plugins live there. Review/link `tmux.conf` separately.
- `~/.gitconfig` because live config can differ by machine.
- `~/.config/raycast` because it contains extension/runtime state.
- `~/.config/1Password`, `~/.config/op`, `~/.config/gh`, or `~/.config/cagent` without a specific request because they contain credential, auth, or app-managed state.
- `~/.config/zed/prompts` because it is Zed runtime database state.
- `~/Library/Application Support/Zed` because it is app runtime state.
- Herdr logs, sockets, sessions, and release notes under `~/.config/herdr`.

## Existing Helpers

- `config/zed/link-zed-config.sh`
- `config/herdr/link-herdr-config.sh`

Prefer these scripts when they match the task.

## Zed Theme Profiles

- `Hamel Nord` pairs with `config/zed/themes/hamel-nord.json`.
- `Hamel Nord Blur` pairs with `config/zed/themes/hamel-nord-blur.json`.
- Keep both profiles in `config/zed/settings.json` and preserve their matching sidebar and scrollbar settings.
- Switch profiles in Zed with `settings profile selector: toggle` from the command palette.
- Blur colors use `#RRGGBBAA`; `ed` is 92.9% opacity. For opacity changes, keep `background`, `status_bar.background`, `title_bar.background`, and `title_bar.inactive_background` identical in the blur theme file and its `theme_overrides` entry.

## Neovim Teaching Continuity

- The goal is to make Hamel a deadly Vim/Neovim warrior: fast, confident, and
  able to reason about the editor instead of memorizing unexplained magic.
- Before teaching Neovim, read `config/nvim/README.md`,
  `config/nvim/CURRICULUM.md`, and `config/nvim/LEARNING_LOG.md` so lessons
  resume from the last checkpoint.
- `CURRICULUM.md` is the checkable skill-progress source of truth;
  `LEARNING_LOG.md` is the append-only evidence of what happened in each
  session. Keep both current.
- Teach interactively in small steps. Give one concrete action, wait for Hamel
  to try it, explain what happened, and then continue.
- Check a curriculum sub-lesson only after Hamel practices it and confirms the
  result. Add the supporting session number beside the completed checkbox.
- Keep checkboxes atomic. Never group several keys or behaviors into one checked
  item when Hamel practiced only part of the group.
- A lesson is complete when every core sub-lesson is checked. Optional deep
  dives never block progress and may remain unchecked permanently.
- If Hamel wants to go deeper, add the new topic under that lesson's Optional
  Deep Dives before teaching it. Do not silently expand the core track.
- Default to the first unchecked core item in the earliest incomplete lesson,
  unless Hamel explicitly chooses another topic.
- Keep the curriculum's `Current Checkpoint` synchronized whenever progress
  changes.
- Every Neovim concept, key, workflow, conflict, or correction taught must be
  documented in `config/nvim/LEARNING_LOG.md` during that session. Do not rely
  on chat history as the record.
- Keep the learning log append-only. Start each new teaching session with the
  next numbered, dated entry and preserve older entries.
- Each session entry must include what was practiced, the useful mental model,
  any unresolved confusion or key conflict, and the best next lesson.
- If a chat or agent handoff loses context, resume from the curriculum's first
  unchecked core item, confirm it against the latest log entry, and begin with
  one short recall checkpoint.

## Verification

After symlink or config changes:

```bash
git status --short --branch
readlink <live-path>
test -e <live-path>
```

For shell config changes, start a fresh shell with `zsh -lic '<check>'`.

Do not commit or push unless Hamel asks.
