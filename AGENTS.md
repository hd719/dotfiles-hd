# AGENTS.md

Be concise. This repository rebuilds real personal and work machines; inspect
before changing state.

`README.md` is the systems overview. Keep automation rules, machine safety
constraints, and agent workflow policy here.

## Start Every Task

1. Run `git status --short --branch`.
1. Read the runbook for the target profile.
1. Inspect both the tracked source and live destination with `readlink`, `cmp`,
   `diff`, or `find`.
1. Preserve unrelated changes and machine-owned state.

## Profile Routing

| Target                                     | Source of truth            |
| ------------------------------------------ | -------------------------- |
| MacBook Air thin client (`mac-air`)        | `hosts/mac-air/README.md`  |
| Standalone development MacBook (`mac-pro`) | `hosts/mac-pro/README.md`  |
| Personal Mac mini (`mac-mini`)             | `hosts/mac-mini/README.md` |
| Resilience work Mac (`mac-work`)           | `hosts/mac-work/README.md` |

`config/` holds portable configuration and must not be reorganized casually.
`chezmoi/` owns approved user-config delivery and rollback. `hosts/` owns
host-specific provisioning, lifecycle, maintenance, doctors, and runbooks.

## Change Safety

- Change only the requested profile and files.
- Back up every Chezmoi-managed target in its timestamped, mode-`0700` backup
  before apply. Keep profile-owned operational backup formats where documented.
- Verify each link with `readlink` plus `test -e` and `test -L`.
- Update the matching inventory when link ownership changes.
- Never copy or replace credentials, Git/SSH/GitHub auth, certificates,
  1Password/Doppler/AWS state, Docker data, or application databases.
- Never bypass company policy or device management.
- Never start, stop, restart, reload, or migrate production services without
  explicit approval.
- Do not commit or push unless Hamel asks.
- Agent-authored `dotfiles-hd` changes may be committed and pushed from a
  development-Mac branch or worktree only as `arbiter-hd`, through
  `github.com-arbiter` directly to `hd719/dotfiles-hd`. Never push agent work
  as `hd719`.
- Default development to the native `mac-pro` MacBook. The Mac mini remains
  a runtime host unless Hamel explicitly selects isolated development there.
  Agent GitHub writes use `arbiter-hd` on the development Mac and `cortana-hd`
  on explicitly selected Mac mini checkouts. Verify the actor before each write.
- Canonical coding prompt sources live under
  `/Users/hameldesai/Developer/hd/Knowledge/prompts/coding/` in the development
  Mac vault. Edit them there, then run the vault's `sync-coding-prompts` workflow.
  Managed local-Mac rules and remote prompt trees are deployment targets; do not
  edit them as independent machine-local copies.

If Hamel explicitly asks for one link, create it safely. Do not expand that
request into a full-machine migration.

## Package Ownership

- Mac package policy lives only in `hosts/shared/macos/Brewfile` and the
  target profile's `hosts/*/Brewfile`.
  Do not keep generated Homebrew inventories or transitive dependency lists
  under `config/`.
- Use pnpm for dotfiles-managed global Node tools unless a profile runbook
  documents a fixed-prefix exception that preserves work-owned runtimes.
- Follow each project's declared package manager and lockfile.
- Keep npm and npx for compatibility; do not convert project package managers.
- Do not add broad upgrades, cleanup, or removals to a bootstrap repair.
- Keep Git identity and credentials machine-owned. Portable Git aliases live in
  `config/git/aliases.gitconfig`; supported profiles add only that include to
  the global Git config.

## Mac Shell Ownership

- `config/zsh/shared/` contains portable shell modules.
- `config/zsh/shared/codex-aliases.zsh` is loaded by personal Macs and Linux
  workstations, never work-only profiles.
- `config/zsh/shared/development-aliases.zsh` is loaded by full Mac
  development profiles, never the Air thin client.
- `config/zsh/mac/init.zsh` is the full Mac development interface.
- `config/zsh/mac/personal/init.zsh` adds personal development workflows.
- Full-development MacBook and Mac mini profiles load both.
- Resilience loads the shared interface plus work-owned behavior, never the
  personal layer.
- Add `config/zsh/linux/` only when multiple Linux profiles share Linux-only
  modules.
- Each profile owns plugin timing, runtimes, credentials, and its `.zshrc`
  entry point.

## Personal Macs

The MacBook Air thin client uses only:

```bash
hosts/mac-air/bootstrap.sh --dry-run
hosts/mac-air/bootstrap.sh --check
hosts/mac-air/bootstrap.sh --apply
hosts/mac-air/doctor.sh
```

Keep development repositories, Docker, databases, compilers, language
runtimes, project language servers, and project dependencies on the development
Mac or an explicitly selected isolated Mac mini checkout. On the Air, the
local editor exception is the shared Neovim `thin` profile with
Marksman for Markdown and Obsidian notes; its Tree-sitter CLI builds only the
two Markdown parsers. Herdr is available as a remote editor client.
Do not run the full `mac-pro` bootstrap on the Air thin client.

### Codex Backup and Restore

- Quit the Codex app with `⌘Q` before backup or restore. Closing its window is
  not enough. Never copy live Codex databases.
- Copy the entire `~/.codex/` directory with `rsync`, not Finder. At minimum,
  verify `sessions/`, `archived_sessions/`, `state_5.sqlite`,
  `session_index.jsonl`, and `.codex-global-state.json`.
- On a restored Mac, install Codex and sign in fresh. Preserve the new
  `auth.json` and `installation_id`; never replace them from backup.
- After backup and restore, run
  `/Applications/ChatGPT.app/Contents/Resources/codex doctor --json` from
  Ghostty. Require healthy database checks and `state.rollout_db_parity: ok`
  with zero missing, stale, duplicate, mismatched, malformed, or scan-error
  entries.
- Keep two independent copies: Guardian-Node plus Time Machine or another
  disk. A backup is incomplete until transcript and database parity checks
  pass.

Standalone full-development MacBooks use only:

```bash
hosts/shared/macos/bootstrap.sh --profile mac-pro --dry-run
hosts/shared/macos/bootstrap.sh --profile mac-pro --check
hosts/shared/macos/bootstrap.sh --profile mac-pro --apply
hosts/shared/macos/doctor.sh --profile mac-pro
```

`mac-pro` installs the complete local development toolchain through Homebrew
and mise.

Substitute `mac-mini` for a new mini. Apply only from a clean canonical clone.
The bootstrap may manage links and one marked `~/.zprofile` block; it must not
replace the rest of `.zprofile`.

For the existing production Mac mini, `--apply` requires:

1. The reviewed change is merged.
1. The MacBook rollback and reboot canary is green.
1. The post-merge Mac mini preflight is green.
1. Hamel explicitly approves the interactive apply.

Service lifecycle changes require separate approval.

## Resilience Work Mac

- Manage only Ghostty, Herdr, Hunk, Neovim, Bookokrat, Yazi, and the portable Git
  alias include.
- Use `hosts/mac-work/Brewfile` and
  `hosts/mac-work/link-terminal-editor-config.sh`.
- Never run the personal Mac bootstrap or the Mac mini Brewfile.
- Keep the live work `~/.zshrc`, `config/mise`, Git identity, work runtimes,
  credentials, certificates, and Docker state machine-owned.
- Use the runbook's pinned tools and exact seven-link inventory.
- Report every backup and policy blocker.

The Resilience linker is intentional: it is the scoped, backup-safe installer
for those seven links. Do not replace it with ad hoc `ln -s` commands.

## Preserved Zed Configuration

Zed is not installed or bootstrap-managed. Keep `config/zed` intact. Run
`config/zed/link-zed-config.sh` only when Hamel explicitly re-enables Zed.
Never link Zed prompts or application runtime state.

## Neovim Teaching Continuity

- Read `config/nvim/README.md`, `config/nvim/CURRICULUM.md`, and
  `config/nvim/LEARNING_LOG.md` first.
- Resume the first unchecked core item unless Hamel chooses another topic.
- Teach one action at a time and wait for confirmation.
- Mark only practiced, confirmed sub-lessons; keep checkboxes atomic.
- Optional deep dives never block a lesson. Add requested deep dives before
  teaching them.
- Keep the curriculum checkpoint current.
- Append every taught concept, correction, conflict, and result to the next
  numbered learning-log session. Include the mental model, unresolved issue,
  and best next lesson.
- Never rewrite old learning-log entries or claim unperformed practice.

The goal is confident Neovim reasoning, not unexplained key memorization.

## Verification

Run checks that match the changed surface:

```bash
git diff --check
bash /Users/hameldesai/.codex/skills/dotfiles-sync/tests/sync-dotfiles-test.sh
bash hosts/tests/run.sh
```

Run `mdformat --check` on changed Markdown files. For shell changes, run
`bash -n` or `zsh -n` on edited scripts and verify behavior in a fresh login
shell with `zsh -lic '<check>'`.
