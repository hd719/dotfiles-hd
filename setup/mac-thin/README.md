# Thin Mac Control Plane

Supported setup path for Hamel's Apple Silicon MacBook after the 2026 restore.
macOS is a control plane; Ubuntu and Fedora ARM64 VMs own development.

## Boundary

The host installs only:

- Homebrew
- 1Password
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
- Vagrant and the VMware utility
- VLC
- VMware Fusion
- Zoom
- macOS SSH

Do not install project repositories, Docker, databases, compilers, language
runtimes, language servers, Neovim, or project dependencies on macOS.

## Install

Prerequisites are Xcode Command Line Tools, Homebrew, the canonical
`~/Developer/dotfiles-hd` checkout, and restored `~/.ssh`. The bootstrap
installs Rosetta 2 when needed by Vagrant's VMware utility.

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

The bootstrap installs the policy casks and pins the
`vagrant-vmware-desktop` provider to `3.0.5`. It links only the thin `.zshrc`
and tracked Ghostty configuration, backing up any replaced destination beside
the original.

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
1. Build the Ubuntu VM with `uvm-up` and keep VMware Fusion open.
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
u            SSH into the Ubuntu VM
ut           SSH into Ubuntu through Tailscale
uvm-up       Start the Vagrant VM with the VMware GUI
uvm-stop     Gracefully halt the Vagrant VM
uvm-suspend Suspend the Vagrant VM
uvm-resume  Resume the Vagrant VM
uvm-status  Show Vagrant VM state
uvm-ip      Show the Vagrant guest addresses
uvm-destroy Interactively destroy only the Vagrant VM
```

Press `Ctrl-D` to leave the SSH session. `uvm-destroy` never uses Vagrant's
force flag and does not reference the legacy VMware VM.

The Vagrant local route is fixed at `127.0.0.1:2222`, so it works without
Tailscale or local networking. The remote route uses Tailscale MagicDNS.
`setup/mac-thin/ssh/ubuntu-vagrant.conf` keeps host-key checking on and disables
agent forwarding.

The Ubuntu VM generates separate VM-local keys for GitHub `hd719`, Arbiter, and
Forgejo. No Git private key is copied from the Mac.

This is an explicit allowlist. Neovim, Node/Bun/Go, Docker, Kubernetes, project,
VS Code, tmux, and other development aliases remain inside the Linux VMs.

The shell is assembled from scoped modules:

- `config/zsh/shared/` provides portable Git, navigation, SSH, and reload helpers.
- `config/zsh/mac/aliases.zsh` adds safe macOS controls.
- `config/zsh/mac/personal/aliases.zsh` adds vault and Codex controls.
- `setup/mac-thin/vm.zsh` stays host-specific and owns VMware shortcuts.
