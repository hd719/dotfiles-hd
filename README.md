# dotfiles-hd

Personal systems repository for Hamel's Macs and Linux workstations.

Start here when choosing the right setup path. Automation rules live in
[`AGENTS.md`](AGENTS.md).

## Start Here

Clone once at the canonical path:

GitHub SSH access is required because automated updates verify the exact
canonical remote.

```bash
mkdir -p "$HOME/Developer"
git clone git@github.com:hd719/dotfiles-hd.git \
  "$HOME/Developer/dotfiles-hd"
cd "$HOME/Developer/dotfiles-hd"
```

If you are on a Mac, choose the Mac profile first:

| Mac                                 | Use this                                              | Runbook                                                                    |
| ----------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------- |
| Thin personal MacBook control plane | `setup/mac-thin/bootstrap.sh`                         | [`setup/mac-thin/README.md`](setup/mac-thin/README.md)                     |
| Full personal MacBook               | `setup/mac-bootstrap/bootstrap.sh --profile mac-pro`  | [`setup/mac-bootstrap/README.md`](setup/mac-bootstrap/README.md)           |
| Personal Mac mini                   | `setup/mac-bootstrap/bootstrap.sh --profile mac-mini` | [`setup/mac-bootstrap/README.md`](setup/mac-bootstrap/README.md)           |
| Resilience work Mac                 | `setup/mac-pro-resilience`                            | [`setup/mac-pro-resilience/README.md`](setup/mac-pro-resilience/README.md) |

If you are on Linux, choose the distro path:

| Linux              | Use this       | Runbook                                            |
| ------------------ | -------------- | -------------------------------------------------- |
| Ubuntu workstation | `setup/ubuntu` | [`setup/ubuntu/README.md`](setup/ubuntu/README.md) |

Future Linux distributions should get their own `setup/<distro>/` runbook
instead of expanding the Ubuntu path.

For Mac-to-Linux learning, use the
[Ubuntu Field Guide](setup/ubuntu/GUIDE.md).

## Common Paths

After a reviewed change is merged, sync canonical `master` from the thin Mac:

```bash
scripts/sync-dotfiles.sh
```

The helper checks all three canonical repos before the first pull and stops if
any worktree is dirty. A clean non-`master` branch is returned to `master` only
when its exact `HEAD` is already merged into current `origin/master`.

Thin Mac plus Ubuntu VM:

```bash
setup/mac-thin/bootstrap.sh --apply
uvm-up
```

Vagrant creates the VMware ARM64 guest and runs guest-local Ansible, mise,
dotfile linking, and the offline doctor. Register the three generated Git
public keys, sign in to Codex, then run the full doctor inside Ubuntu.

For Codex remote development, connect Ubuntu to Tailscale as `ubuntu-dev` and
add the Mac SSH alias `ubuntu-vm-ts`. Keep `ubuntu-vm` as the local fallback.
The Ubuntu setup pins Codex CLI through mise; run `codex login --device-auth`
once inside Ubuntu before enabling the connection in Codex desktop.

Thin Mac only:

```bash
setup/mac-thin/bootstrap.sh --dry-run
setup/mac-thin/bootstrap.sh --check
setup/mac-thin/bootstrap.sh --apply
setup/mac-thin/doctor.sh
```

Development repositories, Docker, databases, project compilers, language
runtimes, project dependencies, and language servers other than the thin
profile's Marksman stay inside the Linux VMs. The local Tree-sitter CLI builds
only Neovim's two Markdown parsers. Thin Neovim is for local configuration and
Obsidian notes, not project development.

Full personal Mac:

```bash
setup/mac-bootstrap/bootstrap.sh --profile mac-pro --dry-run
setup/mac-bootstrap/bootstrap.sh --profile mac-pro --check
setup/mac-bootstrap/bootstrap.sh --profile mac-pro --apply
zsh -lic \
  '"$HOME/Developer/dotfiles-hd/setup/mac-bootstrap/doctor.sh" --profile mac-pro'
exec zsh -l
```

Use `mac-mini` for a new Mac mini. The existing production Mac mini requires
the approval gate in the Mac bootstrap runbook before `--apply`.

## System Boundaries

- Thin Macs are control planes for browsers, Codex, Obsidian, thin-profile
  Neovim, SSH, the Herdr remote client, Vagrant, and VMware Fusion.
- Ubuntu VMs own project repositories, Docker, databases, compilers, language
  runtimes, full-profile Neovim, project language servers, and dependencies.
- Full personal Macs own their local development toolchain.
- The production Mac mini has extra approval gates before bootstrap changes.
- The Resilience work Mac is scoped to terminal and editor repair only.
- Every shell profile uses Hunk through `hdiff`; no profile owns a Git pager.

## Repository Map

- `config/` contains portable application and tool configuration, not package
  inventories.
- `setup/` contains platform installers, machine overlays, tests, and runbooks.
- Each Mac profile declares its package policy in its own `setup/*/Brewfile`.
- Each profile owns its `.zshrc`, plugin timing, runtimes, credentials, and
  host-specific behavior.
- Zsh modules are shared where safe and profile-owned where machine behavior
  differs.

See [`config/nvim/README.md`](config/nvim/README.md) for the editor contract.
