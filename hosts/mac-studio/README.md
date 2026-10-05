# Mac Studio

The Studio becomes the primary native macOS development workstation for every
repository: editors, coding agents, worktrees, builds, tests, Docker workloads
and development databases. It owns the main Obsidian vault and canonical
coding-prompt source after verified cutover.

This is pre-arrival staging for [issue #117](https://github.com/hd719/dotfiles-hd/issues/117).
The M3 Max MacBook Pro remains the current native development host until Studio
and migrated data are verified. Keep it through migration and remote-access
acceptance before deciding on erase or trade-in.

## Target Roles

| Host           | Role after cutover                                                                     |
| -------------- | -------------------------------------------------------------------------------------- |
| Studio         | Primary native development, main personal workstation and local AI                     |
| Mac mini       | Hermes/Cortana Services production; isolated development only when explicitly selected |
| Optional Air   | Lightweight clients; SSH and Screen Sharing into Studio if needed                      |
| Current M3 Max | Migration source and temporary remote-access test client                               |

Studio uses the personal Apple Account. Mini retains its dedicated Apple
Account. Remote Login, Screen Sharing, Tailscale enrollment, hostnames, SSH keys,
authentication, databases and Ollama models are machine-owned.

Ubuntu development support was retired in [PR #134](https://github.com/hd719/dotfiles-hd/pull/134).
This profile has no Vagrant, VMware, guest helpers, Ubuntu SSH routes or Rosetta
requirement. Any preserved VM/data remains a separate archive; Studio readiness
requires neither moving nor starting it. Archive deletion/restoration is a
separate decision.

## On Arrival

Install Xcode Command Line Tools and Homebrew. Clone reviewed `master` at
`~/Developer/dotfiles-hd`, authenticate locally, then preview and audit:

```bash
hosts/shared/macos/bootstrap.sh --profile mac-studio --dry-run
hosts/shared/macos/bootstrap.sh --profile mac-studio --check
```

After hardware arrival and approval of the reviewed checks:

```bash
DOTFILES_MAC_STUDIO_ARRIVED=1 \
  hosts/shared/macos/bootstrap.sh --profile mac-studio --apply
DOTFILES_MAC_STUDIO_ARRIVED=1 \
  hosts/shared/macos/bootstrap.sh --profile mac-studio --apply
hosts/shared/macos/doctor.sh --profile mac-studio
```

The arrival flag is required by both bootstrap and direct Chezmoi apply; set it
only on Studio. Bootstrap installs native development tools and the Studio
Brewfile/configuration. Verify the printed backup and rollback path, no-op
second configuration apply and successful doctor before continuing migration.
Workload services and Ollama models are configured separately.

## Native Development

Homebrew and the shared mise configuration provide the native toolchain.
Studio's overlay adds .NET 9, Colima, Docker, Compose, Buildx, PostgreSQL 17,
pgvector, VS Code and Chromium, plus coreutils, FFmpeg, Git filter-repo, Poppler,
Tesseract, Websocat and XcodeGen. Existing runtime pins stay unchanged. Homebrew
resolves supporting libraries as dependencies.

Colima's VM supplies the Docker engine; repository tools and builds run natively
on Studio. Start Colima deliberately after installation. Merge
`/opt/homebrew/lib/docker/cli-plugins` into the machine-owned
`cliPluginsExtraDirs` array in `~/.docker/config.json`, preserving authentication
and other settings. Verify `docker compose version`, `docker buildx version`
and `docker info` after starting Colima.

The Studio shell exposes PostgreSQL 17 client tools and the .NET 9 SDK.
`DOTNET_ROOT` points to the Homebrew .NET 9 installation. Homebrew creates the
initial PostgreSQL cluster during package installation; database creation,
restores and server startup are deliberate project steps. Verify representative
native builds/tests, including Cortana Services development. Keep the mini's
production credentials, databases and mutable production data on the mini.

Use `arbiter-hd` for Studio agent GitHub work, verify the actor before writes,
and retain current-head `hd719` approval requirements before merging agent PRs.
Deploy to the mini through its existing reviewed process. Mini development
requires explicit selection and separate checkouts/worktrees, test databases
and ports; retain its production checkout on clean `main`.

## Migration and Remote Acceptance

Before retiring the M3 Max:

1. Inventory and back up repositories, uncommitted work, unpushed branches,
   development databases and required local data.
1. Move work and required development data from native MacBook workspaces into
   native Studio workspaces. Authenticate Studio tools locally and verify the
   migrated data against the inventory.
1. Back up Codex using the existing quit, full-directory copy and parity-check
   procedure in `AGENTS.md`; retain two independent copies before migration.
1. Verify representative repository builds/tests, Docker and development
   database access on Studio.
1. Move the main vault/canonical prompt source through a verified cutover.
   Update canonical `machine-topology`, `dotfiles-sync`, `personal-ready` and
   `sync-coding-prompts` at that point using their normal sync workflow.
1. Test Studio SSH and Screen Sharing from the M3 Max, including away-from-home
   Tailscale access, sleep/reconnection and restart/recovery access.
1. Verify Studio access to the mini and home-lab workflows. Keep Hermes/Cortana
   Services production on the mini and pass its readiness checks.
1. Record accepted hostnames, routes, canonical paths, backups and rollback
   steps without secrets. Obtain separate approval before MacBook erase/trade-in.

## Optional Air

Use Studio first, then decide whether a dedicated thin client is useful.
Studio completion does not depend on buying or receiving an Air. Test remote
access from the current MacBook during the overlap.

If chosen, use the existing [`mac-air` profile](../mac-air/README.md), configure
its Studio route after arrival and verify terminal/desktop access away from
home. Development execution stays on Studio; Air retains its existing local
note tools and remote clients. Add it to client sync/readiness workflows only
after acceptance.
