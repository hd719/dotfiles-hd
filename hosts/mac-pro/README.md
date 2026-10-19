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

The `mac-pro` overlay installs Karabiner Elements and Vorssaint.

Chezmoi applies `chezmoi/profiles/mac-pro.paths`, including the MacBook shell,
shared application configuration, full Neovim configuration, mise, and
Karabiner. Git identity, credentials, secrets, services, Docker data, and
application state remain machine-owned.

Use the timestamped Chezmoi backup printed during apply for configuration
rollback. Package removal is never part of rollback.

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
