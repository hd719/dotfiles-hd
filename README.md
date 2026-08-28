# dotfiles-hd

Hamel's profile-aware dotfiles, provisioning, and machine operations.

## Choose a Host

| Host | Role | Entry point |
| --- | --- | --- |
| Thin Mac | Control plane for Codex, SSH, Vagrant, and VMware Fusion | [`hosts/mac-thin/README.md`](hosts/mac-thin/README.md) |
| Ubuntu dev | Primary VM development workstation | [`hosts/ubuntu-dev/README.md`](hosts/ubuntu-dev/README.md) |
| Mac Pro | Standalone full-development MacBook; local Brew stack, no VM | [`hosts/mac-pro/README.md`](hosts/mac-pro/README.md) |
| Mac mini | Production runtime host | [`hosts/mac-mini/README.md`](hosts/mac-mini/README.md) |
| Work Mac | Company-scoped terminal and editor setup | [`hosts/mac-work/README.md`](hosts/mac-work/README.md) |

Clone at the canonical path:

```bash
mkdir -p "$HOME/Developer"
git clone git@github.com:hd719/dotfiles-hd.git \
  "$HOME/Developer/dotfiles-hd"
cd "$HOME/Developer/dotfiles-hd"
```

## Repository Structure

```text
dotfiles-hd/
├── AGENTS.md
├── README.md
├── chezmoi/                 profile-aware config delivery and rollback
├── config/                  canonical application configuration
├── hosts/
│   ├── shared/macos/        shared full-Mac provisioning and doctor
│   ├── mac-thin/            control plane, VM lifecycle, and fallback ops
│   ├── ubuntu-dev/          Vagrant guest provisioning and maintenance
│   ├── mac-pro/             standalone development MacBook policy
│   ├── mac-mini/            production runtime Mac policy
│   └── mac-work/resilience/ current work-Mac setup
```

`config/` stays canonical and is not reorganized. Chezmoi delivers only the
approved profile paths from that directory and each host directory. It does
not own secrets, mutable application state, services, VM lifecycle, macOS
preferences, or project repositories.

## Common Commands

Sync reviewed `master` across the three personal hosts:

```bash
hosts/mac-thin/sync-dotfiles.sh
```

Thin Mac and Ubuntu VM:

```bash
hosts/mac-thin/bootstrap.sh --apply
uvm-up
```

Standalone full-development MacBook:

```bash
hosts/shared/macos/bootstrap.sh --profile mac-pro --dry-run
hosts/shared/macos/bootstrap.sh --profile mac-pro --check
hosts/shared/macos/bootstrap.sh --profile mac-pro --apply
```

The `mac-pro` profile installs its complete local package stack through the
shared and profile Brewfiles. Exact language runtimes stay under the
Brew-installed mise version manager. It does not install or manage Vagrant,
VMware Fusion, or an Ubuntu VM.

Existing production Mac mini:

```bash
hosts/shared/macos/bootstrap.sh --profile mac-mini --dry-run
hosts/shared/macos/bootstrap.sh --profile mac-mini --check
```

Apply to the Mac mini only after the reviewed change is merged and its runbook
gates pass.

## Ownership

- `chezmoi/` owns approved user configuration links and timestamped rollback.
- `hosts/mac-thin/` owns control-plane sync and the Vagrant and VMware lifecycle.
- `hosts/ubuntu-dev/` owns guest provisioning and workstation maintenance.
- `hosts/shared/macos/` owns common full-Mac packages and operational setup.
- `hosts/mac-pro/` and `hosts/mac-mini/` own profile package overlays and shell entry points.
- `hosts/mac-work/resilience/` keeps its current scoped linker until a separate work-Mac rollout.

Every production apply requires preview, a timestamped Chezmoi backup, a
no-op second apply, doctor success, and a verified rollback path. Packages are
not removed during rollback.
