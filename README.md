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
| Ubuntu workstation              | `bash setup/ubuntu/setup.sh`  | [`setup/ubuntu/README.md`](setup/ubuntu/README.md)                         |

Scripts under `setup/fedora` are legacy helpers, not a supported one-command
bootstrap.

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

## Full Personal Mac Link Inventory

The personal Mac bootstrap owns every row below except the explicitly manual
AeroSpace link. It backs up non-matching destinations and leaves other state
alone.

| Tool       | Live path                                                    | Source                                            | Scope                          |
| ---------- | ------------------------------------------------------------ | ------------------------------------------------- | ------------------------------ |
| Shell      | `~/.zshrc`                                                   | `setup/mac-pro/.zshrc` or `setup/mac-mini/.zshrc` | Profile-specific               |
| Login PATH | Managed block in `~/.zprofile`                               | `setup/mac-bootstrap/mise-shims.zsh`              | Preserves the rest of the file |
| Bookokrat  | `~/.config/bookokrat`                                        | `config/bookokrat`                                | Shared                         |
| btop       | `~/.config/btop`                                             | `config/btop`                                     | Shared                         |
| fastfetch  | `~/.config/fastfetch`                                        | `config/fastfetch`                                | Shared                         |
| Ghostty    | `~/Library/Application Support/com.mitchellh.ghostty/config` | `config/ghostty/config`                           | Shared                         |
| Herdr      | `~/.config/herdr/config.toml`                                | `config/herdr/config.toml`                        | Config only                    |
| Hunk       | `~/.config/hunk/config.toml`                                 | `config/hunk/config.toml`                         | Config only                    |
| Karabiner  | `~/.config/karabiner`                                        | `config/karabiner`                                | MacBook only                   |
| mise       | `~/.config/mise`                                             | `config/mise`                                     | Shared                         |
| Neovim     | `~/.config/nvim`                                             | `config/nvim`                                     | Shared                         |
| AeroSpace  | `~/.config/aerospace/aerospace.toml`                         | `config/aerospace/aerospace.toml`                 | Existing manual link           |

Use the profile bootstrap or work-Mac linker to repair links. Do not recreate
them by hand unless the matching runbook explicitly says to.

## Safety Boundaries

Never copy or link credentials, authentication state, certificates, application
databases, or company-managed state. In particular:

- Keep `~/.gitconfig` machine-owned.
- Keep tmux plugins inside the live `~/.config/tmux`; review `tmux.conf`
  separately.
- Link only `config.toml` for Herdr and Hunk. Their runtime directories stay
  local.
- Treat Raycast exports as backups, not live configuration.
- Do not link `~/.config/1Password`, `~/.config/op`, `~/.config/gh`, or
  `~/.config/cagent`.
- Do not link Zed prompts or `~/Library/Application Support/Zed`; both contain
  runtime state.
- Link terminal configuration only on profiles that actively use that terminal.

The Mac bootstrap never restores credentials, removes packages, cleans
Homebrew, or starts and restarts services.

See [`config/nvim/README.md`](config/nvim/README.md) for the editor contract and
[`AGENTS.md`](AGENTS.md) for automation rules.
