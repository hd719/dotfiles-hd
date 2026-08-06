# Standalone Development MacBook

`mac-pro` is the full local-development MacBook profile. It installs the whole
local package stack through Homebrew. Exact language runtimes use mise, which
Homebrew installs. It does not use or manage an Ubuntu VM, Vagrant, or VMware
Fusion.

## Install

Follow the [shared macOS bootstrap](../shared/macos/README.md):

```bash
hosts/shared/macos/bootstrap.sh --profile mac-pro --dry-run
hosts/shared/macos/bootstrap.sh --profile mac-pro --check
hosts/shared/macos/bootstrap.sh --profile mac-pro --apply
hosts/shared/macos/bootstrap.sh --profile mac-pro --apply
hosts/shared/macos/doctor.sh --profile mac-pro
```

Packages come from:

- `hosts/shared/macos/Brewfile` for the common full-Mac toolchain
- `hosts/mac-pro/Brewfile` for the standalone MacBook overlay

Chezmoi applies `chezmoi/profiles/mac-pro.paths`, including the MacBook shell,
shared application configuration, full Neovim configuration, mise, and
Karabiner. Git identity, credentials, secrets, services, Docker data, and
application state remain machine-owned.

Use the timestamped Chezmoi backup printed during apply for configuration
rollback. Package removal is never part of rollback.
