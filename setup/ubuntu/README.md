# Ubuntu Neovim Setup

Use this focused path when you want the shared Neovim configuration without
running the larger Ubuntu workstation setup.

The larger `setup/ubuntu/setup.sh` uses this same sequence with the `desktop`
profile after it installs the shared mise toolchain. Its final config step uses
`setup/ubuntu/link-configs.sh`, which creates timestamped backups and keeps tmux
plugins local while linking `tmux.conf` and shared status scripts separately.

It supports Ubuntu 26.04 or newer. Ubuntu dependencies come from APT, not
Homebrew or Snap. When Ubuntu's package is missing or too old, the installer
uses the pinned official ARM64 or AMD64 release instead.

## Choose a Profile

Profiles are cumulative. Choose one and use the same value for every command.

| Profile | Use it for |
| --- | --- |
| `core` | A small SSH or headless machine: editor, search, Git, and plugins. |
| `full` | A development machine: `core` plus language servers and formatters. |
| `desktop` | A graphical machine: `full` plus image and PDF preview tools. |

`desktop` does not install Ghostty or Herdr.

`full` and `desktop` require host-managed Node 18+ and gopls 0.23.0+. The
Ubuntu adapter preserves Node and installs its pinned gopls when gopls is
missing or stale.

On Hamel's personal Ubuntu development machines, mise is that host manager.
It uses the same Bun, Go, Node, Python, and `gopls` pins as the personal Mac.
Generic `core` servers may skip mise and keep their existing system tools.

## Protect Existing Work

Check the clone before pulling or switching branches:

```bash
git status --short --branch
```

If it has changes, leave it alone. Use a separate clone or worktree for setup.
The simplest beginner-safe option is a separate clone:

```bash
git clone git@github.com:hd719/dotfiles-hd.git \
  "$HOME/Developer/dotfiles-hd-neovim-setup"
cd "$HOME/Developer/dotfiles-hd-neovim-setup"
```

## Install

The Ubuntu adapter installs external commands. The linker connects the shared
configuration, and the bootstrap verifies the tools and restores locked plugins.

```bash
cd /path/to/dotfiles-hd
PROFILE=full
export PATH="$HOME/.local/bin:$PATH"

./setup/ubuntu/install-mise.sh
mise exec -- ./setup/ubuntu/install-neovim-dependencies.sh "$PROFILE"
./setup/nvim/link-config.sh
mise exec -- ./setup/nvim/bootstrap.sh "$PROFILE"
```

Keep that export in the current shell. A child installer cannot change its
parent shell's `PATH`, so the installer's final `Next` message assumes this
user-local directory is still visible when you run the bootstrap.

`install-mise.sh` uses Ubuntu's official APT repository when mise is missing,
preserves an existing working command, then safely links the whole shared
`config/mise` directory. The adapter preserves that working Node, npm, and Go
toolchain. It does not delete npm or npx. Prettier remains project-local.
`mise exec --` makes the installed runtimes available to the next command
immediately; a child installer cannot modify its parent shell.

## Prove It Is Safe to Rerun

Run the installer and bootstrap a second time. Installed packages and matching
pinned tools should become no-ops.

```bash
export PATH="$HOME/.local/bin:$PATH"
./setup/ubuntu/install-mise.sh
mise exec -- ./setup/ubuntu/install-neovim-dependencies.sh "$PROFILE"
mise exec -- ./setup/nvim/bootstrap.sh "$PROFILE"
mise exec -- ./setup/nvim/check-dependencies.sh "$PROFILE"
mise exec -- nvim --headless '+qa'
```

The second mise run should report the existing link and installed pins. If the
dependency check reports a missing command, fix that specific item and rerun
the same profile. Do not switch package managers to make the check pass.

Offline Ubuntu regression checks:

```bash
./setup/ubuntu/tests/install-mise.sh
./setup/ubuntu/tests/install-neovim-dependencies.sh
./setup/ubuntu/tests/link-configs.sh
```
