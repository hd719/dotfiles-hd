# dotfiles-hd

Source of truth for Hamel's supported personal, work, and VM setups.

## Choose a Profile

Clone once at the canonical path:

GitHub SSH access is required because automated updates verify the exact
canonical remote.

```bash
mkdir -p "$HOME/Developer"
git clone git@github.com:hd719/dotfiles-hd.git \
  "$HOME/Developer/dotfiles-hd"
cd "$HOME/Developer/dotfiles-hd"
```

| Device                          | Profile or command            | Runbook                                                                    |
| ------------------------------- | ----------------------------- | -------------------------------------------------------------------------- |
| Thin personal Apple Silicon Mac | `setup/mac-thin/bootstrap.sh` | [`setup/mac-thin/README.md`](setup/mac-thin/README.md)                     |
| Personal Apple Silicon MacBook  | `--profile mac-pro`           | [`setup/mac-bootstrap/README.md`](setup/mac-bootstrap/README.md)           |
| Personal Apple Silicon Mac mini | `--profile mac-mini`          | [`setup/mac-bootstrap/README.md`](setup/mac-bootstrap/README.md)           |
| Resilience work Mac             | `setup/mac-pro-resilience`    | [`setup/mac-pro-resilience/README.md`](setup/mac-pro-resilience/README.md) |
| Ubuntu workstation              | `uvm-up`                      | [`setup/ubuntu/README.md`](setup/ubuntu/README.md)                         |

Scripts under `setup/fedora` are legacy helpers, not a supported one-command
bootstrap.

For Mac-to-Linux learning, use the
[Ubuntu Field Guide](setup/ubuntu/GUIDE.md).

## Ubuntu Quick Start

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

## Thin Mac Quick Start

For the restored MacBook control plane:

```bash
setup/mac-thin/bootstrap.sh --dry-run
setup/mac-thin/bootstrap.sh --check
setup/mac-thin/bootstrap.sh --apply
setup/mac-thin/doctor.sh
```

Development repositories, Docker, databases, compilers, language runtimes,
language servers, Neovim, and project dependencies stay inside the Linux VMs.

## Full Personal Mac Quick Start

Install Xcode Command Line Tools and Homebrew first, then run:

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

## Repository Layout

- `config/` contains portable application and tool configuration.
- `setup/` contains platform installers, machine overlays, tests, and runbooks.
- Each Mac profile owns its `.zshrc`, plugin timing, runtimes, credentials, and
  machine-specific behavior.

### Zsh Architecture

Shell modules are grouped by who loads them:

```text
config/zsh/
├── shared/
│   ├── aliases.zsh
│   ├── completions.zsh
│   ├── development-aliases.zsh
│   └── functions.zsh
└── mac/
    ├── aliases.zsh
    ├── development-aliases.zsh
    ├── development-functions.zsh
    ├── init.zsh
    ├── k8s.zsh
    ├── prompt.zsh
    ├── tooling.zsh
    └── personal/
        ├── aliases.zsh
        ├── development-aliases.zsh
        ├── development-functions.zsh
        └── init.zsh
```

- `shared/` is portable and safe for macOS, Ubuntu, and Fedora.
- `shared/development-aliases.zsh` is loaded by Ubuntu and full Mac development
  profiles, but not by the thin Mac.
- `mac/aliases.zsh` is safe on every Mac, including the thin control plane.
- `mac/init.zsh` adds the complete Mac development shell.
- `mac/personal/aliases.zsh` contains safe personal host controls.
- `mac/personal/init.zsh` adds personal development workflows.
- Ubuntu's `.zshrc` owns Linux plugin timing, readable autosuggestions, and a
  Git pager that falls back to plain `less` when `diff-so-fancy` is unavailable.

The thin Mac sources only the shared, safe Mac, safe personal, and VMware
modules. Full personal Macs source both `mac/init.zsh` and
`mac/personal/init.zsh`. Resilience sources only `mac/init.zsh`.

#### Decision Record

On 2026-07-24, shell modules were organized by consumer:

- Keep portable behavior in `shared/`.
- Keep reusable macOS behavior in `mac/`.
- Keep Linux profile behavior in `setup/ubuntu/` and `setup/fedora/`.
- Add `config/zsh/linux/` only when multiple Linux profiles share Linux-only
  modules.
- Keep the thin Mac limited to safe host modules; development remains in VMs.

## Thin Mac Link Inventory

The thin profile owns only these two links:

| Tool    | Live path                                                    | Source                  |
| ------- | ------------------------------------------------------------ | ----------------------- |
| Shell   | `~/.zshrc`                                                   | `setup/mac-thin/.zshrc` |
| Ghostty | `~/Library/Application Support/com.mitchellh.ghostty/config` | `config/ghostty/config` |

See [`config/nvim/README.md`](config/nvim/README.md) for the editor contract and
[`AGENTS.md`](AGENTS.md) for automation rules.
