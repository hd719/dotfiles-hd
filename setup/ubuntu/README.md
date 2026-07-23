# Ubuntu Workstation

Lean daily-driver setup tested on Ubuntu 26.04 ARM64. The installer rejects
non-Ubuntu hosts.

## Install

Prerequisites: network access, `sudo`, Git, and GitHub SSH access.

```bash
mkdir -p "$HOME/Developer"
git clone git@github.com:hd719/dotfiles-hd.git \
  "$HOME/Developer/dotfiles-hd"
cd "$HOME/Developer/dotfiles-hd"
bash setup/ubuntu/setup.sh
```

Log out and back in once so Zsh becomes the login shell and Docker group
membership applies. Rerunning setup repairs missing packages and links without
replacing an already-correct link.

## What Setup Changes

- Installs the lean APT package set, Ghostty, Docker, Zsh, ImageMagick,
  Ghostscript, clipboard tools, and Zsh plugins.
- Installs Hasklug Nerd Font `3.4.0` from a checksum-verified archive.
- Installs exact runtimes and editor tools from `setup/ubuntu/mise.toml`.
- Restores locked Neovim plugins and required Tree-sitter parsers.
- Enables Docker, adds the current user to its group, and changes the login
  shell to Zsh.
- Sets Git's global editor to Neovim and global excludes file to
  `~/.gitignore_global`.

The default setup does not install cloud tools, Ruby, Redis, VS Code, alternate
launchers, or extra package managers.

## Ownership

| Owner      | State                                                                                      |
| ---------- | ------------------------------------------------------------------------------------------ |
| APT        | System packages, Ghostty, Docker, `lsd`, build libraries, clipboard tools, and Zsh plugins |
| mise       | Pinned Neovim, runtimes, language servers, formatters, and editor CLIs                     |
| User files | Verified Nerd Font and backed-up configuration links                                       |

Existing files, directories, and dangling links are timestamp-backed up beside
their live path before replacement. Credentials and application runtime state
are never linked.

## Link Inventory

| Live path                              | Source                          |
| -------------------------------------- | ------------------------------- |
| `~/.zshrc`                             | `setup/ubuntu/.zshrc`           |
| `~/.config/ghostty/config`             | `setup/ubuntu/ghostty.conf`     |
| `~/.config/zsh/aliases.zsh`            | `config/zsh/aliases.zsh`        |
| `~/.config/starship.toml`              | `config/starship/starship.toml` |
| `~/.gitignore_global`                  | `config/git/.gitignore_global`  |
| `~/.config/mise/config.toml`           | `setup/ubuntu/mise.toml`        |
| `~/.config/nvim`                       | `config/nvim`                   |
| `~/.local/graphql-lsp/bin/graphql-lsp` | `setup/ubuntu/bin/graphql-lsp`  |

Ghostty uses the shared Hamel Nord profile. Neovim uses the shared
`config/nvim`; no Linux-only Lua fork exists.

## Verify

```bash
bash setup/ubuntu/setup-neovim.sh --check
zsh -lic \
  'command -v nvim && command -v mise && command -v docker && command -v ghostty && alias hwatch'
nvim ~/.config/nvim/README.md
```

## Update

```bash
bash setup/ubuntu/update-system.sh
```

The updater accepts only `git@github.com:hd719/dotfiles-hd.git`, pulls `master`
with `--ff-only`, then runs APT full-upgrade and refreshes pinned mise and
Neovim state. A failed repository sync never resets local changes; package
maintenance continues and any reboot requirement is reported.

## One-Time Legacy Migration

This is destructive and never runs from normal setup:

```bash
bash setup/ubuntu/cleanup-legacy.sh --yes
bash setup/ubuntu/setup.sh
```

It removes the old Docker CE repository and packages, AWS CLI, Terraform,
kubectl, Redis, Ulauncher, VS Code, fastfetch PPA, APT Go, development snaps,
rbenv, direct Starship install, and superseded user editor toolchains. It
preserves projects, Docker data, AWS and Kubernetes credentials, Firefox,
Ubuntu system snaps, and the snap service.
