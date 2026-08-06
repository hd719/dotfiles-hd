# Production Promotion and Rollback Runbook

Status: final planning runbook. It does not authorize a change to any live
host. Every host cutover requires a fresh, explicit approval from Hamel.

## Control Path

```text
reviewed dotfiles commit
  -> canonical repository config/
  -> reviewed chezmoi profile and symlink declarations
  -> one approved production host
  -> verification and Hamel-controlled soak
  -> explicit promotion, hold, or rollback decision
  -> next host only after another approval
```

The pull-request path is agent branch as `arbiter-hd` -> reviewed PR -> merged
commit -> clean host checkout. Never apply an unmerged branch or a prototype
directory to a production host.

## Gate 0: Production Implementation

No host may start until one reviewed implementation PR has all of these:

- one production chezmoi source with explicit `ubuntu`, `mac-thin`, `mac-mini`,
  and optional `work-mac` profiles;
- the repository `config/` tree as the canonical configuration, with
  profile-aware symlinks instead of copied configuration trees;
- a roughly 15-25-line bootstrap that only detects the OS, installs pinned
  chezmoi when missing, and runs the reviewed init/apply flow;
- a preview mode that shows the exact target paths, scripts, and missing-package
  actions before writes;
- a host-local backup and rollback command proven against the exact production
  path manifest;
- profile doctors that verify idempotence, exclusions, machine identity, and
  mutable state; and
- no ownership of VM lifecycle, recurring maintenance, macOS preferences,
  services, launchd jobs, credentials, enrollment, or runtime state.

Draft PR #90 now contains the symlink-first implementation candidate under
`../../chezmoi/`. The copied per-canary source trees are removed. This gate
passes only after the implementation diff and isolated validation are reviewed;
merging it still does not authorize a host apply.

## Gate 1: Shared Preconditions

Before each host, confirm all items again:

- The previous required host is accepted or this is the first stage.
- The production implementation is merged and the host is on that exact clean
  commit.
- The [ownership inventory](OWNERSHIP-INVENTORY.md) matches the selected
  profile. No new path is added during the cutover.
- The existing doctor passes before any change.
- The current linker/bootstrap is available for rollback. A successful Ubuntu
  apply activates the ownership marker that stops its transferred-path writes.
- VM lifecycle and recurring maintenance commands have no planned diff.
- Hamel approves this host, profile, commit, scope, and maintenance window.

Any failed item is a stop, not a warning.

## Promotion Order

| Stage | Host               | Initial production scope                | Required gate before apply                         |
| ----- | ------------------ | --------------------------------------- | -------------------------------------------------- |
| 1     | Ubuntu workstation | User config and approved user manifests | Vagrant, Ansible, and system ownership unchanged   |
| 2     | Thin Mac           | Control-plane user environment          | Ubuntu healthy and reachable by both SSH paths     |
| 3     | Mac mini           | Configuration only; no package transfer | Runtime and home-lab readiness green before apply  |
| 4     | Work Mac           | Company-approved subset only            | Personal hosts accepted; Hamel explicitly opts in  |

The work Mac is optional. Skipping it does not block completion, but no script
still used by that host may be archived.

## Per-Host Cutover Checklist

Run this whole checklist independently for each host.

### 1. Identify and Baseline

Record locally, outside Git:

- hostname, selected profile, reviewed commit, date, and operator;
- clean `git status --short --branch` output;
- current doctor result;
- current target type and symlink destination for every approved path; and
- host-specific readiness results from the sections below.

Do not record credentials, tokens, private keys, `.env` values, or raw personal
configuration in evidence.

### 2. Back Up and Prove Restore

- Create a mode-`0700` timestamped directory under
  `~/.local/state/dotfiles-hd/chezmoi-backups/`.
- Save every transferring target and the prior ownership-marker state before
  changing writers.
- Create a manifest containing each target path, original type, symlink
  destination when applicable, permissions, and checksum for regular files.
- Verify the archive is readable and the manifest covers the entire profile
  allowlist.
- Dry-run the rollback command against the manifest. It must target only that
  host and backup.

The backup stays host-local and is never committed or copied to another host.

### 3. Review the Preview

Run the production preview and stop unless all are true:

- Every changed target is in the profile allowlist.
- Symlink destinations resolve inside the reviewed checkout, except the
  reviewed Ghostty terminfo target.
- No parent-directory permission is loosened.
- No deletion, service action, enrollment, credential path, mutable state, or
  unreviewed script appears.
- Package actions install only missing profile-approved user tools without
  upgrades, cleanup, trust changes, or removals.
- The portable Git include preserves the machine-owned global Git identity.

Save only a sanitized summary of the preview. Raw diffs can contain personal
machine state and stay local.

### 4. Transfer Ownership and Apply

- Apply the reviewed profile once.
- Apply it again and require zero output and zero target changes.
- Require empty chezmoi status.
- Activate the host-local ownership marker only after those checks pass. The
  previous Ubuntu link writers must then exit without writing.
- Do not run a general package upgrade or maintenance command during cutover.

If the second apply changes anything, stop and roll back.

### 5. Verify

- Run the production profile doctor and the host's existing doctor.
- Start a fresh login shell and verify its expected profile, aliases, prompt,
  editor, and terminal behavior.
- Verify Ghostty config and `xterm-ghostty` terminfo.
- Verify portable Git aliases and unchanged Git name, email, auth, and signing.
- Verify Neovim's selected profile, locked plugins, parsers, and unchanged
  `lazy-lock.json`.
- Verify all excluded mutable state is unchanged.
- Run the host-specific checks below.

Any unexplained drift, warning promoted from a previous pass, or ownership
change is a failure.

### 6. Soak and Decide

Use the host normally and check chezmoi status plus the host doctor at the end.
Seven normal days is the recommended observation period, but Hamel decides the
actual duration and may explicitly waive it.

The stage advances only after Hamel records one decision:

- **promote**: accept this host and later request the next host;
- **hold**: keep this host on chezmoi but do not advance; or
- **rollback**: execute the rollback section immediately.

Silence and passing automation are not approval.

## Host-Specific Gates

### Ubuntu Workstation

Before and after apply:

- `setup/ubuntu/doctor.sh` passes.
- The thin Mac reaches `ubuntu-vm-ts` and the fixed `ubuntu-vm` fallback.
- Vagrant status, VM identity, resources, networking, and provider state are
  unchanged.
- Ansible, APT/system packages, users, groups, SSH daemon, authorized keys,
  Docker, Tailscale, and netplan are unchanged.
- Git identity, SSH identities, known hosts, histories, and project checkouts
  remain machine-owned.
- `update-system.sh` retains recurring maintenance ownership.

Do not stop, recreate, or reprovision the production VM for this cutover.

### Thin Mac

Before and after apply:

- `setup/mac-thin/doctor.sh` passes.
- The accepted Ubuntu workstation remains healthy and reachable.
- VMware Fusion, the Vagrant VMware utility/service, provider plugin, `vm.zsh`,
  and Ubuntu lifecycle commands are unchanged.
- Ops fallback and `personal-ready` remain in place with the same behavior.
- The thin profile resolves Bookokrat, Ghostty, Herdr, Hunk, Starship, and
  Neovim without adding project runtimes or services.

Do not run a maintenance apply merely to validate this configuration cutover.

### Mac mini

This stage is configuration-only. Require a fresh approval immediately before
apply.

Before and after apply:

- Run the read-only home-lab readiness workflow and require core readiness
  green.
- `setup/mac-bootstrap/doctor.sh --profile mac-mini` passes.
- The runtime checkout commit and dirty state, service set, listening ports,
  LaunchAgent definitions, database health, Hermes/agent health, queues, and
  connection health match the baseline.
- `~/.zprofile`, Homebrew Node 22, pnpm fallback, `goodMorning`, the maintenance
  runner, and runtime shell functions remain machine-owned.
- No Brewfile is applied and no package, tap trust, service, or runtime action
  occurs.

Abort before apply if the preview includes a service or runtime-owned path.
Roll back immediately if any runtime readiness result changes, even when the
configuration doctor passes. Never restart a service to make this stage green.

### Work Mac

The work Mac is not an automatic stage.

- Hamel must opt in after all personal hosts are accepted.
- Reconfirm company policy and the exact allowlist immediately before work.
- Keep the live `~/.zshrc`, `~/.config/mise`, work runtimes, repositories,
  Docker, company apps, policy, credentials, certificates, and Git identity
  machine-owned.
- Use only the maximum scope in the ownership inventory and the verification
  block in `setup/mac-pro-resilience/README.md`.
- Do not import a personal profile, credential, service, or runtime setting.

Any policy ambiguity means skip this host and leave its current setup active.

## Rollback

Rollback is host-local and never advances another stage.

Trigger rollback for any unexpected target, failed second apply, non-empty
status, doctor failure, identity change, mutable-state change, service/runtime
change, broken normal workflow, or direct request from Hamel.

1. Stop all further chezmoi applies on that host.
1. Capture a sanitized failure summary and the reviewed commit.
1. Remove only targets listed in the backup manifest; refuse paths outside the
   user's home and the exact profile allowlist.
1. Restore the timestamped backup with original types and permissions.
1. Restore the prior ownership-marker state, which re-enables the Ubuntu link
   writers after the initial cutover rollback.
1. Run the existing host doctor and repeat the host-specific baseline checks.
1. On the Mac mini, rerun read-only home-lab readiness and require the original
   runtime state without restarting anything.
1. Record the rollback result and hold all later stages.

Package rollback never uninstalls packages automatically. It stops future
chezmoi package actions and returns recurring ownership to the existing
maintenance workflow.

## Legacy Archive Gate

Archive replaced Bash only after Ubuntu, the thin Mac, and the Mac mini are
accepted, plus the work Mac if it opted in.

- Build a script-by-script ownership list. Archive only code fully replaced by
  chezmoi.
- Keep Vagrant, Ansible, VM lifecycle, recurring maintenance, doctors, ops
  fallback, services, runtime actions, and work-Mac code still in use.
- Move replaced code to `legacy/pre-chezmoi-bootstrap/` with a README naming the
  last live owner, replacement, final commit, and rollback boundary.
- Preserve Git history and recovery value. Do not delete the archived code.
- Run every current doctor after the move before declaring the migration map
  complete.

Archiving is a separate reviewed PR and requires explicit approval.
