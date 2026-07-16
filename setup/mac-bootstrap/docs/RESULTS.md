# PR #9 QA Results

- Date: 2026-07-15
- Operator: Codex
- Branch: `agent/plan-personal-mac-mise-standardization`
- Host used for local QA: Apple Silicon, macOS 26.5.2
- Tested implementation commit:
  `6e3e9e2ef8c3ff473fd902df4beea884096f8467`
- Actual-tool isolated home (ephemeral):
  `/tmp/dotfiles-clean-home-qa-final.YfsTmx`
- Durable sanitized evidence:
  `~/.local/state/dotfiles-hd/mise-standardization/20260715-mac-bootstrap-clean-home-6e3e9e2`
- Status: review-ready; **not merge-ready until the live MacBook rollback and
  reboot substitute gate below passes**

## Passed

- Shell syntax, StyLua, whitespace, and all three Brewfile parse checks.
- 141 temporary-home bootstrap assertions, including dry-run purity, profile
  selection, backups, idempotency, legacy `.zprofile` marker migration,
  rollback, protected-state preservation, installer failures, legacy npm-layout
  migration, exact pinned pnpm execution, Go version detection, and Lazy
  lockfile preservation.
- An actual-tool temporary-home run using Homebrew, mise, uv, pnpm, and Neovim:
  - two applies completed without an additional backup;
  - protected SSH, Herdr, Zed, and tmux sentinels were unchanged;
  - `lazy-lock.json` was unchanged;
  - interactive and non-interactive login shells resolved Node 24.18.0, pnpm
    11.2.2, Go 1.26.3, Python 3.14.5, and Bun 1.3.14;
  - the doctor verified exact Ruff, mdformat/plugin, and pnpm-managed GraphQL
    LSP versions;
  - the pnpm-installed GraphQL LSP reported 3.5.0, the second apply skipped its
    reinstall, and `pnpm audit --prod` found no known vulnerabilities;
  - Neovim restored every exact locked plugin plus all required Tree-sitter
    parsers, started headlessly, and left `lazy-lock.json` unchanged.
- Isolated mise installs and execution for every approved runtime pin.
- `cortana-services` at detached clean commit
  `4a7d5e6182e8ce4b66962d55c71b87f93596e288` with the approved pins:
  frozen install, Node 24.18.0 `pnpm ci:local` (58 files and 149 tests), and
  Go 1.26.3 `go test ./...` all passed.
- Personal Next.js/Bun repository at commit
  `fc54e31fbd0608b909b552815a285bf62e6610f9`: Node 24.18.0 plus Bun 1.3.14
  frozen install and lint passed, and the checkout stayed clean.
- Mac mini read-only/no-restart audit: running services stayed on Homebrew Node
  22.23.1 through LaunchAgent PATH entries that prepend
  `/opt/homebrew/opt/node@22/bin`; runtime status stayed green, and no package,
  link, process, or service state changed.

## Known Pre-existing or External Limits

- The personal Next.js repository's root test command is already red because
  `@repo/logger` cannot resolve `ts-jest` and one package has no tests. Its build
  was not run with ignored local secret-bearing environment files.
- The Mac mini doctor retains one pre-existing development-log warning and one
  unrelated pre-existing LaunchAgent failure. Neither changed during this work.
- `cortana-services` hosted CI still explicitly uses Node 22. Updating that
  project workflow is outside this dotfiles PR; the complete local suite passed
  under Node 24.18.0.
- Local host preparation installed missing Homebrew `gopls` and
  `font-maple-mono-nf`, and cached mise Node 22.23.1 without activating it. No
  live dotfile link or active PATH was switched. The Node 24.18.0 rerun used a
  fresh isolated mise root at `/tmp/dotfiles-mise-qa-node24.1LfnIc`.
- No disposable Apple Silicon macOS VM is available. Hamel explicitly waived
  that gate on 2026-07-16; it is not recorded as passed. This accepts residual
  risk around a truly cold Homebrew install and replaces the VM gate with the
  live MacBook rollback and reboot canary below.

## Required Before Merge

- [x] Record Hamel's clean macOS VM waiver without representing the VM gate as
  passed.
- [ ] Preserve the existing uncommitted PLAN/QA edits in the live canonical
  checkout before switching it to the exact reviewed commit.
- [ ] Back up the live MacBook baseline, dry-run, apply the exact reviewed
  commit twice, and pass fresh shells plus the doctor.
- [ ] Prove rollback restores every path changed by the canary, then reapply
  successfully twice.
- [ ] Complete the manual MacBook app, IDE, Neovim LSP, and normal-work-session
  observation gate.
- [ ] Reboot the MacBook and repeat the doctor, shell, Neovim, project, and
  clean-Git checks.
- [ ] Hamel confirms the MacBook behaves normally and approves merge.

## Required After Merge

- [ ] Complete the Mac mini preflight, obtain Hamel's explicit approval, and run
  the interactive no-restart apply plus shell, project, Neovim, and runtime QA.
- [ ] Complete immediate, one-hour, and next-day observation on both machines;
  Hamel confirms the final post-merge gate.
- [ ] Record the post-merge evidence and completed checklist in a small QA-only
  follow-up PR.

No Mac mini restart, reload, runtime migration, cleanup, or fallback removal is
authorized by this PR.
