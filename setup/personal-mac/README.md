# Personal Mac Bootstrap

This is the supported setup path for an Apple Silicon personal Mac. It covers
the shell, Ghostty, Zed, Herdr, Neovim, shared configuration, and pinned
development runtimes.

It does not restore credentials, SSH keys, application databases, Docker
state, or the Mac mini's Cortana/Hermes production runtime.

## Brand-new Mac

First install Apple's Command Line Tools:

```bash
xcode-select --install
```

Wait for that installer to finish, then use Homebrew's official installer from
<https://brew.sh>. Complete the installer's printed **Next steps** before
continuing. On an Apple Silicon Mac, those steps normally include:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew --version
```

Clone the repository at its canonical path:

```bash
mkdir -p "$HOME/Developer"
git clone https://github.com/hd719/dotfiles-hd.git \
  "$HOME/Developer/dotfiles-hd"
cd "$HOME/Developer/dotfiles-hd"
```

The legacy `mac-vm` name means the personal MacBook profile; it is correct for
a new physical MacBook too. Preview it first. Dry-run invokes no package
manager and writes nothing:

```bash
setup/personal-mac/bootstrap.sh --profile mac-vm --dry-run
```

Then audit installed dependencies. This can return nonzero while packages are
missing; Homebrew or mise may populate their own caches during the audit.

```bash
setup/personal-mac/bootstrap.sh --profile mac-vm --check
```

Apply only from a clean checkout:

```bash
setup/personal-mac/bootstrap.sh --profile mac-vm --apply
exec zsh -l
setup/personal-mac/doctor.sh --profile mac-vm
```

Run the apply command a second time. It must complete without creating another
backup or changing an already-correct link.

Then open Ghostty, Zed, and Herdr once and confirm they use the linked config.
Open Karabiner-Elements and complete macOS's required driver and Input
Monitoring permission prompts. Credentials and application sign-ins remain
manual.

The legacy entry point is now a safe wrapper around the same MacBook profile:

```bash
setup/mac-vm/setup-vm.sh --dry-run
setup/mac-vm/setup-vm.sh --apply
```

It no longer accepts a GitHub token or manages SSH, Nix, nvm, or rbenv.

## Mac mini boundary

For a new Mac mini toolchain, substitute `--profile mac-mini`. This installs
the shared development environment plus the mini's package overlay.

Do not run `--apply` on the existing production Mac mini until the clean-VM and
MacBook gates are green, the Mac mini preflight passes, and Hamel explicitly
approves the interactive step in
[`../personal-mac-standardization/QA.md`](../personal-mac-standardization/QA.md).
That apply is what completes the no-restart gate. The bootstrap does not start
or restart services, but a new login shell will resolve the shared mise
versions. Existing Cortana and Hermes LaunchAgents remain explicitly pinned to
Homebrew Node 22 until a separate maintenance window is approved.

## What apply changes

- Installs the shared Brewfile, then the selected machine overlay, without a
  broad upgrade or cleanup.
- Backs up and links only the reviewed config inventory.
- Adds one marker-owned mise-shims block to `~/.zprofile`; it never replaces
  the whole profile.
- Installs exact mise versions for Node, pnpm, Go, Python, and Bun.
- Installs pinned Ruff, mdformat, and GraphQL LSP versions.
- Restores the exact Neovim plugin lock and required Tree-sitter parsers without
  rewriting `lazy-lock.json`.
- Runs the verification doctor before reporting success. Its package and
  Neovim checks may refresh tool-owned caches, but it does not change managed
  links or install packages.

The linker intentionally leaves Herdr sessions, Zed prompts, tmux plugins,
credentials, auth state, services, and app databases alone.

## Rollback

Backups sit beside the original path as
`path.backup-YYYYMMDD-HHMMSS`. Roll back the full inventory printed by apply:

1. Close the affected applications and shells.
2. For every destination that had a backup, move the new symlink aside and move
   the timestamped backup back to its original name.
3. For every destination that was originally absent, move the newly created
   symlink aside so the path is absent again.
4. Restore the previous `~/.zprofile` backup. If bootstrap created `.zprofile`,
   move that new file aside instead. If the file predated bootstrap, never
   remove user-owned content outside the marked block.
5. Start a fresh login shell and run the baseline, doctor, and project checks
   from the QA runbook.

This config rollback intentionally leaves installed Homebrew packages, mise
runtimes, and tool caches in place. Uninstall and cleanup are outside this PR.

Never remove the Mac mini's Homebrew Node or pnpm fallback as part of this
bootstrap.
