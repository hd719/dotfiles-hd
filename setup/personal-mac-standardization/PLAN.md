# Personal Mac Toolchain Standardization Plan

- Status: Planning only
- Plan branch: `agent/plan-personal-mac-mise-standardization`
- Base branch: `origin/master` (this repository uses `master`, not `main`)
- Targets: personal MacBook (`mac-vm`) and Mac mini (`mac-mini`)
- QA runbook: [`QA.md`](QA.md)

## Goal

Make both personal Macs reproducible without risking the working Mac mini
runtime.

Standardization means the same ownership rules and tested version policy. It
does not mean every installed Homebrew formula must be identical.

## Safety Contract

- This branch changes documentation only.
- Implementation happens in small pull requests after this plan is approved.
- The MacBook is the canary. The Mac mini is never first.
- Manager migration and version upgrades are separate changes. Temporary
  per-machine transition pins preserve current versions during the manager
  move; shared-version convergence follows only after that is green.
- Homebrew fallbacks stay installed through the initial rollout and soak.
- No service or runtime restart happens without Hamel's approval.
- A failed hard gate stops the rollout. Do not improvise around it.
- Rollback must be proven before duplicate tools are removed.

## Scope

### Included

- One ownership model for personal Mac development tools.
- A shared mise runtime policy for Node, pnpm, Go, Python, and Bun.
- Reliable tool resolution in interactive, non-interactive login, and IDE
  shells, plus explicit launch contracts for scripts and LaunchAgents.
- Reproducible Homebrew inventories for common and machine-specific tools.
- MacBook project validation and Mac mini runtime protection.
- Backup, rollback, idempotency, and observation procedures.
- Documentation of each machine's intentional exceptions.

### Explicitly excluded

- `setup/mac-resilience` and all work-laptop tooling.
- `setup/ubuntu`; that work belongs to the separate Ubuntu effort.
- Credentials, SSH, GitHub auth, certificates, Docker state, or app databases.
- PostgreSQL, pgvector, Tailscale, Hermes, or Cortana feature changes.
- Neovim Lua/plugin changes.
- A Node 26 upgrade on the Mac mini during the manager migration.
- Homebrew cleanup, `brew autoremove`, or fallback uninstalls during rollout.
- Repairing the old `setup/mac-vm/setup-vm.sh` in the first implementation PR.

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
| Neovim | Homebrew `0.12.4` | Homebrew `0.12.4` | Already aligned; do not move it in the runtime phase. |
| Non-interactive shell | Homebrew fallbacks win; some mise tools are absent | Homebrew wins | Scripts, IDEs, and LaunchAgents may not see mise. |
| Mac mini runtime | N/A | Running on Homebrew Node 22 and pnpm-linked paths | Highest-risk dependency; Node migrates last. |

Additional known hazards:

- `goodMorning()` runs broad Homebrew upgrades and cleanup.
- `_remove_mise_npm()` deletes npm and npx from the mise Node installation.
- The MacBook has no current Brewfile.
- `setup/mac-vm/setup-vm.sh` still references nvm, rbenv, removed Nix files,
  and a nonexistent shell source. It is not a safe rebuild path today.
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
| Fixed npm prefix | GraphQL LSP `3.5.0` under `~/.local/graphql-lsp` | Keep the path expected by Neovim and pin the install command exactly. |
| Project | Prettier, ESLint, and project-specific runtime overrides | A repository requirement beats the global default. |
| Documented exception | Mac mini production runtime, if LaunchAgents must remain on Homebrew Node 22 | Safety beats cosmetic uniformity. Remove the exception only in a maintenance window. |

## Transition Pins and Version Decision Gate

First preserve the current effective versions while testing mise ownership:

| Tool | MacBook transition pin | Mac mini transition pin |
| --- | --- | --- |
| Node | `26.1.0` | `22.23.1` |
| pnpm | `11.11.0` | `11.11.0` for the interactive shell; keep the runtime's recorded `11.2.2` path unchanged |
| Go | `1.26.3` | `1.26.5` |
| Python | `3.14.5` | `3.14.6` |
| Bun | `1.3.14` | Not activated during manager-only migration |

The Mac mini transition config remains machine-local and unlinked. This lets us
prove mise ownership without silently changing versions. It is removed only
after the shared convergence pins pass their own PR and QA cycle.

Do not edit or link the shared convergence pins until the candidate set passes
isolated tests on both machines.

| Tool | Candidate shared convergence baseline | Reason |
| --- | --- | --- |
| Node | `22.23.1` | Matches the working Mac mini runtime and avoids combining manager migration with a major upgrade. |
| pnpm | `11.2.2` | Matches `cortana-services` `packageManager`. |
| Go | `1.26.3` | Existing shared mise pin; test before accepting the mini patch-level change. |
| Python | `3.14.5` | Existing shared mise pin. Homebrew Python may remain as a dependency. |
| Bun | `1.3.14` | Existing shared mise pin. |
| Neovim | `0.12.4`, Homebrew-owned | Both machines already match. |

The Node recommendation is provisional. Test Node 22 on the MacBook without a
PATH switch. If its real projects fail, stop and decide between a project-local
Node 26 override and a separately planned Mac mini Node 26 upgrade.

### Approval checklist

- [ ] Hamel approves the ownership table.
- [ ] Both per-machine transition pin sets are confirmed against fresh-shell
  baselines.
- [ ] Hamel approves Node `22.23.1` as the candidate shared default.
- [ ] Hamel approves pnpm `11.2.2` as the candidate shared default.
- [ ] Every candidate version is available through mise on both architectures.
- [ ] Project-local runtime requirements are inventoried before changing PATH.

## Proposed Repository Shape

Keep portable policy separate from machine-specific setup:

```text
config/mise/config.toml                  shared runtime pins
setup/personal-mac/Brewfile              common personal-Mac packages
setup/mac-vm/Brewfile                    MacBook-only packages
setup/mac-mini/Brewfile                  Mac-mini-only apps, services, and libraries
setup/mac-vm/zsh-config/                 shared shell behavior
setup/personal-mac-standardization/      this plan and QA record
```

This shape is a target, not a change on this branch. Existing Mac mini formulae
move only after the runtime migration is stable. Do not combine Brewfile
reorganization with tool activation.

## Implementation Sequence

Each phase is its own reviewable PR or explicit approval gate. A later phase
cannot begin while an earlier gate is red.

### Phase 0: Approve the plan

- [ ] Review this plan and [`QA.md`](QA.md).
- [ ] Resolve the version decision gate.
- [ ] Confirm `mac-resilience` and Ubuntu remain excluded.
- [ ] Confirm the Mac mini maintenance window requires a separate approval.
- [ ] Record approval in the PR.

Exit gate: scope, versions, ownership, stop rules, and rollback are accepted.

### Phase 1: Capture a two-machine baseline

- [ ] Create a timestamped evidence directory on each Mac.
- [ ] Record OS, architecture, Git state, symlink targets, tool paths, and
  versions without capturing environment variables or secrets.
- [ ] Record interactive and non-interactive shell resolution separately.
- [ ] Save `brew bundle dump` and `mise ls --json` rollback inventories.
- [ ] On the Mac mini, record LaunchAgent command paths, running Node/pnpm
  process paths, `brew services list`, `pnpm runtime:status`, and
  `pnpm runtime:doctor`.
- [ ] Confirm both dotfiles checkouts are clean before proceeding.

Exit gate: the baseline section of `QA.md` is green and evidence paths are
recorded.

### Phase 2: Make testing safe and deterministic

- [ ] Create implementation branches in a separate Git worktree, not the
  checkout targeted by live symlinks.
- [ ] Test candidate pins with an isolated `MISE_GLOBAL_CONFIG_FILE` and
  `mise exec`.
- [ ] Add exact per-machine transition pins first; do not use `latest`.
- [ ] Remove `_remove_mise_npm()` before mise owns Node/pnpm.
- [ ] Disable broad `brew cleanup` and `brew autoremove` during migration and
  soak. Keep normal maintenance as a separately reviewed concern.
- [ ] Preserve existing Homebrew runtimes as fallbacks.
- [ ] Add a safe, backed-up `.zprofile` shim strategy for non-interactive and
  IDE shells, following mise's
  [zsh shim guidance](https://mise.jdx.dev/dev-tools/shims.html); do not blindly
  replace an existing profile.

Exit gate: the transition pins match each machine's baseline and resolve in
both supported shell modes without touching the live symlinked config.

### Phase 3: MacBook canary

- [ ] Install the MacBook transition pins without switching the global PATH.
- [ ] Run the MacBook project matrix through `mise exec`.
- [ ] Confirm Node/npm/npx/pnpm, Go, Python, and Bun paths and versions.
- [ ] Activate the MacBook transition pins for a fresh interactive shell only.
- [ ] Validate a fresh non-interactive shell and IDE-launched terminal.
- [ ] Run Neovim startup, health, formatter, Tree-sitter, and LSP checks.
- [ ] Run `cortana-services` local CI and Go tests from a clean checkout.
- [ ] Complete at least one normal work session on the canary.
- [ ] Prove per-command Homebrew rollback before continuing.

After the manager-only canary is green, repeat the isolated project matrix for
the proposed shared convergence versions. Treat activation of those versions
as a separate reviewed change.

Exit gate: all MacBook checks pass, its repositories remain clean, and Hamel
accepts the normal-work-session behavior.

### Phase 4: Mac mini interactive canary, no restart

- [ ] Fast-forward the Mac mini dotfiles checkout to the exact approved commit.
- [ ] Back up any existing `~/.config/mise` and `.zprofile` before linking or
  editing.
- [ ] Install and activate the machine-local transition config; do not link the
  shared convergence config yet.
- [ ] Install the matching tools with mise; do not remove Homebrew tools.
- [ ] Test with `mise exec`, then a fresh interactive shell.
- [ ] Re-run non-interactive, IDE, Neovim, and project checks.
- [ ] Confirm already-running services use the same binaries as the baseline.
- [ ] Run `brew services list`, `pnpm runtime:status`, and
  `pnpm runtime:doctor` without restarting anything.
- [ ] Run project and Neovim QA from isolated/clean worktrees; do not run an
  install inside the active Cortana runtime checkout.

Exit gate: interactive use is green and the existing runtime is unchanged.

### Phase 4B: Shared-version convergence

- [ ] Test the proposed shared pins through isolated `mise exec` on both Macs.
- [ ] Run the full project, Neovim, shell, and runtime matrix.
- [ ] Activate the shared pins on the MacBook first and repeat its soak.
- [ ] Activate the shared pins for Mac mini interactive use without restarting
  services.
- [ ] Only after both machines pass, back up and replace the Mac mini local
  transition config with the reviewed shared-config symlink.

Exit gate: both interactive environments use the approved shared pins and the
Mac mini runtime remains unchanged.

### Phase 5: Mac mini runtime decision and maintenance window

This phase is conditional. If LaunchAgents safely remain on an explicit
Homebrew Node 22 path, document that exception and skip the migration. If the
runtime should move to mise, stop for approval.

- [ ] Review every LaunchAgent and wrapper that starts Node or pnpm.
- [ ] Choose and document one stable launch contract.
- [ ] Prepare a one-command Homebrew fallback before restart.
- [ ] Obtain Hamel's explicit maintenance-window approval.
- [ ] Restart only the affected services.
- [ ] Run immediate runtime status, doctor, endpoint, and lane smoke checks.
- [ ] Roll back immediately if any new degradation appears.

Exit gate: runtime health matches baseline and rollback remains available.

### Phase 6: Observe, then clean up

- [ ] Recheck both machines immediately, after one hour, and the next day.
- [ ] Run `mise install` twice and confirm the second run is a no-op.
- [ ] Review `goodMorning()` and test its revised mise sub-step separately.
  Do not execute the full upgrade/cleanup function during rollout.
- [ ] Confirm no project or dotfiles drift was created.
- [ ] Unlink duplicate formulae before uninstalling them.
- [ ] Remove shared duplicates from machine Brewfiles only in a cleanup PR.
- [ ] Uninstall fallbacks only after a second explicit approval and successful
  rollback drill.
- [ ] Keep Homebrew dependencies that are still required by other formulae.

Exit gate: both machines remain green through the observation window.

### Phase 7: Reproducible bootstrap and optional editor-tool follow-up

- [ ] Add a common personal-Mac Brewfile and thin machine overlays.
- [ ] Add a dry-run/audit command that reports drift without deleting packages.
- [ ] Repair or replace `setup/mac-vm/setup-vm.sh` in a dedicated PR.
- [ ] Test a fresh-shell bootstrap twice for idempotency.
- [ ] Decide separately whether Neovim and version-sensitive editor tools should
  move from Homebrew to mise.
- [ ] If approved, migrate one editor tool family at a time and rerun the full
  Neovim QA matrix.

Exit gate: a rebuild is documented and reproducible without changing the work
Mac or Ubuntu setup.

## Expected Future File Scope

These are candidates for later implementation PRs. They are not changed by the
planning branch.

| File | Expected purpose |
| --- | --- |
| `config/mise/config.toml` | Approved shared runtime and package-manager pins. |
| `setup/mac-vm/zsh-config/functions.zsh` | Remove npm deletion and make maintenance migration-safe. |
| `setup/mac-vm/zsh-config/.zshrc` | Keep interactive activation predictable. |
| New shared profile fragment | Expose mise shims safely to non-interactive/IDE shells. |
| `setup/personal-mac/Brewfile` | Shared Homebrew baseline after runtime stabilization. |
| `setup/mac-vm/Brewfile` | MacBook-only overlay. |
| `setup/mac-mini/Brewfile` | Mac mini apps, services, libraries, and documented exceptions. |
| `README.md` and `AGENTS.md` | Final inventory, ownership rules, and recovery guidance. |

## Hard Stop Conditions

Stop and use the rollback section in [`QA.md`](QA.md) when any of these occurs:

- A dirty dotfiles or project checkout cannot be explained.
- A manager-only phase changes an effective tool version.
- Node changes major version before the Node gate is approved.
- npm or npx disappears from the mise Node installation.
- `pnpm --version` differs from the approved project version during project QA.
- A LaunchAgent depends on a path scheduled for removal.
- `pnpm ci:local`, Go tests, Neovim startup, or LSP checks regress.
- Mac mini `runtime:status` or `runtime:doctor` is worse than baseline.
- PostgreSQL, Tailscale, Hermes, or a Cortana lane becomes unhealthy.
- The Lazy lockfile or application config changes unexpectedly.
- A restart is required before its maintenance window is approved.
- Rollback fails once. Stop instead of attempting repeated live repairs.

## Definition of Done

- [ ] Both personal Macs follow the approved ownership policy.
- [ ] Shared runtime versions are pinned or an intentional exception is written.
- [ ] Interactive, non-interactive, and IDE shell checks pass on both machines.
- [ ] Neovim and project QA pass on both machines.
- [ ] Mac mini runtime health matches its baseline through the next-day check.
- [ ] No work-Mac, Ubuntu, credential, service-config, or unrelated files changed.
- [ ] Rollback was tested before any fallback was removed.
- [ ] Bootstrap documentation matches the final symlink and package state.
- [ ] Every implementation PR contains its completed QA record.
