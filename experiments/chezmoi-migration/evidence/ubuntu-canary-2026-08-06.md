# Ubuntu Chezmoi Canary Evidence — 2026-08-06

## Result

The disposable Ubuntu canary passes the technical and human gates. After
extensive interactive QA on 2026-08-06, Hamel accepted the prototype and
explicitly waived the remaining three-normal-workday soak. The canary is
applied and running. This evidence does not authorize promotion to a live
host.

## Isolation

- Fresh pinned Bento Ubuntu 26.04 ARM64 box.
- Separate Vagrant state, hostname, forwarded SSH port, VMware display name,
  and network adapter identity.
- Credential-free `hamel` user with a locked password.
- No Tailscale installation, personal SSH keys, tokens, or production
  enrollment.
- Production Ubuntu VM was stopped through its existing lifecycle; its files
  and configuration were not changed.

## Preview and Apply

- Chezmoi pinned to `v2.72.0`.
- Reviewed a 4,322-line first-apply diff.
- Source resolves to 76 managed entries, including 49 rendered files.
- First apply completed from the tiny bootstrap.
- Second apply produced 0 bytes of output and no target changes.
- No symlink was rendered for the managed user configuration.

## Checks

- `vagrant validate`, Ruby syntax, shell syntax, Zsh syntax, and repository
  whitespace checks passed.
- Existing Ubuntu lean setup test passed with `lean_setup_tests=ok`.
- Canary doctor passed for target drift, Zsh, portable Git aliases, preserved
  machine-owned Git identity, all declared CLI tools, Herdr reset support, and
  SSH-secret exclusions.
- A fresh Ghostty login shell resolves `xterm-ghostty`, runs `clear`, exposes
  the `ll` LSD alias, and reports LSD 1.2.0.
- Hamel completed extensive interactive QA and confirmed the rendered shell,
  terminal tools, themes, and editor environment looked and behaved correctly.
- Excluded Btop logs, Fastfetch legacy files, SSH identities, and `known_hosts`
  were not rendered.

## Rollback and Recovery

- Rollback removes only exact managed files and symlinks under the canary home.
- It does not call `chezmoi destroy`, which would also remove source-state
  files.
- The pre-apply shell marker and machine-owned Git identity were restored.
- The source and rollback archive remained available.
- Non-interactive rollback completed without a prompt.
- Reapply after rollback reran the idempotent side-effect scripts, passed the
  doctor, and produced another empty second apply.

## Defects Found and Fixed in the Canary

1. The default VM network identity collided with the production Bento VM. The
   canary now has a separate adapter identity.
1. Neovim's plugin manager advanced its own lock entry. The install script now
   restores the pinned plugin-manager revision before validation.
1. The first rollback design included managed directories and used
   `chezmoi destroy`; this could remove the backup and source state. Rollback
   now deletes only exact rendered targets and preserves the source.
1. Chezmoi remembered side-effect script entries after rollback. Rollback now
   resets only chezmoi's internal persistent state so recovery reapply is
   complete.
1. The doctor treated one-time scripts as persistent targets and did not count
   a failed Git-alias assertion. Both checks are now strict.
1. First normal use found that the minimal canary Ansible package list omitted
   production-owned Ghostty terminfo and LSD. The canary now installs the
   existing production packages, checks their shell behavior, and reprovisions
   with zero Ansible changes. A stale temporary source upload also blocked that
   second provision; the canary now replaces only its disposable upload copy.

## Acceptance

- Technical proof: passed.
- Interactive QA: accepted by Hamel on 2026-08-06.
- Three-normal-workday soak: explicitly waived by Hamel for this disposable
  Ubuntu canary after the interactive QA.
- Live-host promotion remains a separate decision and requires explicit
  approval.
