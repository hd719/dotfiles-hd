# Future MacBook Air

`mac-air` is the future lightweight access machine for Studio. It runs Codex,
Ghostty, a browser and Obsidian locally. Repository development, coding agents,
builds, tests, containers and development databases execute on Studio.
The `chatgpt` Homebrew cask supplies the current Codex desktop app bundle.

This profile is separate from the current M3 Max's VMware-owning `mac-thin`
profile. It installs no VMware, Vagrant, editor toolchains, project runtimes,
Docker or database server. Studio rollout does not wait for the Air to arrive.

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

The arrival gate also protects direct Chezmoi apply. The profile owns only the
shell, prompt, lightweight Ghostty configuration and Brewfile link listed in
`chezmoi/profiles/mac-air.paths`. Use the timestamped Chezmoi rollback printed
by apply. Packages, credentials and application data remain machine-owned.

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
