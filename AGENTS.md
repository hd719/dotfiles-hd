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

| Target                                     | Source of truth                      |
| ------------------------------------------ | ------------------------------------ |
| Thin personal MacBook (`mac-thin`)         | `hosts/mac-thin/README.md`           |
| Standalone development MacBook (`mac-pro`) | `hosts/mac-pro/README.md`             |
| Personal Mac mini (`mac-mini`)             | `hosts/mac-mini/README.md`            |
| Resilience work Mac (`mac-work`)           | `hosts/mac-work/README.md`            |
| Ubuntu workstation                         | `hosts/ubuntu-dev/README.md`          |

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
- `dotfiles-hd` is the thin-Mac PR exception: agent-authored dotfiles changes
  may be committed and pushed from a thin-Mac branch or worktree only as
  `arbiter-hd`, through `github.com-arbiter` directly to `hd719/dotfiles-hd`.
  Never push agent work as `hd719`.
- Other development repositories remain Ubuntu-first and use `arbiter-hd`.
  From the Mac mini, use `cortana-hd` only for explicitly selected or
  Mac-mini-owned work; otherwise sync reviewed `master` only.
- New development repositories must not be created, cloned, or worked from the
  thin Mac. Use Ubuntu by default, or the Mac mini when Hamel explicitly selects
  it or the repo is Mac-mini-owned. Agent PRs use `arbiter-hd` from Ubuntu or
  `cortana-hd` from the Mac mini.
- Canonical coding prompt sources live under
  `/Users/hameldesai/Developer/hd/Knowledge/prompts/coding/` in the thin Mac
  vault. Edit them there, then run the vault's `sync-coding-prompts` workflow.
  Managed thin-Mac rules and remote prompt trees are deployment targets; do not
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
- `config/zsh/shared/development-aliases.zsh` is loaded by Ubuntu and full Mac
  development profiles, never the thin Mac.
- `config/zsh/mac/init.zsh` is the full Mac development interface.
- `config/zsh/mac/personal/init.zsh` adds personal development workflows.
- MacBook and Mac mini profiles load both.
- Resilience loads the shared interface plus work-owned behavior, never the
  personal layer.
- Ubuntu keeps profile-specific shell behavior under `hosts/ubuntu-dev/`.
- Add `config/zsh/linux/` only when multiple Linux profiles share Linux-only
  modules.
- Each profile owns plugin timing, runtimes, credentials, and its `.zshrc`
  entry point.

## Personal Macs

The restored thin MacBook uses only:

```bash
hosts/mac-thin/bootstrap.sh --dry-run
hosts/mac-thin/bootstrap.sh --check
hosts/mac-thin/bootstrap.sh --apply
hosts/mac-thin/doctor.sh
```

Keep development repositories, Docker, databases, compilers, language
runtimes, project language servers, and project dependencies inside the Linux
VMs. The only local editor exception is the shared Neovim `thin` profile with
Marksman for Markdown and Obsidian notes; its Tree-sitter CLI builds only the
two Markdown parsers. Herdr may run only as a thin client for the Ubuntu Herdr
server. Do not run the full `mac-pro` bootstrap on the thin host.

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
and mise. It owns no Vagrant, VMware Fusion, or Ubuntu VM lifecycle.

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

- Manage only Ghostty, Herdr, Hunk, Neovim, Bookokrat, and the portable Git
  alias include.
- Use `hosts/mac-work/Brewfile` and
  `hosts/mac-work/link-terminal-editor-config.sh`.
- Never run the personal Mac bootstrap or the Mac mini Brewfile.
- Keep the live work `~/.zshrc`, `config/mise`, Git identity, work runtimes,
  credentials, certificates, and Docker state machine-owned.
- Use the runbook's pinned tools and exact five-link inventory.
- Report every backup and policy blocker.

The Resilience linker is intentional: it is the scoped, backup-safe installer
for those five links. Do not replace it with ad hoc `ln -s` commands.

## Ubuntu

Follow `hosts/ubuntu-dev/README.md`. Vagrant owns the VM lifecycle, guest-local
Ansible owns system setup, mise owns development tools, and dotfiles owns user
links. Use `hosts/ubuntu-dev/GUIDE.md` for Mac-to-Ubuntu teaching and keep its
commands aligned with the supported workstation.

- Keep `~/.gitconfig` machine-owned. Hunk is the shared diff viewer through
  `hdiff`; do not install `diff-so-fancy` or set a profile-owned `GIT_PAGER`.
- Set `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE` before sourcing zsh-autosuggestions.
  Ghostty's Nord palette color 8 is too close to its background; preserve the
  tracked higher-contrast color unless the shared terminal palette changes.
- GitHub `hd719`, Arbiter, and Forgejo must use three separate VM-local
  Ed25519 keys. Generate them once, never overwrite them during provisioning,
  and never copy Git private keys from the Mac.
- Keep plain `github.com` pinned to the local `hd719` key and reserve
  `github.com-arbiter` for the local Arbiter key.
- Keep GitHub CLI authenticated as `arbiter-hd`; dotfiles agent branches push
  through `github.com-arbiter` directly to `hd719/dotfiles-hd`.
- Use `ubuntu-vm-ts` as the primary Codex route to Tailscale node `ubuntu-dev`.
  Keep `ubuntu-vm` as the loopback-only Vagrant fallback. Both must disable Mac
  agent forwarding and enforce SSH host-key checking.
- Keep Ubuntu mise-managed CLI and editor tools on their latest available
  releases. Keep Node, Go, Python, and Bun on reviewed exact versions. Codex
  desktop starts Codex through the remote login shell, where `codex` must be
  on `PATH`. Preserve the issue 25 forwarded-socket wrapper as a compatibility
  guard even though the normal Vagrant routes do not forward an agent.

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
bash hosts/ubuntu-dev/doctor.sh
```

Run `mdformat --check` on changed Markdown files. For shell changes, run
`bash -n` or `zsh -n` on edited scripts and verify behavior in a fresh login
shell with `zsh -lic '<check>'`.
