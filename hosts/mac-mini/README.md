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
