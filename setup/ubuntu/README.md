# Ubuntu Workstation

Lean daily-driver setup for Hamel's Ubuntu VM. Tested on Ubuntu 26.04 ARM64.

## What Owns What

- APT: Git, Zsh, Ghostty, Docker, build libraries, clipboard tools, ImageMagick,
  Ghostscript, and Zsh plugins.
- mise: exact versions of Neovim, runtimes, language servers, formatters, and
  editor command-line tools from [`mise.toml`](mise.toml).
- User fonts: Hasklug Nerd Font `3.4.0`, because Ubuntu APT does not provide a
  Nerd Font package for the Neovim icons.

The default setup does not install cloud tools, Ruby, Redis, VS Code, extra
launchers, or alternate package managers.

## Fresh Setup

```bash
git clone git@github.com:hd719/dotfiles-hd.git ~/Developer/dotfiles-hd
cd ~/Developer/dotfiles-hd
bash setup/ubuntu/setup.sh
```

Log out and back in once so the new Zsh login shell and Docker group apply.

The installer backs up an existing target before linking over it. Rerunning it
repairs missing packages and links without creating duplicate backups.

## Ubuntu Link Inventory

- `~/.zshrc` -> `setup/ubuntu/.zshrc`
- `~/.config/ghostty/config` -> `setup/ubuntu/ghostty.conf` ->
  `config/ghostty/config`
- `~/.config/starship.toml` -> `config/starship/starship.toml`
- `~/.gitignore_global` -> `config/git/.gitignore_global`
- `~/.config/mise/config.toml` -> `setup/ubuntu/mise.toml`
- `~/.config/nvim` -> `config/nvim`
- `~/.local/graphql-lsp/bin/graphql-lsp` ->
  `setup/ubuntu/bin/graphql-lsp`

An existing target is timestamp-backed up beside its live path before the link
is created. Credential and app-runtime directories are not linked.

## Validate Neovim

```bash
bash setup/ubuntu/setup-neovim.sh --check
nvim ~/.config/nvim/README.md
```

The shared Ghostty profile uses Hamel Nord, an 88% opaque background, blur, and
Maple Mono NF with Hasklug Nerd Font as the Ubuntu fallback. Neovim continues to
use the shared `config/nvim` setup; no Linux-only Lua fork is required.

## Update

```bash
bash setup/ubuntu/update-system.sh
```

This updates APT and mise, then restores the pinned Neovim tools and plugins.

## One-Time Cleanup For The Existing VM

This cleanup is intentionally separate from the reusable installer. Run it once
before `setup.sh` when migrating a VM built by the old Ubuntu setup:

```bash
bash setup/ubuntu/cleanup-legacy.sh --yes
bash setup/ubuntu/setup.sh
```

It removes the old Docker CE repository/packages, AWS CLI, Terraform, kubectl,
Redis, Ulauncher, VS Code, fastfetch PPA, APT Go, development snaps, rbenv, and
the old direct Starship install and superseded user-level editor toolchains. It
preserves projects, Docker data, `~/.aws`, `~/.kube`, Firefox, Ubuntu system
snaps, and the snap service.
