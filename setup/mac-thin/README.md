# Thin Mac Control Plane

Supported setup path for Hamel's Apple Silicon MacBook after the 2026 restore.
macOS is a control plane; Ubuntu and Fedora ARM64 VMs own development.

## Boundary

The host installs only:

- Homebrew
- 1Password
- Bartender
- Brave and Google Chrome
- ChatGPT/Codex
- DaisyDisk
- diff-so-fancy for readable local Git diffs
- Ghostty
- Ghostty fonts
- iStat Menus
- Mullvad VPN
- noTunes
- Obsidian
- Pearcleaner
- Raycast
- TablePlus
- Tailscale
- VLC
- VMware Fusion
- Zoom
- macOS SSH

Do not install project repositories, Docker, databases, compilers, language
runtimes, language servers, Neovim, or project dependencies on macOS.

## Install

Prerequisites are Xcode Command Line Tools, Homebrew, the canonical
`~/Developer/dotfiles-hd` checkout, and restored `~/.ssh`.

Preview and audit first:

```bash
setup/mac-thin/bootstrap.sh --dry-run
setup/mac-thin/bootstrap.sh --check
```

Apply from a clean canonical checkout, then repeat to prove idempotency:

```bash
setup/mac-thin/bootstrap.sh --apply
setup/mac-thin/bootstrap.sh --apply
setup/mac-thin/doctor.sh
```

The bootstrap installs the policy casks in `Brewfile` through Homebrew. It links
only the thin `.zshrc` and tracked Ghostty configuration, backing up any
replaced destination beside the original.

## Manual Applications

- ChatGPT is the supported Codex desktop app. Install it from
  <https://chatgpt.com/download/> when it is not already present.
- VMware Fusion is not available as a current Homebrew cask. Download it
  through Broadcom's official flow:
  <https://knowledge.broadcom.com/external/article/315638/download-and-install-vmware-fusion.html>.

The doctor remains red until both applications exist in `/Applications`.

## First Run

1. Sign in to 1Password, Tailscale, Obsidian, and ChatGPT.
1. Grant Tailscale's requested network-extension permission.
1. Complete VMware Fusion's one-time privileged setup.
1. Add `ubuntu-vm-ts` to Codex connections as the primary development route.
   Keep `ubuntu-vm` as the local VMware fallback.
1. Keep repositories and all development execution on the guests' native Linux
   filesystems.

The bootstrap never restores credentials, starts services, removes packages,
or installs development tooling.

## Personal Shell Allowlist

Start a fresh shell after bootstrap, then use:

```text
g, gs        Git and Git status
gdiff        Git diff
gpull        Pull the current repository
gpush        Push the current repository
cod          Codex CLI
codr, codrl  Resume a Codex session
dots         Enter the Mac dotfiles repository
vault        Enter the Obsidian vault repository
hosts        List configured SSH hosts
r            Reload the Zsh configuration
u, ubuntu   SSH into the Ubuntu VM
ut, ubuntu-ts
             SSH into Ubuntu through Tailscale
uvm-status  Show whether the Ubuntu VM is running
uvm-ip      Show the current VMware guest IP
uvm-open    Open VMware Fusion
```

Press `Ctrl-D` to leave the SSH session. VM shutdown remains an explicit VMware
action to avoid accidental power-offs.

Keep `AddressFamily inet` in both Ubuntu SSH blocks. `ubuntu-vm` uses VMware
mDNS for the local route; `ubuntu-vm-ts` uses Ubuntu's stable Tailscale address.
VMware mDNS can publish the guest on multiple IPv6 link-local interfaces,
making SSH choose the wrong route intermittently.

Arbiter GitHub and Forgejo access use agent forwarding from the thin Mac.
Private keys remain in `~/.ssh` on macOS; Ubuntu stores only their public keys
as identity selectors. The `ubuntu-vm` block must set `ForwardAgent yes` and
use `LocalCommand` with `ssh-add` so a fresh Mac agent loads
`id_ed25519_arbiter_hd` and `id_ed25519_forgejo_truenas` before the Ubuntu
shell starts.

This is an explicit allowlist. Neovim, Node/Bun/Go, Docker, Kubernetes, project,
VS Code, tmux, and other development aliases remain inside the Linux VMs.

The shell is assembled from scoped modules:

- `config/zsh/shared/` provides portable Git, navigation, SSH, and reload helpers.
- `config/zsh/mac/aliases.zsh` adds safe macOS controls.
- `config/zsh/mac/personal/aliases.zsh` adds vault and Codex controls.
- `setup/mac-thin/vm.zsh` stays host-specific and owns VMware shortcuts.
