# Future MacBook Air

`mac-air` is the future lightweight access machine for Studio. It uses the
thin Mac's apps, fonts and local note tools, including Codex, Ghostty,
browsers, Obsidian, Herdr, Hunk, Bookokrat, Fastfetch and Neovim. Repository
development, coding agents, builds, tests, containers and development
databases execute on Studio.
The `chatgpt` Homebrew cask supplies the current Codex desktop app bundle.

This profile is separate from the current M3 Max's VMware-owning `mac-thin`
profile. Its Brewfile matches that profile except for Vagrant and the VMware
utility, and adds the Codex desktop app. VMware Fusion, Rosetta/provider setup
and VM lifecycle helpers are excluded. Project runtimes, Docker and database
servers remain on Studio. Studio rollout does not wait for the Air to arrive.

## Setup After Arrival

Install Homebrew and its command-line prerequisites, authenticate locally and
clone reviewed `master` at `~/Developer/dotfiles-hd`. Use the personal Apple
Account. Review the client package/configuration plan:

```bash
hosts/mac-air/bootstrap.sh --dry-run
hosts/mac-air/bootstrap.sh --check
```

After the Air arrives and the preview is approved:

```bash
DOTFILES_MAC_AIR_ARRIVED=1 hosts/mac-air/bootstrap.sh --apply
hosts/mac-air/doctor.sh
```

The arrival gate also protects direct Chezmoi apply. Chezmoi installs the Air
Brewfile, restores the locked thin Neovim plugins and builds only the two
Markdown parsers. The profile owns the shell, lightweight Ghostty config and
shared note/client configuration listed in `chezmoi/profiles/mac-air.paths`.
Use the timestamped Chezmoi rollback printed by apply. Packages, credentials
and mutable application data remain machine-owned.

## Local Notes and Clients

Neovim uses `DOTFILES_NVIM_PROFILE=thin` for Markdown and Obsidian notes;
Marksman is its only language server and is toggled per file with `Space m m`.
Tree-sitter CLI exists to build the Markdown parsers. Use `v` for Neovim,
`hdiff` for Hunk, and the usual thin-Mac navigation and Codex shortcuts.
The editor stays lightweight while project builds, tests and dependencies
live on Studio.

Herdr uses the shared client configuration. Connect with `herdr --remote`
followed by the verified Studio SSH alias; remote aliases and credentials are
configured after arrival. The Air shell does not inherit Ubuntu shortcuts or
start Herdr/remote sessions automatically. Hermes Desktop can be added as a
remote mini client using the [thin runbook's manual app procedure](../mac-thin/README.md#manual-applications).

## Remote Acceptance

- Enroll Air in Tailscale with fresh machine-local authentication.
- Configure Studio as the remote Codex/terminal execution destination. Use
  the verified Studio hostname and username; do not reuse the Ubuntu target.
- Test SSH and Screen Sharing over private Tailscale access from away from home.
  Verify remote command execution with `hostname` before running project work.
- Verify Studio restart/reconnection and recovery access. Air's doctor checks
  local clients only; it does not connect to or start a remote machine.
- Configure Obsidian synchronization for local reading/editing while keeping
  Studio the canonical coding-prompt source. Add Air to applicable sync/readiness
  workflows only after these checks pass.
