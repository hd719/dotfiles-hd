# Production Mac Mini

`mac-mini` is the production runtime profile. It shares the full personal-Mac
toolchain but has stricter preview, backup, apply, and service-safety gates.

## Run

Follow the [shared macOS bootstrap](../shared/macos/README.md):

```bash
hosts/shared/macos/bootstrap.sh --profile mac-mini --dry-run
hosts/shared/macos/bootstrap.sh --profile mac-mini --check
hosts/shared/macos/bootstrap.sh --profile mac-mini --apply
hosts/shared/macos/doctor.sh --profile mac-mini
```

Packages come from `hosts/shared/macos/Brewfile` and
`hosts/mac-mini/Brewfile`. The shared Brewfile owns `marksman`; a post-merge
bootstrap apply repairs the current missing binary before the final doctor.

Chezmoi owns only `chezmoi/profiles/mac-mini.paths`. It safely migrates and
restores Btop, Fastfetch, and mise parent-link shapes through
`mac-mini.ancestors`.

The bootstrap does not restart, reload, or migrate Cortana, Hermes, Homebrew
services, LaunchAgents, or other production processes. Runtime changes require
a separate maintenance window. Use the exact timestamped Chezmoi backup printed
by apply for configuration rollback.

## Secondary Development

After verified Studio cutover, Studio is the default development host. Until
then, current topology rules apply. Select the mini explicitly when its
secondary development environment is needed. The shared profile already
provides native mise runtimes and editor/agent tools; its overlay also provides
PostgreSQL 17, pgvector and Colima/Docker/Compose/Buildx. Review missing packages
through the normal guarded apply; installation never starts services.

Keep `/Users/h/Developer/cortana-services` clean on `main` for production.
Create development clones or worktrees under `~/Developer/worktrees/`, with
separate environment files, test databases, data directories and ports. Follow
each project's runtime runbook for the actual port allocation; never develop
against production credentials or mutable production data. Preserve the
production Homebrew Node 22 prefix independently of mise development Node.

Use `cortana-hd` for explicitly selected mini agent GitHub work and verify the
actor before writes. Deploy reviewed work through the existing approval and
runtime-verification process. Development does not authorize service reloads.
For Docker plugin discovery and manual runtime activation, follow the
[Studio development setup](../mac-studio/README.md#native-development), using
a separately named Colima development profile on the mini.
