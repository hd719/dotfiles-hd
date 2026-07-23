# Personal Mac Bootstrap

Supported setup path for Apple Silicon personal Macs.

| Profile    | Target            |
| ---------- | ----------------- |
| `mac-pro`  | Personal MacBook  |
| `mac-mini` | Personal Mac mini |

The bootstrap installs the reviewed toolchain, creates backed-up links, manages
one marked `~/.zprofile` block, restores Neovim, and runs the doctor. It never
restores credentials, removes packages, cleans Homebrew, or starts and restarts
services.

## Prerequisites

1. Install Xcode Command Line Tools:

   ```bash
   xcode-select --install
   ```

1. Install Homebrew from <https://brew.sh> and complete its printed shell setup.

1. Configure GitHub SSH access. Credentials remain machine-owned.

1. Clone the repository at the required path:

   ```bash
   mkdir -p "$HOME/Developer"
   git clone git@github.com:hd719/dotfiles-hd.git \
     "$HOME/Developer/dotfiles-hd"
   cd "$HOME/Developer/dotfiles-hd"
   ```

`--apply` requires this canonical path and a clean worktree.

## Install a Personal Mac

Set the profile once:

```bash
export PROFILE=mac-pro
```

Preview without package-manager calls or writes:

```bash
setup/mac-bootstrap/bootstrap.sh --profile "$PROFILE" --dry-run
```

Audit packages and planned filesystem changes:

```bash
setup/mac-bootstrap/bootstrap.sh --profile "$PROFILE" --check
```

`--check` may return nonzero while dependencies are missing. Tools may refresh
their own caches, but managed links are not changed.

Apply, then repeat the apply to prove idempotency:

```bash
setup/mac-bootstrap/bootstrap.sh --profile "$PROFILE" --apply
setup/mac-bootstrap/bootstrap.sh --profile "$PROFILE" --apply
```

The second run must create no new backups and change no correct link. Verify in
a fresh login shell, then replace the current shell:

```bash
zsh -lic \
  '"$HOME/Developer/dotfiles-hd/setup/mac-bootstrap/doctor.sh" --profile "$PROFILE"'
exec zsh -l
```

Open Ghostty, Herdr, Hunk, Neovim, and Bookokrat once. On the MacBook, complete
Karabiner's required driver and Input Monitoring prompts. Application sign-ins
and credentials remain manual. Open one PDF in Bookokrat and confirm Hamel Nord,
search, navigation, zoom, and the opaque document canvas.

## Existing Production Mac mini

Do not run `--apply` until all four gates pass:

1. The reviewed change is merged.
1. The MacBook rollback and reboot canary is green.
1. The post-merge Mac mini preflight is green.
1. Hamel explicitly approves the interactive apply.

The bootstrap does not edit or reload Cortana or Hermes services. Their running
processes remain on the production-owned keg-only Homebrew Node 22 contract.
Stale LaunchAgent paths, service restarts, and runtime migrations require a
separate approved maintenance window with runtime status and doctor checks.

Never remove the Mac mini's Homebrew Node or pnpm fallback during bootstrap.
See [`docs/QA.md`](docs/QA.md) for the full gate.

## What `--apply` Owns

- Shared Brewfile plus the selected profile overlay, installed without broad
  upgrades or cleanup.
- The reviewed links listed in the root [`README.md`](../../README.md).
- One marker-owned mise-shims block in `~/.zprofile`; all other content remains
  user-owned.
- Exact mise versions for Node, pnpm, Go, Python, and Bun.
- Pinned Ruff, mdformat, and GraphQL LSP tooling.
- Locked Neovim plugins and required Tree-sitter parsers without rewriting
  `lazy-lock.json`. Restore includes vault-gated plugins; normal startup remains
  conditional.
- A final doctor run.

Herdr sessions, Hunk state, tmux plugins, credentials, auth state, services,
Docker state, and application databases remain outside bootstrap ownership.

## Roll Back

Backups sit beside their original paths as
`path.backup-YYYYMMDD-HHMMSS`.

1. Close affected applications and shells.
1. Move each new symlink aside and restore its matching backup.
1. Move a new symlink aside when its destination was originally absent.
1. Restore the previous `~/.zprofile`; if none existed, move the
   bootstrap-created file aside. Preserve all user-owned content outside the
   marked block.
1. Start a fresh login shell and rerun the baseline and doctor checks from
   [`docs/QA.md`](docs/QA.md).

Rollback leaves installed packages, runtimes, and tool caches in place.
Uninstall and cleanup are separate, explicitly approved work.
