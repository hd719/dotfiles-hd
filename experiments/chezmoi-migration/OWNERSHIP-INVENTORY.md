# Chezmoi Ownership Inventory

Status: approved design boundary for disposable prototypes. It does not
authorize changes to a live host.

## Ownership Rules

- Chezmoi owns reviewed, declarative user configuration and profile-scoped
  package manifests.
- Chezmoi may perform first-time user package and tool installation. Existing
  maintenance commands keep recurring updates, cleanup, and health checks.
- Vagrant keeps VM identity, resources, networking, provider state, and
  lifecycle. Ansible keeps Ubuntu system setup.
- Services, launchd jobs, production runtimes, mutable application data,
  credentials, identities, enrollment, and secrets remain outside chezmoi.
- The existing repository `config/` tree remains canonical. Chezmoi owns
  profile-aware symlinks into it and renders files only when a symlink is not
  appropriate.
- A path has one active writer. During the controlled Ubuntu cutover, the old
  linker is not run; the verified apply then activates a host-local marker that
  makes its future link operations no-ops.

## Ubuntu Profile

Chezmoi owns these target paths:

| Target                                 | Source scope                                               |
| -------------------------------------- | ---------------------------------------------------------- |
| `~/.zshrc`                             | Ubuntu shell entrypoint                                    |
| `~/.config/zsh/`                       | Portable aliases and user-environment shell modules        |
| `~/.config/ghostty/config`             | Ghostty configuration                                      |
| `~/.config/starship.toml`              | Starship configuration                                     |
| `~/.gitignore_global`                  | Global ignore rules                                        |
| `~/.ssh/config`                        | SSH client policy only                                     |
| `~/.config/bookokrat/`                 | `config.yaml` and `keybindings.toml` only                  |
| `~/.config/btop/`                      | Configuration and themes; never logs                       |
| `~/.config/fastfetch/`                 | Active configuration and logo assets; never legacy files   |
| `~/.config/herdr/`                     | Client configuration and the existing reset command        |
| `~/.config/hunk/config.toml`           | Hunk configuration                                         |
| `~/.config/mise/config.toml`           | Ubuntu user-tool manifest                                  |
| `~/.config/nvim/`                      | Declarative Neovim configuration and lockfile              |
| `~/.config/tmux/`                      | Configuration and maintained scripts/assets; never plugins |
| `~/.local/bin/codex`                   | Codex launcher wrapper                                     |
| `~/.local/graphql-lsp/bin/graphql-lsp` | GraphQL LSP launcher wrapper                               |

Chezmoi also owns the first installation of the tools declared by the mise
manifest, the pinned mdformat bundle, and the locked Neovim plugins and parsers.
Installed binaries, plugins, caches, and runtime data are not managed files.

The following stay with their current owner:

- **Vagrant:** VM identity, box, disk, CPU, memory, networking, SSH transport,
  provider configuration, and lifecycle commands.
- **Ansible/system:** APT packages and repositories, fonts, users, groups,
  shell, password, sudoers, SSH daemon, authorized keys, services, Tailscale,
  Git-key generation, filesystem growth, and netplan.
- **Maintenance:** `update-system.sh`, user-tool upgrades, locked Neovim
  restore, Herdr binary refresh, and the doctor.
- **Machine:** `~/.gitconfig`, Git identity/auth/signing, SSH keys,
  `authorized_keys`, `known_hosts`, histories, sessions, and mutable state.

Chezmoi may idempotently set only `core.editor`, `core.excludesfile`, and the
portable aliases include in the machine-owned global Git config. It never
renders the full `~/.gitconfig`.

## Thin Mac Profile

Chezmoi owns these target paths:

- `~/.zshrc`
- `~/.config/zsh/` for portable aliases and user-environment shell modules
- `~/.config/bookokrat/` for declarative files only
- `~/Library/Application Support/com.mitchellh.ghostty/config`
- `~/.config/herdr/config.toml`
- `~/.config/hunk/config.toml`
- `~/.config/nvim/` for declarative files and the lockfile
- `~/.config/starship.toml`
- `~/.terminfo/78/xterm-ghostty` as a symlink to Ghostty's bundled terminfo
- the portable Git-alias include, without owning `~/.gitconfig`

Chezmoi owns the thin-Mac Brewfile as a first-install manifest and may perform
the initial `brew bundle`, locked Neovim plugin install, and Markdown parser
install. Homebrew upgrades and cleanup remain maintenance-owned.

Rosetta, the Vagrant VMware provider and service, `vm.zsh`, Ubuntu lifecycle,
ops fallback, doctors, manual applications, sign-ins, permissions, and
Tailscale enrollment remain outside chezmoi. The managed shell entrypoint may
source the existing VM lifecycle module, but chezmoi does not rewrite or absorb
that module.

## Mac Mini Profile

The first live Mac mini cutover is configuration-only. Chezmoi owns:

- `~/.zshrc`
- `~/.config/zsh/` for portable, non-runtime shell modules
- `~/.config/btop/` for configuration and themes only
- `~/.config/fastfetch/` for active configuration and assets only
- `~/.config/bookokrat/` for declarative files only
- `~/Library/Application Support/com.mitchellh.ghostty/config`
- `~/.config/herdr/config.toml`
- `~/.config/hunk/config.toml`
- `~/.config/nvim/` for declarative files and the lockfile
- `~/.config/starship.toml`
- `~/.hermes/skins/hamel-nord.yaml`
- the portable Git-alias include, without owning `~/.gitconfig`

The first live cutover preserves the existing whole-directory Btop and
Fastfetch links in its backup, then transfers their approved children to
chezmoi. The mise link and terminfo remain under their previous owner.

Neither the shared Mac Brewfile nor `setup/mac-mini/Brewfile` transfers in the
first live cutover. The Mac mini manifest mixes user applications with
runtime-sensitive Node, PostgreSQL, pgvector, pnpm, and Tailscale dependencies.
Splitting package ownership requires a separate future decision.

The Mac mini runtime checkout, services, LaunchAgents, databases, agents,
connection state, maintenance runner, `goodMorning`, Herdr lifecycle, and all
runtime shell functions remain outside chezmoi. `~/.zprofile` stays
machine-owned; no prototype may replace it to manage a single block.

## Work Mac Profile

The work Mac remains untouched until every personal host works cleanly and
Hamel explicitly opts in. Its approved maximum scope is:

- `~/.config/bookokrat/` for declarative files only
- `~/Library/Application Support/com.mitchellh.ghostty/config`
- `~/.config/herdr/config.toml`
- `~/.config/hunk/config.toml`
- `~/.config/nvim/` for declarative files and the lockfile
- the portable Git-alias include, without owning `~/.gitconfig`
- the work Brewfile and first-time profile tool install, only after opt-in and
  company-policy review

The live `~/.zshrc`, `~/.config/mise`, work runtimes and repositories,
`goodMorning`, Docker, tmux/Herdr launchers, company applications, device
policy, credentials, certificates, and Git identity remain machine-owned.

## Shared Exclusions

Chezmoi never owns credentials, SSH keys, `.env` files, Git identity/auth,
1Password/GitHub/Codex sessions, `.gog-env`, Tailscale enrollment, certificates,
Docker data, databases, projects, shell history, Herdr sessions, Hunk state,
Neovim data/cache/state/undo, tmux plugins, application databases, logs, or
backup files.

Whole-directory links must contain only approved declarative state. In
particular, do not expose
`config/btop/btop.log`, Bookokrat backups, Fastfetch legacy files, tmux plugins,
or any generated Neovim state.

## Transfer and Rollback

For each path, the prototype must prove this order:

1. Back up the existing target and validate the rollback preview.
1. Review `chezmoi diff`, then apply while the old linker remains idle.
1. Require a second apply to be a no-op.
1. Activate chezmoi ownership so the previous Ubuntu link writers become
   no-ops.
1. Roll back by restoring the backup and the previous ownership-marker state.

Package rollback does not uninstall packages automatically. It stops future
chezmoi install actions and returns recurring ownership to the existing
maintenance command.
