# Personal Mac Toolchain QA and Rollback Runbook

Use this runbook for every implementation PR from
[`PLAN.md`](PLAN.md). Do not treat it as one large migration script.

## PR #9 Completion Status

Full evidence is recorded in [`RESULTS.md`](RESULTS.md).

- [x] Bash and Zsh syntax, StyLua, whitespace, and all three Brewfiles pass.
- [x] All 141 temporary-home bootstrap assertions pass.
- [x] Actual Homebrew, mise, uv, pnpm, and Neovim clean-home QA passes twice.
- [x] The second apply is idempotent and protected files remain unchanged.
- [x] Node 24, pnpm, Go, Python, Bun, GraphQL LSP, and Neovim checks pass.
- [x] Project compatibility and `pnpm audit --prod` pass.
- [x] PR review has no remaining Critical, High, Medium, or Low findings.
- [x] GitGuardian passed on implementation head `5ae95fe` before this docs-only
  status update.
- [x] Hamel waived the unavailable clean Apple Silicon macOS VM gate on
  2026-07-16; it is not recorded as passed.
- [x] Live MacBook activation, rollback, reboot, and manual app/editor checks
  passed as the compensating pre-merge gate; the IDE-terminal gate is N/A for
  the Ghostty and Neovim daily-driver workflow.
- [x] Mac mini activation and immediate post-merge checks passed.
- [x] One-hour checks passed on both personal Macs through Everyday Mac Ops at
  10:52 EDT on 2026-07-16.
- [x] Next-day technical checks passed on both personal Macs at 07:42 EDT on
  2026-07-17 without a restart, reload, install, or runtime change.
- [ ] Hamel's final next-day normal-use confirmation remains open.

Unchecked checklists below are deliberate live-machine gates, not missing
results from the completed isolated QA.

## QA Record

Copy the pre-merge MacBook rows into PR #9. Carry the record into the QA-only
follow-up PR and complete the post-merge Mac mini and observation rows there.

| Field | Value |
| --- | --- |
| Date/time | 2026-07-16, immediate post-merge QA |
| Operator | Codex, with Hamel approving each live activation gate |
| Dotfiles commit | `429ee01b6afd00653c075e94b17a69b979ef3fe7` |
| Phase under test | Post-merge MacBook reboot and Mac mini no-restart activation |
| MacBook evidence directory | `~/.local/state/dotfiles-hd/mise-standardization/20260716-064353-post-merge-pr9-macbook` |
| Mac mini evidence directory | `~/.local/state/dotfiles-hd/mise-standardization/20260716-064935-post-merge-pr9-macmini` |
| MacBook next-day evidence | `~/.local/state/dotfiles-hd/mise-standardization/20260717-074253-next-day-pr9-macbook` |
| Mac mini next-day evidence | `~/.local/state/dotfiles-hd/mise-standardization/20260717-074253-next-day-pr9-macmini` |
| Clean macOS VM gate | Waived by Hamel on 2026-07-16; no VM available |
| Approved Node version | 24.18.0 for interactive/dev tools; Homebrew 22.23.1 remains the Mac mini service contract |
| Approved pnpm version | 11.2.2 for interactive/dev tools |
| Maintenance window approved? | `no`; none was needed or used |
| Rollback tested? | MacBook config rollback/reapply passed; Mac mini rollback ref recorded, runtime migration not performed |
| Mac mini LaunchAgent/wrapper files | Five `~/Library/LaunchAgents/ai.hermes.*.plist` files plus the recorded Cortana runtime scripts; the three gateway plists retain a deleted `22.22.3` Cellar path in `PATH` |
| Timestamped backup paths | MacBook `~/.zprofile.backup-20260716-064639` and rollback-drill backup; Mac mini destinations were absent, so no backup was created |
| Affected runtime services | None; existing Cortana, Hermes, PostgreSQL, and Tailscale services were observed only |
| Known-good Node path and version | `/opt/homebrew/opt/node@22/bin/node`, 22.23.1; three Hermes gateway plists still name the deleted `/opt/homebrew/Cellar/node@22/22.22.3/bin` path |
| Known-good pnpm path and version | `~/.local/share/mise/shims/pnpm`, 11.2.2 for fresh shells; runtime services were not migrated to pnpm |
| Exact runtime rollback command | Not invoked: services retained their explicit Homebrew Node 22 launch contract |
| Exact runtime restart/reload command | Not authorized and not run |
| Required post-rollback checks | `pnpm runtime:status` and `pnpm runtime:doctor` from a fresh login shell |

## Rules

- Run read-only baseline checks before installing or linking anything.
- Store evidence under
  `~/.local/state/dotfiles-hd/mise-standardization/<timestamp>/`.
- Do not capture `env`, tokens, credentials, or complete process environments.
- Do not run `brew cleanup`, `brew autoremove`, `brew uninstall`, or
  `brew bundle cleanup` during initial rollout.
- Do not run runtime reload/restart commands on the Mac mini without Hamel's
  explicit maintenance approval.
- Keep Homebrew Node 22 and pnpm fallbacks until the next-day gate passes and
  rollback has been proven.
- Stop on the first new regression. Record evidence before rollback.
- Plain `zsh -c` and LaunchAgents do not automatically inherit `.zprofile`.
  Record their behavior, but give them an explicit `mise exec` or fixed-path
  launch contract instead of assuming shell activation.
- A temporary `$HOME` test does not replace live validation. Because Hamel
  waived the unavailable macOS VM gate for PR #9, the live MacBook rollback and
  reboot canary below is required before merge.

## 0. Clean-machine Acceptance Evidence

The automated tier proves the bootstrap in an isolated home. Hamel waived the
disposable macOS VM tier for PR #9 on 2026-07-16 because no macOS VM is
available. The live MacBook rollback and reboot canary in section 4 replaces it
as the pre-merge gate. The Mac mini is proven separately after merge by the
preflight and no-restart gates.

### Automated local tier

From the implementation worktree:

```bash
bash -n \
  setup/mac-bootstrap/bootstrap.sh \
  setup/mac-bootstrap/doctor.sh \
  setup/mac-bootstrap/lib.sh \
  setup/mac-bootstrap/tests/bootstrap-test.sh

for zsh_file in \
  config/zsh/completions.zsh \
  config/zsh/mac/*.zsh \
  setup/mac-bootstrap/mise-shims.zsh \
  setup/mac-pro/.zshrc \
  setup/mac-mini/.zshrc \
  setup/mac-pro-resilience/.zshrc \
  setup/fedora/.zshrc; do
  zsh -n "$zsh_file"
done

setup/mac-bootstrap/tests/bootstrap-test.sh
git diff --check
```

Parse every Brewfile without updating Homebrew:

```bash
for brewfile in \
  setup/mac-bootstrap/Brewfile \
  setup/mac-pro/Brewfile \
  setup/mac-mini/Brewfile
do
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --all --file "$brewfile"
done
```

Pass criteria:

- Dry-run writes nothing.
- Missing/unknown profiles and simulated installer failures stop before links.
- Files, directories, wrong links, and broken links receive timestamped
  backups; correct links are no-ops.
- Rerunning bootstrap creates no additional backup.
- Herdr sessions, tmux plugins, SSH, and credentials are untouched.
- No command log contains upgrade, cleanup, autoremove, uninstall, SSH-key,
  restart, or credential operations.

### Optional future clean macOS tier — waived for PR #9

These steps remain useful when a disposable Apple Silicon macOS VM becomes
available, but they are not a PR #9 merge gate and must not be marked passed.
A new local user is not equivalent because it shares the host's Homebrew
installation.

1. Record the macOS version and snapshot the clean VM.
2. Confirm Homebrew, mise, and all managed links are absent.
3. Install Xcode Command Line Tools and Homebrew, complete Homebrew's printed
   shell `Next steps`, then clone the exact PR commit over HTTPS to
   `~/Developer/dotfiles-hd`.
4. Seed sentinel `.zshrc`, `.zprofile`, btop, Ghostty, and Herdr paths.
5. Run `--profile mac-pro --dry-run`; confirm zero filesystem change.
6. Run `--profile mac-pro --apply`, reboot, then run the doctor.
7. Verify exact mise versions, both shell modes, Neovim restore/startup, and a
   clean Git worktree.
8. Open Ghostty, Herdr, and Karabiner-Elements. Confirm linked settings are
   active and complete Karabiner's required macOS permissions.
9. Run apply again and prove it is a no-op.
10. Restore every seeded backup byte-for-byte, remove every managed link that
    was originally absent, rerun the baseline, then apply once more.

Required post-install commands:

```bash
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade \
  --file setup/mac-bootstrap/Brewfile
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade \
  --file setup/mac-pro/Brewfile
mise install --dry-run-code
zsh -lic 'command -v node npm npx pnpm go python bun nvim'
zsh -lc  'command -v node npm npx pnpm go python bun nvim'
nvim --headless '+Lazy! restore' '+qa'
nvim --headless '+qa!'
git status --porcelain
```

All commands must pass, the Git output must be empty, and `lazy-lock.json` must
not change.

## 1. Create an Evidence Directory

Run separately on each machine:

```bash
STAMP="$(date +%Y%m%d-%H%M%S)"
EVIDENCE="$HOME/.local/state/dotfiles-hd/mise-standardization/$STAMP"
mkdir -p "$EVIDENCE"
printf '%s\n' "$EVIDENCE"
```

Keep that shell open so `$EVIDENCE` remains set. Do not commit this directory.

## 2. Baseline Both Machines

### Machine and Git state

```bash
{
  date
  hostname
  sw_vers
  uname -m
} | tee "$EVIDENCE/machine.txt"

git -C "$HOME/Developer/dotfiles-hd" status --short --branch \
  | tee "$EVIDENCE/dotfiles-git.txt"
git -C "$HOME/Developer/dotfiles-hd" rev-parse HEAD \
  | tee "$EVIDENCE/dotfiles-commit.txt"

GOOD_COMMIT="$(git -C "$HOME/Developer/dotfiles-hd" rev-parse HEAD)"
ROLLBACK_REF="rollback/mac-bootstrap-pre-mise-$STAMP"
git -C "$HOME/Developer/dotfiles-hd" branch "$ROLLBACK_REF" "$GOOD_COMMIT"
printf '%s %s\n' "$ROLLBACK_REF" "$GOOD_COMMIT" \
  | tee "$EVIDENCE/dotfiles-rollback-ref.txt"
```

Pass criteria:

- Correct host and `arm64` are recorded.
- Dotfiles are on the expected commit.
- The worktree is clean before activation.

### Symlinks

```bash
for target in \
  "$HOME/.zshrc" \
  "$HOME/.zprofile" \
  "$HOME/.config/mise" \
  "$HOME/.config/nvim"
do
  if [[ -L "$target" ]]; then
    printf '%s -> %s\n' "$target" "$(readlink "$target")"
  elif [[ -e "$target" ]]; then
    printf '%s exists and is not a symlink\n' "$target"
  else
    printf '%s is missing\n' "$target"
  fi
done | tee "$EVIDENCE/symlinks.txt"
```

Pass criteria:

- Every existing path is classified before any replacement.
- A non-symlinked file is timestamp-backed up before editing or linking.
- MacBook mise and Neovim links point into `dotfiles-hd`.
- The Mac mini mise state matches the phase being tested.

### Homebrew and mise inventory

```bash
brew bundle dump --file "$EVIDENCE/Brewfile.before" --force
brew services list > "$EVIDENCE/brew-services.before.txt"
brew list --versions > "$EVIDENCE/brew-versions.before.txt"

mise doctor > "$EVIDENCE/mise-doctor.before.txt" 2>&1 || true
mise current > "$EVIDENCE/mise-current.before.txt" 2>&1 || true
mise ls --json > "$EVIDENCE/mise-list.before.json" \
  2> "$EVIDENCE/mise-list.before.stderr.txt" || true
/usr/bin/ruby -rjson \
  -e 'JSON.parse(File.read(ARGV.fetch(0)))' \
  "$EVIDENCE/mise-list.before.json"

nvim --headless '+checkhealth' \
  "+write! $EVIDENCE/nvim-checkhealth.before.txt" '+qa'
test -s "$EVIDENCE/nvim-checkhealth.before.txt"
```

The `|| true` is for evidence capture only. Review the files and fail the gate
for a real mise error.

### Shell path matrix

Run both modes because scripts and IDEs do not always use interactive zsh:

```bash
CHECK_TOOLS='for tool in mise node npm npx pnpm go python python3 bun nvim rg fd fzf lazygit tree-sitter lua-language-server stylua vtsls vscode-eslint-language-server bash-language-server gopls ruff mdformat; do printf "%-32s " "$tool"; command -v "$tool" || printf "MISSING\n"; done'

zsh -lic "$CHECK_TOOLS" > "$EVIDENCE/paths.interactive.before.txt" 2>&1
zsh -lc "$CHECK_TOOLS" > "$EVIDENCE/paths.noninteractive.before.txt" 2>&1
zsh -c "$CHECK_TOOLS" > "$EVIDENCE/paths.plain-script.before.txt" 2>&1

zsh -lic 'node --version; npm --version; npx --version; pnpm --version; go version; python --version; bun --version; nvim --version | head -n 1' \
  > "$EVIDENCE/versions.interactive.before.txt" 2>&1
zsh -lc 'node --version; npm --version; npx --version; pnpm --version; go version; python --version; bun --version; nvim --version | head -n 1' \
  > "$EVIDENCE/versions.noninteractive.before.txt" 2>&1 || true

GRAPHQL_LSP="$HOME/.local/graphql-lsp/bin/graphql-lsp"
if [[ -x "$GRAPHQL_LSP" ]]; then
  "$GRAPHQL_LSP" --version
else
  printf 'MISSING: %s\n' "$GRAPHQL_LSP"
fi > "$EVIDENCE/graphql-lsp.before.txt" 2>&1
```

Pass criteria after activation:

- Node, npm, npx, pnpm, Go, Python, Bun, and Neovim are present in both modes.
- Runtime paths and versions match the approved policy.
- Generic CLIs and all Neovim LSP/formatter executables remain present.
- Any intentional Mac mini runtime exception is documented, not hidden.
- `~/.local/graphql-lsp/bin/graphql-lsp` exists, is executable, and reports the
  pinned version.
- `~/.local/graphql-lsp/.pnpm-managed-version` records the exact GraphQL LSP
  and pnpm versions; no `npm install` command is used.
- Plain `zsh -c` output is recorded for comparison. Missing mise tools there
  are acceptable only when scripts and LaunchAgents use an explicit launch
  contract.

## 3. Isolated mise Test Before PATH Switch

Never test a new shared config by editing the live symlink target.

```bash
export MISE_DATA_DIR="$EVIDENCE/mise-data"
export MISE_CACHE_DIR="$EVIDENCE/mise-cache"
export MISE_STATE_DIR="$EVIDENCE/mise-state"
export MISE_TMP_DIR="$EVIDENCE/mise-tmp"
cd "$HOME"

# The doctor separately verifies the reviewed config contains these exact pins.
# --no-config prevents the live global config from merging into this install.
MISE_NO_CONFIG=1 mise install \
  node@24.18.0 pnpm@11.2.2 go@1.26.3 python@3.14.5 bun@1.3.14
MISE_NO_CONFIG=1 mise exec node@24.18.0 -- node --version
MISE_NO_CONFIG=1 mise exec node@24.18.0 -- npm --version
MISE_NO_CONFIG=1 mise exec node@24.18.0 -- npx --version
MISE_NO_CONFIG=1 mise exec node@24.18.0 pnpm@11.2.2 -- pnpm --version
MISE_NO_CONFIG=1 mise exec go@1.26.3 -- go version
MISE_NO_CONFIG=1 mise exec python@3.14.5 -- python --version
MISE_NO_CONFIG=1 mise exec bun@1.3.14 -- bun --version
```

Pass criteria:

- The worktree path is not the target of a live config symlink.
- Every command resolves to the approved version.
- npm and npx still exist after `mise install`.
- The live `~/.local/share/mise` installation and shims are unchanged.
- No tracked file outside the implementation worktree changes.

Keep these isolated mise variables for the pre-activation project tests below.
Unset all of them before testing the normal live shell.

## 4. MacBook Canary

### Project checks

Start only from a clean project checkout:

```bash
cd "$HOME/Developer/cortana-services"
git status --short --branch
MISE_NO_CONFIG=1 mise exec node@24.18.0 pnpm@11.2.2 -- \
  pnpm install --frozen-lockfile
MISE_NO_CONFIG=1 mise exec node@24.18.0 pnpm@11.2.2 -- pnpm ci:local
MISE_NO_CONFIG=1 mise exec go@1.26.3 -- go -C apps/cortana-go test ./...
git status --short
```

Pass criteria:

- The project declares and uses the approved pnpm version.
- Local CI and Go tests pass.
- No tracked project files change.

After the isolated tests, clear the isolated paths. Keep this shell open so the
evidence and rollback variables remain available:

```bash
unset MISE_DATA_DIR MISE_CACHE_DIR MISE_STATE_DIR MISE_TMP_DIR
hash -r
```

For Python and Bun, select one real existing project for each runtime and add
its command and result to the QA record. Do not invent a synthetic project that
cannot catch real compatibility problems.

### Approval-gated activation of the reviewed commit

Run only after the isolated QA is green and Hamel explicitly approves the
MacBook canary. For PR #9, this live rollback and reboot canary replaces the
waived VM gate and must pass before merge. The canonical checkout feeds live
symlinks, so switching it is an activation step. Preserve any uncommitted work
with Hamel's approval, require a clean checkout, and fill in the exact reviewed
PR #9 SHA; never test a moving branch name.

```bash
(
set -euo pipefail
DOTFILES="$HOME/Developer/dotfiles-hd"
REVIEWED_COMMIT="<full PR #9 commit SHA>"

cd "$DOTFILES"
test "$REVIEWED_COMMIT" != "<full PR #9 commit SHA>"
test -z "$(git status --porcelain)"
git fetch origin pull/9/head
test "$(git rev-parse FETCH_HEAD)" = "$REVIEWED_COMMIT"
read -r ROLLBACK_REF GOOD_COMMIT \
  < "$EVIDENCE/dotfiles-rollback-ref.txt"
test "$(git rev-parse "$ROLLBACK_REF")" = "$GOOD_COMMIT"
printf '%s\n' "$REVIEWED_COMMIT" > "$EVIDENCE/reviewed-commit.txt"

git switch --detach "$REVIEWED_COMMIT"
setup/mac-bootstrap/bootstrap.sh --profile mac-pro --dry-run
setup/mac-bootstrap/bootstrap.sh --profile mac-pro --apply
setup/mac-bootstrap/bootstrap.sh --profile mac-pro --apply

zsh -lic 'node --version; pnpm --version; go version; python --version; bun --version; nvim --version | head -n 1'
zsh -lc  'node --version; pnpm --version; go version; python --version; bun --version; nvim --version | head -n 1'
setup/mac-bootstrap/doctor.sh --profile mac-pro
test -z "$(git status --porcelain)"
)
```

All commands must pass, the final Git output must be empty, and the second
apply must create no backup. If the canary fails, move new managed links aside,
restore every recorded backup, reload `ROLLBACK_REF` and `GOOD_COMMIT` from the
evidence file, verify the ref, switch back with `git switch "$ROLLBACK_REF"`, and
run section 9. Never use `git reset --hard`.

Open a fresh Ghostty login shell before manual checks. Automated commands below
invoke their toolchain through `zsh -lic` so the pre-activation outer-shell PATH
cannot produce a false pass.

### Neovim checks

Capture the lockfile hash before and after:

```bash
cd "$HOME/Developer/dotfiles-hd"
shasum -a 256 config/nvim/lazy-lock.json \
  | tee "$EVIDENCE/nvim-lock.before.txt"

EVIDENCE="$EVIDENCE" zsh -lic '
  set -euo pipefail
  cd "$HOME/Developer/dotfiles-hd"
  stylua --check config/nvim
  nvim --headless "+lua print(vim.version().major, vim.version().minor, vim.version().patch)" "+qa"
  nvim --headless "+checkhealth" \
    "+write! $EVIDENCE/nvim-checkhealth.after.txt" "+qa"
'
test -s "$EVIDENCE/nvim-checkhealth.after.txt"
diff -u \
  "$EVIDENCE/nvim-checkhealth.before.txt" \
  "$EVIDENCE/nvim-checkhealth.after.txt" \
  > "$EVIDENCE/nvim-checkhealth.diff.txt" || true

shasum -a 256 config/nvim/lazy-lock.json \
  | tee "$EVIDENCE/nvim-lock.after.txt"
diff -u "$EVIDENCE/nvim-lock.before.txt" "$EVIDENCE/nvim-lock.after.txt"
git status --short
```

Manual checks:

- [x] Open a Lua file: LuaLS attaches and formatting works.
- [x] Open a shell file: Bash LSP attaches.
- [x] Open a TypeScript/TSX file: vtsls and ESLint resolve as configured.
- [x] Open a Go file: gopls attaches.
- [x] Open a GraphQL file: the pinned GraphQL LSP attaches from
  `~/.local/graphql-lsp/bin/graphql-lsp`.
- [x] Open Markdown: mdformat is available through Conform.
- [x] Tree-sitter highlighting works in each tested language.
- [x] `Space f`, `Space /`, Oil, LazyGit, and split navigation open normally.

Pass criteria:

- Headless startup and formatting check pass.
- The health file is nonempty and its diff has no new error caused by the
  toolchain change.
- `lazy-lock.json` and the dotfiles worktree remain unchanged.

### MacBook observation gate

- [x] Fresh Ghostty window works.
- N/A: an IDE terminal is outside the approved Ghostty and Neovim daily-driver
  workflow.
- [x] Herdr opens with the linked config.
- [x] Karabiner-Elements opens after required macOS permissions are granted.
- [x] One normal coding session completes.
- [x] A new terminal still reports the approved versions.
- [x] Per-command Homebrew fallback was tested.

### MacBook rollback and reboot substitute gate

Complete these steps before merging PR #9:

- [x] Restore every path changed by the canary using section 9 and prove the
  recorded baseline returns without losing user-owned content.
- [x] Reload the exact SHA from `$EVIDENCE/reviewed-commit.txt`, verify it
  against a fresh fetch of PR #9, and reapply it twice; the second apply creates
  no new backup.
- [x] Reboot the MacBook and open a fresh Ghostty login shell.
- [x] Repeat the doctor, both shell modes, Neovim checks, project checks, and
  clean-Git checks after reboot.
- [x] Hamel confirms the MacBook behaves normally.

After reboot:

```bash
EVIDENCE="<MacBook evidence directory from the QA record>"
test "$EVIDENCE" != "<MacBook evidence directory from the QA record>"
test -d "$EVIDENCE"
cd "$HOME/Developer/dotfiles-hd"
test "$(git rev-parse HEAD)" = "$(cat "$EVIDENCE/reviewed-commit.txt")"
setup/mac-bootstrap/doctor.sh --profile mac-pro
zsh -lic 'node --version; pnpm --version; go version; python --version; bun --version; nvim --version | head -n 1'
zsh -lc  'node --version; pnpm --version; go version; python --version; bun --version; nvim --version | head -n 1'
nvim --headless '+qa!'
git status --short
```

Do not merge until Hamel confirms this gate. Start the Mac mini preflight only
after PR #9 is merged.

## 5. Post-merge Mac mini Preflight

Run from the MacBook unless already connected:

```bash
ssh mac-mini-ts
```

On the Mac mini, rerun sections 1 and 2 first. Create a mini-local evidence
directory and rollback ref; do not reuse the MacBook shell's variables. Then:

```bash
(
set -euo pipefail
cd "$HOME/Developer/dotfiles-hd"
git status --short --branch

cd "$HOME/Developer/cortana-services"
git status --short --branch
pnpm runtime:status | tee "$EVIDENCE/runtime-status.before.txt"
pnpm runtime:doctor | tee "$EVIDENCE/runtime-doctor.before.txt"

brew services list > "$EVIDENCE/brew-services.runtime-before.txt"
pg_isready > "$EVIDENCE/postgres.before.txt" 2>&1 || true
tailscale status > "$EVIDENCE/tailscale.before.txt" 2>&1 || true
)
```

Capture executable paths without dumping arguments or process environments:

```bash
for pid in $(pgrep -f 'node|pnpm|cortana|hermes'); do
  ps -p "$pid" -o pid=,comm=
  lsof -a -p "$pid" -d txt -Fn 2>/dev/null | sed -n 's/^n//p'
done | tee "$EVIDENCE/runtime-executables.before.txt"
```

Also inspect the actual LaunchAgent and wrapper command paths. If any path
points at a Homebrew runtime scheduled for removal, stop. Record the file and
path in the QA record.

Pass criteria:

- Both repositories are in the expected clean state.
- Runtime status and doctor have no new warning or failure.
- PostgreSQL, Tailscale, Hermes, and Cortana services match baseline.
- The process and LaunchAgent path inventory is understood.
- Every Mac mini rollback field in the QA record is filled before a maintenance
  window can be approved.

## 6. Post-merge Mac mini Interactive Activation, No Restart

Do not run this section until PR #9 is merged, the MacBook canary is green, and
Hamel approves the Mac mini interactive step. Preview the merged profile
first; its apply path backs up existing destinations and links the shared
config without starting or restarting services. Fill in and verify the exact
merged `master` SHA; never apply a moving branch name.

```bash
(
set -euo pipefail
MERGED_COMMIT="<full merged master SHA>"
cd "$HOME/Developer/dotfiles-hd"
test "$MERGED_COMMIT" != "<full merged master SHA>"
test -z "$(git status --porcelain)"
git fetch origin master
test "$(git rev-parse FETCH_HEAD)" = "$MERGED_COMMIT"
read -r ROLLBACK_REF GOOD_COMMIT \
  < "$EVIDENCE/dotfiles-rollback-ref.txt"
test "$(git rev-parse "$ROLLBACK_REF")" = "$GOOD_COMMIT"
printf '%s\n' "$MERGED_COMMIT" > "$EVIDENCE/merged-commit.txt"
git switch master
git merge --ff-only "$MERGED_COMMIT"
test "$(git rev-parse HEAD)" = "$MERGED_COMMIT"

setup/mac-bootstrap/bootstrap.sh --profile mac-mini --dry-run
setup/mac-bootstrap/bootstrap.sh --profile mac-mini --apply
setup/mac-bootstrap/bootstrap.sh --profile mac-mini --apply
readlink "$HOME/.config/mise"
test -f "$HOME/.config/mise/config.toml"
mise config
mise install
setup/mac-bootstrap/doctor.sh --profile mac-mini
test -z "$(git status --porcelain)"
)
```

Stop if `mise config` lists an unexpected file or any interactive version
differs from the approved shared table in `PLAN.md`. The bootstrap marker-edits
`.zprofile`; it does not replace or symlink the whole profile.

```bash
CHECK_TOOLS='for tool in mise node npm npx pnpm go python python3 bun nvim rg fd fzf lazygit tree-sitter lua-language-server stylua vtsls vscode-eslint-language-server bash-language-server gopls ruff mdformat; do printf "%-32s " "$tool"; command -v "$tool" || printf "MISSING\n"; done'

zsh -lic "$CHECK_TOOLS" > "$EVIDENCE/paths.interactive.after.txt" 2>&1
zsh -lc "$CHECK_TOOLS" > "$EVIDENCE/paths.noninteractive.after.txt" 2>&1
zsh -c "$CHECK_TOOLS" > "$EVIDENCE/paths.plain-script.after.txt" 2>&1
```

Open a second, fresh SSH login session after activation and reload the recorded
mini evidence path there. Run the project checks from a disposable worktree at
the same Cortana commit; never install dependencies into the active runtime
checkout. Run the Neovim checks from section 4 on the Mac mini as well. If a
second session is unavailable, wrap every post-activation tool command in
`zsh -lic`. Record both results in the final sign-off table.

Without restarting anything, repeat:

```bash
(
set -euo pipefail
cd "$HOME/Developer/cortana-services"
pnpm runtime:status | tee "$EVIDENCE/runtime-status.no-restart.txt"
pnpm runtime:doctor | tee "$EVIDENCE/runtime-doctor.no-restart.txt"
brew services list > "$EVIDENCE/brew-services.no-restart.txt"
for pid in $(pgrep -f 'node|pnpm|cortana|hermes'); do
  ps -p "$pid" -o pid=,comm=
  lsof -a -p "$pid" -d txt -Fn 2>/dev/null | sed -n 's/^n//p'
done > "$EVIDENCE/runtime-executables.no-restart.txt"
)
```

Pass criteria:

- Interactive and non-interactive login shells pass the path matrix.
- Existing runtime process paths match the baseline.
- No service was restarted.
- Runtime health is unchanged.

## 7. Optional Mac mini Maintenance Window

Default: do not run this section.

Prerequisites:

- [ ] Hamel explicitly approved the window.
- [ ] The exact services affected are listed.
- [ ] The launch contract is reviewed.
- [ ] All exact rollback fields in the QA record are filled and reviewed.
- [ ] Homebrew Node 22 and pnpm remain installed.
- [ ] The rollback command was tested in a non-production shell.
- [ ] The pre-restart runtime doctor is green.

Use the runtime's documented reload command only after approval. Immediately
afterward, run:

```bash
(
set -euo pipefail
cd "$HOME/Developer/cortana-services"
pnpm runtime:status | tee "$EVIDENCE/runtime-status.after-restart.txt"
pnpm runtime:doctor | tee "$EVIDENCE/runtime-doctor.after-restart.txt"
brew services list > "$EVIDENCE/brew-services.after-restart.txt"
for pid in $(pgrep -f 'node|pnpm|cortana|hermes'); do
  ps -p "$pid" -o pid=,comm=
  lsof -a -p "$pid" -d txt -Fn 2>/dev/null | sed -n 's/^n//p'
done > "$EVIDENCE/runtime-executables.after-restart.txt"
)
```

Run the existing prod/dev lane smoke procedure from the Cortana runtime
runbook. Do not substitute an unreviewed command here.

Pass criteria:

- Status and doctor are at least as healthy as baseline.
- Both lanes pass their existing smoke checks.
- PostgreSQL, Tailscale, Hermes, and dependent services are healthy.
- Process paths match the approved launch contract.

Any failure triggers immediate rollback.

## 8. Idempotency and Observation

Do not run the full `goodMorning()` function during rollout because it performs
unrelated Zoom, Downloads, `.DS_Store`, and cache housekeeping. Its former
broad Homebrew upgrade/cleanup steps are removed by this PR. Test mise directly
with the commands below and separately verify that npm and npx remain present.

On both machines:

```bash
(
set -euo pipefail
mise install | tee "$EVIDENCE/mise-install.first.txt"
mise install | tee "$EVIDENCE/mise-install.second.txt"
mise which npm
mise which npx
git -C "$HOME/Developer/dotfiles-hd" status --short --branch \
  | tee "$EVIDENCE/dotfiles-git.after.txt"
)
```

Observation checklist:

| Time | MacBook shell/toolchain/Neovim | Mac mini shell/runtime/doctor | Result |
| --- | --- | --- | --- |
| Immediate | [x] | [x] | Passed 2026-07-16; evidence paths are in the QA record |
| One hour | [x] | [x] | Everyday Mac Ops passed shell, toolchain, Neovim, and runtime health at 10:52 EDT on 2026-07-16 |
| Next day | [x] | [x] | Shells, Git, Neovim, and the Mac mini runtime passed at 07:42 EDT on 2026-07-17; no machine state changed |

Pass criteria:

- The second mise install makes no unexpected change.
- Both Git worktrees remain clean.
- No runtime, editor, shell, or service regression appears.
- No fallback is removed before the next-day check.

## 9. Rollback

### Immediate command fallback

Use explicit paths while diagnosing shell activation:

```bash
/opt/homebrew/bin/node --version
/opt/homebrew/bin/pnpm --version
/opt/homebrew/bin/nvim --version
```

The unversioned Homebrew Node path above is only a generic interactive-shell
fallback. On the Mac mini, production services must use the pinned Node 22 opt
prefix:

```bash
/opt/homebrew/opt/node@22/bin/node --version
```

### Config rollback

1. Stop affected interactive work. Do not delete the failed evidence.
2. For every managed destination that had a backup, move the new symlink aside
   and restore the timestamped backup. For every destination originally absent,
   move the newly created symlink aside so the path is absent again.
3. Restore the timestamped `.zprofile` backup. If bootstrap created the file,
   move that new file aside instead; never delete user-owned content outside
   the marked block.
4. Return the live dotfiles checkout to the recorded known-good commit or
   rollback branch with `git switch`. Do not use `git reset --hard`. If the
   worktree is dirty, stop for review rather than forcing the switch.
5. Start a fresh login shell.
6. Verify Homebrew fallback paths and versions.
7. Run the shell, project, Neovim, and runtime baseline checks again.

Config rollback leaves installed packages, mise runtimes, and tool caches in
place. Uninstall and cleanup are deliberately outside this PR.

Typical post-rollback verification:

```bash
exec zsh -l
command -v node pnpm go python3 nvim
node --version
pnpm --version
```

### Mac mini runtime rollback

Use the previously recorded launch contract to point the affected service back
to Homebrew Node 22 and the exact known-good pnpm executable, then use the
runtime's documented restart/reload command. Do not assume
`/opt/homebrew/bin/pnpm` is `11.2.2`; verify the recorded path and version.

After rollback:

```bash
cd "$HOME/Developer/cortana-services"
pnpm runtime:status
pnpm runtime:doctor
```

Stop after one failed rollback attempt. Preserve logs and ask for review rather
than stacking more live changes.

## 10. Final Sign-off

- [x] The unavailable clean macOS VM is explicitly waived for PR #9; no VM
  result is represented as passed.

MacBook rows through the reboot check were required before merge. The technical
next-day observation passed; Hamel's final normal-use confirmation remains open.

| Gate | MacBook | Mac mini | Timing/evidence |
| --- | --- | --- | --- |
| Clean baseline | [x] | [x] | Evidence directories in the QA record |
| Symlinks verified | [x] | [x] | Doctor and link inventories |
| Interactive shell | [x] | [x] | Approved path/version matrix |
| Non-interactive shell | [x] | [x] | Approved path/version matrix |
| IDE terminal | N/A | N/A | Ghostty and Neovim are the approved daily-driver workflow |
| Approved versions | [x] | [x] | Node 24.18.0, pnpm 11.2.2, Go 1.26.3, Python 3.14.5, Bun 1.3.14 |
| Project QA | [x] | [x] | Disposable Cortana clones; active checkout untouched |
| Neovim QA | [x] | [x] | Locked plugins/parsers, StyLua, headless startup, lockfile unchanged |
| Services unchanged/healthy | N/A | [x] | Status and PIDs unchanged; service Node remains 22.23.1 |
| Runtime doctor | N/A | [x] | Same one pre-existing dev-log warning |
| Rollback proven | [x] | N/A | Mac mini runtime was not migrated; fallback remains installed |
| Idempotent second apply | [x] | [x] | No new backup; GraphQL LSP fast path used |
| Reboot check | [x] | N/A | MacBook post-reboot QA passed |
| One-hour check | [x] | [x] | Everyday Mac Ops passed at 10:52 EDT on 2026-07-16 |
| Next-day check | [x] | [x] | Technical gate passed at 07:42 EDT on 2026-07-17; evidence paths are in the QA record |
| Worktrees clean | [x] | [x] | Both dotfiles repos and active Cortana checkout clean |

Final approval:

- [x] Hamel confirmed both machines worked normally during immediate and
  one-hour observation.
- [ ] Hamel confirms both machines worked normally through the next-day
  observation.
- [x] No fallback tool is removed until a separate cleanup PR is approved.
- [x] Final symlink, version, exception, and bootstrap state is documented.
