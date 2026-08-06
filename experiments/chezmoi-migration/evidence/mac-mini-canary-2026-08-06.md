# Mac Mini Chezmoi Delta Canary Evidence — 2026-08-06

## Result

The disposable Mac mini delta canary passes the approved automated gates. By
Hamel's decision, it reuses the accepted thin-Mac design and does not repeat
interactive shell and editor QA. This evidence does not authorize an apply to
the live Mac mini.

## Delta Scope

- Reused the same disposable Orka macOS 26.6 ARM64 VM after the proven thin-Mac
  rollback; this was a delta proof rather than a second clean-room build.
- Replaced the thin shell entrypoint with `setup/mac-mini/.zshrc`.
- Managed 17 exact symlinks, adding narrowed Btop, Fastfetch, mise, and Hermes
  targets without exposing their mutable or legacy state.
- Installed 40 safe user-tool Brewfile entries.
- Excluded Node, pnpm, PostgreSQL, pgvector, Tailscale, production apps,
  services, launchd jobs, credentials, enrollment, and runtime connections.

## Automated Proof

- Preview contained only the approved symlinks and narrow Git include action.
- First apply passed; second apply and `chezmoi status` each produced zero
  bytes.
- The doctor passed every link, package, shell, Ghostty, Git, full-profile
  Neovim, and exclusion check.
- Btop logs, Fastfetch legacy data, Herdr sessions, Hunk state, mise state, and
  Hermes session data survived apply unchanged.
- Full-profile Neovim restored plugins and Markdown parsers while preserving
  `lazy-lock.json` at SHA-256
  `f261ce42c6fdbc40466da5c124d789c2b17b1964bc84f39b75802eac7535a614`.
- Rollback restored the seeded pre-chezmoi state. Reapply passed the doctor, and
  the following apply again produced zero bytes.

## Boundary Found

The first package attempt found that `steipete/tap/remindctl` now requires an
explicit Homebrew trust decision. The canary did not grant that trust. It
removed the third-party tap and `remindctl` from its managed package set, then
passed the final Brewfile and doctor checks. That machine-level trust decision
remains outside chezmoi.
