# Shared Personal Mac Bootstrap

Shared provisioning for three full local macOS profiles:

| Profile      | Purpose                                                                          |
| ------------ | -------------------------------------------------------------------------------- |
| `mac-pro`    | Standalone full-development MacBook; all development tools local, no VM          |
| `mac-studio` | Staged native development, dormant Ubuntu and Ollama                             |
| `mac-mini`   | Production and explicitly selected secondary development, with extra apply gates |

Do not run this bootstrap on the thin Mac. Use
[`../../mac-thin/README.md`](../../mac-thin/README.md) there.

## Prerequisites

- Apple Silicon macOS
- Xcode Command Line Tools
- Homebrew
- clean canonical clone at `~/Developer/dotfiles-hd`
- machine-owned Git and SSH credentials

## Run

```bash
export PROFILE=mac-pro
hosts/shared/macos/bootstrap.sh --profile "$PROFILE" --dry-run
hosts/shared/macos/bootstrap.sh --profile "$PROFILE" --check
hosts/shared/macos/bootstrap.sh --profile "$PROFILE" --apply
hosts/shared/macos/bootstrap.sh --profile "$PROFILE" --apply
zsh -lic \
  '"$HOME/Developer/dotfiles-hd/hosts/shared/macos/doctor.sh" --profile "'$PROFILE'"'
```

The second apply must create no adjacent operational backups and Chezmoi must
report no drift.

## Ownership

The bootstrap owns:

- shared and profile-specific Brewfiles, installed without broad upgrades
- exact mise versions for Node, pnpm, Go, Python, and Bun
- pinned Ruff, mdformat, and GraphQL LSP tooling
- one marker-owned mise-shims block in `~/.zprofile`
- locked Neovim plugins and required Tree-sitter parsers
- the portable Git alias include, without Git identity or credentials
- profile configuration through Chezmoi

Chezmoi owns only the paths declared in `chezmoi/profiles/PROFILE.paths`. It
preserves Btop, Fastfetch, and mise parent-directory state through the matching
ancestor manifest.

Secrets, auth state, Herdr sessions, Hunk state, tmux plugins, services, Docker
state, databases, and application data remain machine-owned.

Studio and mini overlays include Colima/Docker development tools; Studio also
adds PostgreSQL 17, which mini already retains. Package installation does not
start these services. Studio installs Ollama without activation or model
pulls. The Studio VMware utility installer registers its host helper service;
Rosetta is installed when missing. VMware Fusion setup remains manual; Ubuntu
provider plugin installation is deferred until the preserved guest is
explicitly requested. See the
[Studio runbook](../../mac-studio/README.md) for manual Docker plugin setup,
database ownership and remote acceptance. Air uses its separate client
bootstrap, never the shared full-development bootstrap.

## Rollback

Use the exact Chezmoi rollback command printed by apply. The timestamped backup
restores every managed path and approved ancestor. Restore the adjacent
`~/.zprofile.backup-*` only when rolling back the operational mise-shims block.
Packages and tool caches stay installed.

## Mac mini Gate

For the existing production Mac mini, apply only when:

1. The reviewed change is merged.
1. A canary or equivalent profile QA is green.
1. Post-merge preview and check are green.
1. Hamel approves the production apply.

The bootstrap never restarts Cortana, Hermes, or other production services.
Service lifecycle work requires separate approval.
