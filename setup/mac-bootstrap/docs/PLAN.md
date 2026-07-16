# Personal Mac Toolchain Standardization Plan

- Status: PR #9 is merged. MacBook live/reboot QA and immediate Mac mini
  no-restart QA passed; one-hour and next-day observation remain open
- Plan branch: `agent/plan-personal-mac-mise-standardization`
- Base branch: `origin/master` (this repository uses `master`, not `main`)
- Targets: personal MacBook (`mac-vm`), Mac mini (`mac-mini`), and a brand-new
  Apple Silicon personal Mac
- QA runbook: [`QA.md`](QA.md)

## PR #9 Completion Status

- [x] Implement the shared bootstrap, ownership model, and exact runtime pins.
- [x] Pass shell, formatting, Brewfile, and 141 bootstrap assertions.
- [x] Pass the actual-tool isolated-home run twice without live PATH changes.
- [x] Pass project compatibility, Neovim, GraphQL LSP, and security checks.
- [x] Complete PR review with no remaining Critical, High, Medium, or Low
  findings.
- [x] Record the exact tested commit and durable evidence in
  [`RESULTS.md`](RESULTS.md).
- [x] Record Hamel's 2026-07-16 waiver of the clean Apple Silicon macOS VM gate
  because no macOS VM is available.
- [x] Complete the live MacBook canary, rollback drill, reboot, and post-reboot
  checks before merge.
- [x] Complete the Mac mini no-restart activation and immediate QA after merge.
- [ ] Complete the one-hour and next-day observation window.

Unchecked items later in this plan are intentional live-machine gates;
isolated temporary-home evidence does not mark them complete. The VM gate is
waived, not passed.

## Goal

Make both personal Macs reproducible, including a clean-machine rebuild path,
without risking the working Mac mini runtime.

Standardization means the same ownership rules and tested version policy. It
does not mean every installed Homebrew formula must be identical.

## Safety Contract

- Hamel explicitly approved implementing the plan in this same PR.
- The implementation remains surgical and cannot bypass a failed QA gate.
- The MacBook is the canary. The Mac mini is never first.
- The approved shared pins are installed and tested in isolation before any
  live PATH switch. The MacBook activates them first; the Mac mini follows only
  after that canary is green and PR #9 is merged.
- Homebrew fallbacks stay installed through the initial rollout and soak.
- No service or runtime restart happens without Hamel's approval.
- A failed hard gate stops the rollout. Do not improvise around it.
- Rollback must be proven before duplicate tools are removed.

## Scope

### Included

- One ownership model for personal Mac development tools.
- A shared mise runtime policy for Node, pnpm, Go, Python, and Bun.
- Reliable tool resolution in interactive, non-interactive login, and IDE
  shells, plus documented fixed-path exceptions for scripts and LaunchAgents.
- Reproducible Homebrew inventories for common and machine-specific tools.
- MacBook project validation and Mac mini runtime protection.
- Backup, rollback, idempotency, and observation procedures.
- Documentation of each machine's intentional exceptions.
- A check-first, backed-up, idempotent clean-Mac bootstrap and verification
  doctor.

### Explicitly excluded

- `setup/mac-resilience` and all work-laptop tooling.
- `setup/ubuntu`; that work belongs to the separate Ubuntu effort.
- Credentials, SSH, GitHub auth, certificates, Docker state, or app databases.
- PostgreSQL, pgvector, Tailscale, Hermes, or Cortana feature changes.
- Neovim Lua/plugin changes.
- Any manager or version change for the Mac mini production runtime.
- Homebrew cleanup, `brew autoremove`, or fallback uninstalls during rollout.
- Full reconstruction of Mac mini Cortana/Hermes services, LaunchAgents,
  secrets, or runtime databases. This PR covers its toolchain only.

## Current State

The symlinks already share configuration. They do not install tools, select
versions, or control the PATH used by services.

| Area | Personal MacBook | Mac mini | Risk |
| --- | --- | --- | --- |
| Dotfiles branch | Live checkout | Clean `master` checkout | Editing a linked file can take effect immediately. |
| mise config | `~/.config/mise` links to `config/mise` | Not linked | Only one machine consumes the shared pins today. |
| Interactive Node | mise `26.1.0` | Homebrew `22.23.1` | Different manager and major version. |
| pnpm | Homebrew `11.11.0` | Homebrew shell `11.11.0`; Cortana declares `11.2.2` | A package-manager mismatch can change installs and runtime commands. |
| Go | mise `1.26.3` | Homebrew `1.26.5` | Different manager and patch version. |
| Python | mise `3.14.5` | Homebrew `3.14.6` | Homebrew Python may remain as another formula's dependency. |
| Bun | mise `1.3.14` | Missing | Bun projects are not reproducible on the mini. |
| Neovim | Observed Homebrew `0.12.4` | Observed Homebrew `0.12.4` | Already aligned; keep Homebrew ownership and require `0.12+`. |
| Non-interactive shell | Homebrew fallbacks win; some mise tools are absent | Homebrew wins | Scripts, IDEs, and LaunchAgents may not see mise. |
| Mac mini runtime | N/A | Running on Homebrew Node 22 and pnpm-linked paths | Highest-risk dependency; Node migrates last. |

Baseline hazards found before PR #9 implementation:

- `goodMorning()` ran broad Homebrew upgrades and cleanup. This PR pauses those
  operations while fallbacks are required.
- `_remove_mise_npm()` deleted npm and npx from the mise Node installation.
  This PR removes that function and call.
- The MacBook had no Brewfile. This PR adds a shared baseline and thin overlay.
- `setup/mac-vm/setup-vm.sh` referenced nvm, rbenv, removed Nix files, and a
  nonexistent shell source. This PR replaces it with the safe bootstrap wrapper.
- The MacBook's live `~/.config/mise` symlink points into this checkout. Future
  mise edits must be tested in a separate worktree with an isolated config.

## Target Ownership Model

| Owner | Tools | Rule |
| --- | --- | --- |
| Homebrew | mise itself, apps, services, system libraries, shell plugins | Homebrew owns machine integration. |
| Homebrew | `rg`, `fd`, `fzf`, LazyGit, and similar generic CLIs | Keep stable editor helpers simple in the first rollout. |
| mise | Node, pnpm, Go, Python, Bun | Pin version-sensitive development runtimes in one shared config. |
| Homebrew initially | Neovim, Tree-sitter CLI, LuaLS, StyLua, Bash LSP, vtsls, VS Code LSPs | They already work. Revisit only in a later editor-tool PR. |
| uv | Ruff and mdformat | Pin exact versions; do not use `latest`. |
| Fixed pnpm home | GraphQL LSP `3.5.0` under `~/.local/graphql-lsp` | Keep the path expected by Neovim and pin the pnpm install command exactly. |
| Project | Prettier, ESLint, and project-specific runtime overrides | A repository requirement beats the global default. |
| Documented exception | Mac mini production runtime on keg-only Homebrew `node@22`; LaunchAgents prepend its opt path | Safety beats cosmetic uniformity. Keeping it unlinked avoids conflicts with Homebrew tools that depend on unversioned Node. Remove the exception only in a maintenance window. |

## Approved Shared Pins and Activation Gate

These are the single shared interactive-development defaults implemented by
this PR. The existing Mac mini production runtime remains a separate Homebrew
exception and is not restarted or migrated.

| Tool | Approved shared baseline | Reason |
| --- | --- | --- |
| Node | `24.18.0` | Active LTS baseline approved on 2026-07-15 for the shared interactive daily driver; the Mac mini production runtime remains an explicit Homebrew Node 22 exception. |
| pnpm | `11.2.2` | Matches `cortana-services` `packageManager`. |
| Go | `1.26.3` | Existing shared mise pin; test before accepting the mini patch-level change. |
| Python | `3.14.5` | Existing shared mise pin. Homebrew Python may remain as a dependency. |
| Bun | `1.3.14` | Existing shared mise pin. |
| Neovim | `0.12+`, Homebrew-owned | Keep the working release line without pretending Homebrew pins a patch. |

Node 24 must pass the MacBook project matrix before live activation. If a real
project requires Node 26, use a project-local override or stop for a separate
version decision; do not change the Mac mini production runtime in this PR.

### Approval checklist

- [x] Hamel approves the ownership table.
- [x] Hamel approves Node `24.18.0` as the shared default. This supersedes the
  earlier conservative Node `22.23.1` choice because Node 22 is now in
  Maintenance LTS while Node 24 is Active LTS at approval time.
- [x] Hamel approves pnpm `11.2.2` as the shared default.
- [x] Every approved version is available through mise for the Apple Silicon
  target architecture.
- [x] Project-local runtime requirements are inventoried before changing PATH.
  Cortana pins pnpm `11.2.2` and Go `1.26.3`; the personal Next.js monorepo pins
  Bun `1.3.3` and accepts Bun `>=1.0.0`.

## Proposed Repository Shape

Keep portable policy separate from machine-specific setup:

```text
config/mise/config.toml             shared runtime pins
setup/mac-bootstrap/Brewfile        common managed-Mac packages
setup/mac-bootstrap/bootstrap.sh    check-first installer and linker
setup/mac-bootstrap/doctor.sh       verification without managed-config writes
setup/mac-bootstrap/docs/           this plan and QA record
setup/mac-vm/Brewfile               MacBook-only packages
setup/mac-mini/Brewfile             Mac-mini-only apps, services, and libraries
setup/mac-vm/zsh-config/            shared shell behavior
```

This shape is implemented in this PR. Removing already-installed Homebrew
fallbacks remains deferred; Brewfile reorganization does not uninstall them.

## Implementation Sequence

Implementation and isolated QA may proceed in parallel. Live activation gates
are sequential: the MacBook reboot canary is the pre-merge substitute for the
waived VM, and the Mac mini cannot be activated after merge while the MacBook
gate is red.

### Phase 0: Approve the plan

- [x] Review this plan and [`QA.md`](QA.md).
- [x] Resolve the shared Node and pnpm decision gate.
- [x] Confirm `mac-resilience` and Ubuntu remain excluded.
- [x] Confirm the Mac mini maintenance window requires a separate approval.
- [x] Record Hamel's approval in this PR branch.

Exit gate: scope, versions, ownership, stop rules, and rollback are accepted.

### Phase 0B: Build and prove the clean-machine path

- [x] Replace the unsafe legacy Mac setup script with a thin compatibility
  wrapper.
- [x] Add common and profile-specific Brewfiles.
- [x] Add an explicit check/apply bootstrap with safe backups and no cleanup,
  credential handling, or service control.
- [x] Add a verification doctor and temporary-home regression suite.
- [x] Record the clean Apple Silicon macOS VM waiver; do not mark the VM test as
  passed.
- [x] Use the live MacBook reboot canary in [`QA.md`](QA.md) as the compensating
  pre-merge gate, including two applies and a rollback drill.

Exit gate: automated temporary-home tests pass, then the live MacBook canary
proves apply, rollback, reapply, reboot, and post-reboot health before merge.

### Phase 1: Capture a two-machine baseline

- [x] Create a timestamped evidence directory on each Mac.
- [x] Record OS, architecture, Git state, symlink targets, tool paths, and
  versions without capturing environment variables or secrets.
- [x] Record interactive and non-interactive shell resolution separately.
- [ ] Save `brew bundle dump` and `mise ls --json` rollback inventories.
- [x] On the Mac mini, record LaunchAgent command paths, running Node/pnpm
  process paths, `brew services list`, `pnpm runtime:status`, and
  `pnpm runtime:doctor`.
- [x] Confirm both dotfiles checkouts are clean before proceeding.

Exit gate: the baseline section of `QA.md` is green and evidence paths are
recorded.

### Phase 2: Make testing safe and deterministic

- [x] Create implementation branches in a separate Git worktree, not the
  checkout targeted by live symlinks.
- [x] Test exact candidate specs in isolated mise directories with
  `MISE_NO_CONFIG=1` and `mise exec`.
- [x] Add exact approved shared pins; do not use `latest`. Activation still
  follows the MacBook-first and Mac-mini no-restart gates.
- [x] Remove `_remove_mise_npm()` before mise owns Node/pnpm.
- [x] Disable broad upgrade, `brew cleanup`, and `brew autoremove` during migration and
  soak. Keep normal maintenance as a separately reviewed concern.
- [x] Preserve existing Homebrew runtimes as fallbacks.
- [x] Add a safe, backed-up `.zprofile` shim strategy for non-interactive and
  IDE shells, following mise's
  [zsh shim guidance](https://mise.jdx.dev/dev-tools/shims.html); do not blindly
  replace an existing profile.

Exit gate: the approved pins install and execute from isolated directories
without touching the live symlinked config.

### Phase 3: MacBook canary

- [x] Install the approved shared pins without switching the global PATH.
- [x] Run the MacBook project matrix through `mise exec`.
- [x] Confirm Node/npm/npx/pnpm, Go, Python, and Bun paths and versions.
- [x] Activate the shared pins on the MacBook.
- [x] Validate a fresh non-interactive shell.
- [ ] Validate an IDE-launched terminal.
- [x] Run Neovim startup, health, formatter, Tree-sitter, and LSP checks.
- [x] Run `cortana-services` local CI and Go tests from a clean checkout.
- [ ] Complete at least one normal work session on the canary.
- [ ] Prove per-command Homebrew rollback before continuing.
- [x] Reboot the MacBook, then repeat the doctor, fresh-shell, Neovim, project,
  and clean-Git checks.

Exit gate: all MacBook checks pass, its repositories remain clean, and Hamel
accepts the normal-work-session and post-reboot behavior before merge.

### Phase 4: Post-merge Mac mini interactive canary, no restart

- [x] Verify, then fast-forward the Mac mini dotfiles checkout to the exact
  merged `master` commit.
- [x] Back up any existing `~/.config/mise` and `.zprofile` before linking or
  editing.
- [x] Preview, then apply the merged `mac-mini` profile, which backs up and
  links the shared config without controlling services.
- [x] Install the approved shared tools with mise; do not remove Homebrew tools.
- [x] Test with `mise exec`, then a fresh interactive shell.
- [x] Re-run non-interactive, Neovim, and project checks.
- [ ] Observe an IDE-launched terminal separately.
- [x] Confirm already-running services use the same binaries as the baseline.
- [x] Run `brew services list`, `pnpm runtime:status`, and
  `pnpm runtime:doctor` without restarting anything.
- [x] Run project and Neovim QA from isolated/clean worktrees; do not run an
  install inside the active Cortana runtime checkout.

Exit gate: both interactive environments use the approved shared pins, all
Mac mini service processes still use their baseline Homebrew paths, and runtime
health is unchanged.

### Phase 5: Mac mini runtime decision and maintenance window

This phase is conditional. If LaunchAgents safely remain on an explicit
Homebrew Node 22 path, document that exception and skip the migration. If the
runtime should move to mise, stop for approval.

- [x] Review every recorded LaunchAgent and wrapper that starts Node or pnpm.
- [x] Keep and document the explicit Homebrew Node 22 launch contract.
- [ ] Prepare a one-command Homebrew fallback before restart.
- [ ] Obtain Hamel's explicit maintenance-window approval.
- [ ] Restart only the affected services.
- [ ] Run immediate runtime status, doctor, endpoint, and lane smoke checks.
- [ ] Roll back immediately if any new degradation appears.

Exit gate: runtime health matches baseline and rollback remains available.

### Phase 6: Observe, then clean up

- [ ] Recheck both machines immediately, after one hour, and the next day.
- [x] Run `mise install` twice and confirm the second run is a no-op.
- [x] Keep `goodMorning()` out of rollout QA because it also performs unrelated
  Zoom, Downloads, `.DS_Store`, and cache housekeeping. Test `mise install`
  directly instead.
- [ ] Confirm no project or dotfiles drift was created.
- [ ] Unlink duplicate formulae before uninstalling them.
- [ ] Remove shared duplicates from machine Brewfiles only in a cleanup PR.
- [ ] Uninstall fallbacks only after a second explicit approval and successful
  rollback drill.
- [ ] Keep Homebrew dependencies that are still required by other formulae.

Exit gate: both machines remain green through the observation window.

### Phase 7: Optional editor-tool follow-up

- [ ] Decide separately whether Neovim and version-sensitive editor tools should
  move from Homebrew to mise.
- [ ] If approved, migrate one editor tool family at a time and rerun the full
  Neovim QA matrix.

Exit gate: any optional editor migration is proven independently without
changing the work Mac or Ubuntu setup.

## Key Files

These files implement the approved scope in PR #9.

| File | Expected purpose |
| --- | --- |
| `config/mise/config.toml` | Approved shared runtime and package-manager pins. |
| `setup/mac-vm/zsh-config/functions.zsh` | Remove npm deletion and make maintenance migration-safe. |
| `setup/mac-vm/zsh-config/.zshrc` | Keep interactive activation predictable. |
| `setup/mac-bootstrap/mise-shims.zsh` | Expose mise shims safely to non-interactive/IDE shells. |
| `setup/mac-bootstrap/bootstrap.sh` | Check-first personal-Mac installer and linker. |
| `setup/mac-bootstrap/doctor.sh` | Package, link, shell, runtime, and Neovim checks without managed-config writes. |
| `setup/mac-bootstrap/Brewfile` | Shared Homebrew baseline. |
| `setup/mac-vm/Brewfile` | MacBook-only overlay. |
| `setup/mac-mini/Brewfile` | Mac mini apps, services, libraries, and documented exceptions. |
| `README.md` and `AGENTS.md` | Final inventory, ownership rules, and recovery guidance. |

## Hard Stop Conditions

Stop and use the rollback section in [`QA.md`](QA.md) when any of these occurs:

- A dirty dotfiles or project checkout cannot be explained.
- An isolation phase changes the live effective tool version.
- Node changes major version before the Node gate is approved.
- npm or npx disappears from the mise Node installation.
- `pnpm --version` differs from the approved project version during project QA.
- A LaunchAgent depends on a path scheduled for removal.
- `pnpm ci:local`, Go tests, Neovim startup, or LSP checks regress.
- Mac mini `runtime:status` or `runtime:doctor` is worse than baseline.
- PostgreSQL, Tailscale, Hermes, or a Cortana lane becomes unhealthy.
- The Lazy lockfile or application config changes unexpectedly.
- A restart is required before its maintenance window is approved.
- The MacBook canary cannot complete apply twice, rollback, reapply, reboot, or
  post-reboot verification.
- Rollback fails once. Stop instead of attempting repeated live repairs.

## Definition of Done

- [ ] Both personal Macs follow the approved ownership policy.
- [ ] Shared runtime versions are pinned or an intentional exception is written.
- [ ] Interactive, non-interactive, and IDE shell checks pass on both machines.
- [x] Neovim and project QA pass on both machines.
- [ ] Mac mini runtime health matches its baseline through the next-day check.
- [x] No work-Mac, Ubuntu, credential, service-config, or unrelated files changed.
- [ ] Rollback was tested before any fallback was removed.
- [ ] Bootstrap documentation matches the final symlink and package state.
- [x] The unavailable clean Apple Silicon macOS VM is explicitly waived rather
  than recorded as passed.
- [x] The live MacBook passes apply twice, rollback, reapply, reboot, Neovim,
  shell, project, and manual app checks from the exact reviewed commit.
- [ ] PR #9 contains the completed pre-merge MacBook QA record; a QA-only
  follow-up PR records the post-merge Mac mini and observation results.
