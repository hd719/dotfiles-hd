# Thin-Mac Chezmoi Canary Evidence — 2026-08-06

## Result

The disposable thin-Mac canary passes the technical and human QA gates. Hamel
accepted the result on 2026-08-06 and requested the next gated step. This
evidence does not authorize an apply to a live host.

## Isolation and Scope

- Disposable Orka macOS 26.6 ARM64 VM with no personal accounts, credentials,
  Tailscale enrollment, production services, or durable state.
- Chezmoi pinned to `v2.72.0` and installed under the canary user.
- Existing repository `config/` tree stayed canonical.
- Chezmoi managed ten profile-aware symlinks plus one narrow Git include action.
- The canary Brewfile installed 15 approved tools and excluded Vagrant, VMware,
  security services, network enrollment, credentials, and personal apps.

## Apply and Checks

- The first preview exposed unsafe parent-directory permission changes under
  `~/Library`; the source attributes were corrected before apply.
- First apply passed. The second apply produced zero bytes, and
  `chezmoi status` produced zero bytes.
- The doctor passed all shell, Git identity, Ghostty, Homebrew, tool, config,
  mutable-state, and exclusion checks.
- Fresh Zsh exposed the thin profile, editor, LSD alias, and expected tools.
- Ghostty configuration validated, and user-local `xterm-ghostty` terminfo made
  `clear` work without changing system state.
- Thin-profile Neovim restored its plugins and Markdown parsers while preserving
  `lazy-lock.json` byte-for-byte.
- Hamel completed interactive QA and accepted the shell, terminal, tools, and
  editor behavior.

## Rollback and Recovery

- Rollback removed only the managed targets, reset canary-local chezmoi state,
  and restored the pre-apply archive.
- The original shell marker, Git identity, and mutable application state were
  restored. Installed packages were deliberately left in place.
- Reapply after rollback passed the full doctor again.
- The post-rollback second apply also produced zero bytes.

## Production Implication

The approved direction is symlink-first: keep `config/` canonical and let
chezmoi select links by profile. The copied Ubuntu source in draft PR #90 is
prototype evidence, not the final production shape, and must be refactored
before merge. No live thin Mac, Mac mini, or work Mac was changed.
