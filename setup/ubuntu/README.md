# Ubuntu Workstation

Lean daily-driver setup tested on Ubuntu 26.04 ARM64. The installer rejects
non-Ubuntu hosts.

New to Linux administration? Start with the
[Ubuntu Field Guide for a Mac User](GUIDE.md).

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
- Installs exact runtimes, editor tools, Herdr, Hunk, Bookokrat, fastfetch, and
  diff-so-fancy from `setup/ubuntu/mise.toml`.
- Loads the portable full-development alias set, including Hunk, pnpm, Git, Go,
  Neovim, fastfetch, and tmux shortcuts.
- Uses `diff-so-fancy` for Git output with plain `less` as a safe fallback.
- Uses a higher-contrast autosuggestion color over the shared Ghostty Nord
  background instead of zsh-autosuggestions' low-contrast palette default.
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
| mise       | Pinned Codex CLI, Neovim, runtimes, language servers, formatters, and editor CLIs          |
| User files | Verified Nerd Font and backed-up configuration links                                       |

Existing files, directories, and dangling links are timestamp-backed up beside
their live path before replacement. Credentials and application runtime state
are never linked.

## Link Inventory

| Live path                              | Source                          |
| -------------------------------------- | ------------------------------- |
| `~/.zshrc`                             | `setup/ubuntu/.zshrc`           |
| `~/.config/ghostty/config`             | `setup/ubuntu/ghostty.conf`     |
| `~/.config/starship.toml`              | `config/starship/starship.toml` |
| `~/.gitignore_global`                  | `config/git/.gitignore_global`  |
| `~/.config/bookokrat`                  | `config/bookokrat`              |
| `~/.config/btop`                       | `config/btop`                   |
| `~/.config/fastfetch`                  | `config/fastfetch`              |
| `~/.config/herdr/config.toml`          | `config/herdr/config.toml`      |
| `~/.config/hunk/config.toml`           | `config/hunk/config.toml`       |
| `~/.config/mise/config.toml`           | `setup/ubuntu/mise.toml`        |
| `~/.config/nvim`                       | `config/nvim`                   |
| `~/.config/tmux`                       | `config/tmux`                   |
| `~/.local/bin/codex`                   | `setup/ubuntu/bin/codex`        |
| `~/.local/graphql-lsp/bin/graphql-lsp` | `setup/ubuntu/bin/graphql-lsp`  |

Ghostty uses the shared Hamel Nord profile. Neovim uses the shared
`config/nvim`; no Linux-only Lua fork exists. Herdr and Hunk link only their
configuration files so runtime state remains machine-owned. The linked btop
configuration disables save-on-exit so btop cannot rewrite the Git checkout;
edit the tracked config directly when changing btop settings.

## Tailscale Remote Access

Tailscale is a one-time authenticated install, separate from normal setup:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname=ubuntu-dev
tailscale ip -4
```

The thin Mac uses `ubuntu-vm-ts` as the primary Codex route and keeps
`ubuntu-vm` as the local VMware fallback. Both aliases use the Ubuntu SSH key
and forward the Mac agent.

Authenticate the pinned Codex CLI once from Ubuntu:

```bash
codex login --device-auth
codex --version
```

Codex desktop starts the remote app server through the Ubuntu login shell, so
`codex` must remain in that shell's `PATH`. The managed Codex launcher gives
the remote app server a stable path to the current forwarded agent socket, so
closing a separate Mac terminal session cannot strand Codex on a dead socket.

## Verify

Open Ubuntu through the Mac's `u` alias so SSH agent forwarding is active, then
run the one-command doctor:

```bash
cd "$HOME/Developer/dotfiles-hd"
bash setup/ubuntu/doctor.sh
nvim ~/.config/nvim/README.md
```

The doctor is read-only. It checks the canonical clean checkout, every managed
link, the Nerd Font, Zsh and development aliases, Codex CLI, Docker, Tailscale,
the pinned Neovim setup, and all four GitHub/Forgejo routes. Use `--offline` to
skip only the remote identity checks when the VM has no network.

## Update

```bash
bash setup/ubuntu/update-system.sh
```

The updater accepts only `git@github.com:hd719/dotfiles-hd.git`, pulls `master`
with `--ff-only`, then runs APT full-upgrade and refreshes pinned mise and
Neovim state. A failed repository sync never resets local changes; package
maintenance continues and any reboot requirement is reported.

## Arbiter and Forgejo Access

Ubuntu's existing personal key is pinned to plain `github.com`, which
authenticates as `hd719`. The Arbiter and Forgejo private keys stay on the thin
Mac and reach Ubuntu only through the forwarded SSH agent. Ubuntu stores their
matching public keys and machine-owned host aliases:

```text
github.com               GitHub as hd719
github.com-arbiter       GitHub as arbiter-hd
forgejo-truenas-lan      Forgejo over the home LAN
forgejo-truenas-ts       Forgejo over Tailscale
```

Use `git@github.com-arbiter:arbiter-hd/<repository>.git` for Arbiter remotes and
`git@forgejo-truenas-lan:hd719/<repository>.git` for Forgejo remotes. Verify
from an SSH session opened through `ubuntu-vm`:

```bash
ssh -T github.com
ssh -T github.com-arbiter
ssh -T forgejo-truenas-lan
ssh -T forgejo-truenas-ts
```

The SSH hostname selects the account; the path after `:` selects the repository
owner. Never copy the Arbiter or Forgejo private keys into the VM.

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
