# Standalone Development MacBook

`mac-pro` is the full local-development MacBook profile. It installs the whole
local package stack through Homebrew. Exact language runtimes use mise, which
Homebrew installs.

## Install

Follow the [shared macOS bootstrap](../shared/macos/README.md):

```bash
hosts/shared/macos/bootstrap.sh --profile mac-pro --dry-run
hosts/shared/macos/bootstrap.sh --profile mac-pro --check
hosts/shared/macos/bootstrap.sh --profile mac-pro --apply
hosts/shared/macos/bootstrap.sh --profile mac-pro --apply
hosts/shared/macos/doctor.sh --profile mac-pro
```

Packages come from:

- `hosts/shared/macos/Brewfile` for the common full-Mac toolchain
- `hosts/mac-pro/Brewfile` for the standalone MacBook overlay

The `mac-pro` overlay installs Karabiner Elements.
Vorssaint's reviewed manual settings backup is preserved under
[`config/vorssaint`](../../config/vorssaint/README.md) for an optional future
reinstall. It is no longer installed by this profile.

Chezmoi applies `chezmoi/profiles/mac-pro.paths`, including the MacBook shell,
shared application configuration, full Neovim configuration, mise, and
Karabiner. Git identity, credentials, secrets, services, Docker data, and
application state remain machine-owned.

Use the timestamped Chezmoi backup printed during apply for configuration
rollback. Package removal is never part of rollback.

## Codex clipboard in Rex

Use `cod`, `codf`, `codfl`, `codr`, `codra`, or `codrl` to start or
resume Codex. In native Rex sessions, these shortcuts add `SSH_TTY=rex` for
that process so Codex also forwards selected text to the viewing Mac's
clipboard. Normal Codex selection and scrolling stay available.

Existing SSH markers are preserved. Other terminals and noninteractive
shortcuts such as `codd`, `codu`, and `codx` keep their existing behavior.
Plain `codex` remains the unwrapped command. This is a workaround verified
with Codex 0.166.0, not a global shell setting. Start a fresh shell after the
merged dotfiles update to load the shortcuts.

## Terminal colors on personal Macs

Air, Pro, and Mini load [one color policy](../../config/zsh/shared/colors.zsh).
It clears inherited `FORCE_COLOR` values so CLIs detect the terminal's full
color support. It preserves `COLORTERM` and honors `NO_COLOR`. A deliberate
per-command override, such as `FORCE_COLOR=3 command`, still works.

The old Pro-only `FORCE_COLOR=1` setting restricted Codex 0.166.0 to basic
colors. That fallback also removed its input shading. Automatic detection
restores the Air's full-color Dali appearance, including the shaded input box.
`tui.theme` controls syntax highlighting; the input shade is computed by
[Codex itself](https://github.com/openai/codex/blob/rust-v0.166.0/codex-rs/tui/src/style.rs#L212-L267).
The shared `cod`, `codf`, `codfl`, `codr`, `codra`, and `codrl` shortcuts
also select Dali on all three Macs. They pass the theme at launch without
rewriting Codex configuration, login, or session files. Plain `codex` and
noninteractive shortcuts still use machine-owned Codex settings. A later
`-c tui.theme=...` argument can override Dali for one launch.

After merging and syncing all three checkouts, open a fresh terminal shell
and restart or resume Codex. Existing symlinks pick up this shell-only change
without a Chezmoi apply. Running Codex sessions keep their old environment.

## Code review

Install reviewr once, then copy the shared preset into its plugin settings:

```bash
herdr plugin install persiyanov/herdr-reviewr
reviewr_config_dir="$(herdr plugin config-dir persiyanov.reviewr)"
cp config/herdr/reviewr.toml "$reviewr_config_dir/config.toml"
exec zsh
```

Run these commands from a Git repository:

| Command    | Opens                                                                  |
| ---------- | ---------------------------------------------------------------------- |
| `review`   | Reviewr for the current repository                                     |
| `reviewpr` | Reviewr against the open PR's target branch, or the repository default |
| `hpr`      | The same review as `reviewpr`                                          |

PR reviews fetch the target branch first and stop if fetching fails. Branch
reviews include both committed changes and current edits.

In Herdr, reload settings once with `Ctrl+B`, then `r`. Open or close the wide
review pane with `Ctrl+B`, then `Shift+V`. The preset uses Nord colors, a file
list on the left, and manual opening.

The plugin install stays manual. Hunk is no longer installed by the MacBook
profile; its settings remain available for other hosts.
