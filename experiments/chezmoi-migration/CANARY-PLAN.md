# Canary Plan

## Purpose

Answer whether chezmoi can reproduce the supported user environment safely and
with less Bash. Canary work is disposable and must not affect a live host.

## Phase 0: Orka Compatibility Gate

Hamel installs Orka Desktop. Before relying on it, verify on the thin Mac that
one disposable macOS VM can:

- install and boot from a clean macOS image;
- reach the network and accept local SSH after manual guest setup;
- stop, start, erase, and rebuild predictably; and
- coexist with the existing VMware and Vagrant Ubuntu workflow.

Compatibility risk recorded on 2026-08-05: the thin Mac runs macOS 26.6, while
[Orka Desktop 3.1.0's published notes](https://docs.macstadium.com/orka/orka-desktop/orka-desktop-310-release-notes)
do not officially support macOS 26 hosts. Treat a successful local boot as
required evidence, not an assumption.

Do not connect the guest to personal accounts, production services, Tailscale,
or real credentials.

## Phase 1: Ownership Inventory

Use [OWNERSHIP-INVENTORY.md](OWNERSHIP-INVENTORY.md) as the exact ownership
contract for every prototype and rollback test.

Classify every currently managed path and package manifest as one of:

- chezmoi-owned user state;
- existing lifecycle or maintenance ownership;
- machine-owned mutable or secret state; or
- excluded from the migration.

Keep the existing repository `config/` tree canonical. Use chezmoi to declare
profile-aware symlinks into it, and render a file only when the target cannot
safely be a symlink. Record the rollback source for every transferred path.

## Phase 2: Disposable Ubuntu Canary

Reuse the current Vagrant and guest-local Ansible lifecycle, but give the
canary a distinct VM identity and Vagrant state. It must not reuse the active
Ubuntu VM, its credentials, its registered keys, or its Tailscale identity.

Build from zero, install chezmoi through the tiny bootstrap, and apply the
Ubuntu profile. Reproduce the normal user environment except secrets,
identities, personal state, and external enrollment.

## Phase 3: Disposable macOS Canary

Use one Orka VM. Apply and validate the thin-Mac profile first. After that
result is accepted, erase or rebuild the same VM and test the Mac mini profile.
Reuse the thin-Mac implementation as the base, then add only Mac-mini-specific
configuration links and package-manifest entries.

The Mac mini simulation is user-config-only. It must not install, start, stop,
or alter production services, launchd jobs, or runtime connections.

Mac-mini delta decision recorded on 2026-08-06: because the thin-Mac base passed
technical and interactive QA, the disposable Mac mini canary still requires
preview, apply, no-op, doctor, exclusion, and rollback checks, but does not
repeat the same interactive shell and editor QA.

The approved delta proof reused the same disposable VM after the tested
thin-Mac rollback instead of performing a second clean-room build. This
exception does not authorize a live Mac mini apply.

## Acceptance Gate

A canary passes only when all of these are true:

1. A clean machine builds without hidden manual file repair.
1. `chezmoi diff` is reviewed before the first apply.
1. A second apply is a no-op.
1. Existing applicable tests and doctors pass.
1. No excluded or unmanaged path changes unexpectedly.
1. The documented rollback restores the pre-chezmoi state.
1. The canary survives three normal workdays without unexplained drift.

Hamel decides whether the evidence is sufficient. Passing checks never promotes
a host automatically.

Ubuntu canary exception recorded on 2026-08-06: after extensive interactive QA,
Hamel explicitly accepted that prototype and waived its remaining three-day
soak. This does not waive soak or approval gates for any later host.

Thin-Mac canary result recorded on 2026-08-06: Hamel completed interactive QA
in the disposable Orka VM, accepted the result, and requested the next gated
step. This does not authorize a live-host apply.

## Evidence

Keep only sanitized evidence under a future `evidence/` directory:

- host and profile metadata without identifiers or secrets;
- pre-apply diff summary;
- first and second apply results;
- test and doctor results;
- rollback result; and
- observed drift or exceptions.

Recorded evidence:

- [Orka compatibility, 2026-08-06](evidence/orka-compatibility-2026-08-06.md)
- [Ubuntu canary, 2026-08-06](evidence/ubuntu-canary-2026-08-06.md)
- [Thin-Mac canary, 2026-08-06](evidence/macos-thin-canary-2026-08-06.md)
- [Mac mini delta canary, 2026-08-06](evidence/mac-mini-canary-2026-08-06.md)
