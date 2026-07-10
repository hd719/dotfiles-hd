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

Single file or subdirectory links:

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

## Verification

After symlink or config changes:

```bash
git status --short --branch
readlink <live-path>
test -e <live-path>
```

For shell config changes, start a fresh shell with `zsh -lic '<check>'`.

Do not commit or push unless Hamel asks.
