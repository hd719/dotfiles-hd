# Thin Mac Control Plane

Supported setup path for Hamel's Apple Silicon MacBook after the 2026 restore.
macOS is a control plane; Ubuntu and Fedora ARM64 VMs own development.

## Boundary

The host installs only:

- Homebrew
- 1Password
- ChatGPT/Codex
- Ghostty
- Obsidian
- Tailscale
- VMware Fusion
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

The bootstrap installs 1Password, Ghostty, Obsidian, and Tailscale through
Homebrew. It links only the thin `.zshrc` and tracked Ghostty configuration,
backing up any replaced destination beside the original.

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
1. Add the Ubuntu and Fedora SSH aliases to Codex connections.
1. Keep repositories and all development execution on the guests' native Linux
   filesystems.

The bootstrap never restores credentials, starts services, removes packages,
or installs development tooling.
