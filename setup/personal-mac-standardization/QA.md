# Personal Mac Toolchain QA and Rollback Runbook

Use this runbook for every implementation PR from
[`PLAN.md`](PLAN.md). Do not treat it as one large migration script.

## QA Record

Copy this table into the implementation PR and fill every row.

| Field | Value |
| --- | --- |
| Date/time | |
| Operator | |
| Dotfiles commit | |
| Phase under test | |
| MacBook evidence directory | |
| Mac mini evidence directory | |
| Approved Node version | |
| Approved pnpm version | |
| Maintenance window approved? | `no` by default |
| Rollback tested? | |
| Mac mini LaunchAgent/wrapper files | |
| Timestamped backup paths | |
| Affected runtime services | |
| Known-good Node path and version | |
| Known-good pnpm path and version | |
| Exact runtime rollback command | |
| Exact runtime restart/reload command | |
| Required post-rollback checks | |

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
ROLLBACK_REF="rollback/personal-mac-pre-mise-$STAMP"
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
- Plain `zsh -c` output is recorded for comparison. Missing mise tools there
  are acceptable only when scripts and LaunchAgents use an explicit launch
  contract.

## 3. Isolated mise Test Before PATH Switch

Never test a new shared config by editing the live symlink target.

```bash
IMPLEMENTATION_WORKTREE="$HOME/Developer/dotfiles-hd-mise-standardization"
# Point this at the reviewed transition or convergence config for this phase.
TEST_MISE_CONFIG="$IMPLEMENTATION_WORKTREE/config/mise/config.toml"

export MISE_GLOBAL_CONFIG_FILE="$TEST_MISE_CONFIG"
export MISE_CEILING_PATHS="$HOME"
export MISE_DATA_DIR="$EVIDENCE/mise-data"
export MISE_CACHE_DIR="$EVIDENCE/mise-cache"
export MISE_STATE_DIR="$EVIDENCE/mise-state"
export MISE_TMP_DIR="$EVIDENCE/mise-tmp"
cd "$HOME"

# Stop here unless this lists only the test config and expected local files.
mise config

# Installation is isolated from the live mise data, cache, state, and shims.
mise install
mise exec -- node --version
mise exec -- npm --version
mise exec -- npx --version
mise exec -- pnpm --version
mise exec -- go version
mise exec -- python --version
mise exec -- bun --version
```

Pass criteria:

- The worktree path is not the target of a live config symlink.
- `mise config` lists the isolated global config and only expected local files.
- Every command resolves to the candidate version.
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
mise config | tee "$EVIDENCE/cortana-mise-config.txt"
mise exec -- pnpm install --frozen-lockfile
mise exec -- pnpm ci:local
mise exec -- go -C apps/cortana-go test ./...
git status --short
```

Pass criteria:

- The project declares and uses the approved pnpm version.
- Local CI and Go tests pass.
- No tracked project files change.

After the isolated tests, return to normal discovery before live-shell QA:

```bash
unset MISE_GLOBAL_CONFIG_FILE MISE_CEILING_PATHS
unset MISE_DATA_DIR MISE_CACHE_DIR MISE_STATE_DIR MISE_TMP_DIR
exec zsh -l
```

For Python and Bun, select one real existing project for each runtime and add
its command and result to the QA record. Do not invent a synthetic project that
cannot catch real compatibility problems.

### Neovim checks

Capture the lockfile hash before and after:

```bash
cd "$HOME/Developer/dotfiles-hd"
shasum -a 256 config/nvim/lazy-lock.json \
  | tee "$EVIDENCE/nvim-lock.before.txt"

stylua --check config/nvim
nvim --headless '+lua print(vim.version().major, vim.version().minor, vim.version().patch)' '+qa'
nvim --headless '+checkhealth' \
  "+write! $EVIDENCE/nvim-checkhealth.after.txt" '+qa'
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

- [ ] Open a Lua file: LuaLS attaches and formatting works.
- [ ] Open a shell file: Bash LSP attaches.
- [ ] Open a TypeScript/TSX file: vtsls and ESLint resolve as configured.
- [ ] Open a Go file: gopls attaches.
- [ ] Open a GraphQL file: the pinned GraphQL LSP attaches from
  `~/.local/graphql-lsp/bin/graphql-lsp`.
- [ ] Open Markdown: mdformat is available through Conform.
- [ ] Tree-sitter highlighting works in each tested language.
- [ ] `Space f`, `Space /`, Oil, LazyGit, and split navigation open normally.

Pass criteria:

- Headless startup and formatting check pass.
- The health file is nonempty and its diff has no new error caused by the
  toolchain change.
- `lazy-lock.json` and the dotfiles worktree remain unchanged.

### MacBook observation gate

- [ ] Fresh Ghostty window works.
- [ ] Fresh IDE terminal works.
- [ ] One normal coding session completes.
- [ ] A new terminal still reports the approved versions.
- [ ] Per-command Homebrew fallback was tested.

Do not continue to the Mac mini until Hamel confirms this gate.

## 5. Mac mini Preflight

Run from the MacBook unless already connected:

```bash
ssh mac-mini-ts
```

On the Mac mini:

```bash
cd "$HOME/Developer/dotfiles-hd"
git status --short --branch

cd "$HOME/Developer/cortana-services"
git status --short --branch
pnpm runtime:status | tee "$EVIDENCE/runtime-status.before.txt"
pnpm runtime:doctor | tee "$EVIDENCE/runtime-doctor.before.txt"

brew services list > "$EVIDENCE/brew-services.runtime-before.txt"
pg_isready > "$EVIDENCE/postgres.before.txt" 2>&1 || true
tailscale status > "$EVIDENCE/tailscale.before.txt" 2>&1 || true
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

## 6. Mac mini Manager-only Activation, No Restart

During the manager-only phase, use the reviewed machine-local transition
config. It must preserve the Mac mini's effective versions and must not be a
symlink to the shared convergence config.

Back up the existing destination before the reviewed transition-config
installer writes anything. Then verify:

```bash
test ! -L "$HOME/.config/mise"
test -f "$HOME/.config/mise/config.toml"
mise config
mise install
mise doctor
```

Stop if `mise config` lists an unexpected file or if any effective version
differs from the Mac mini transition table in `PLAN.md`.

Back up `.zprofile` separately before a marker-owned edit. Do not replace or
symlink the whole profile.

```bash
CHECK_TOOLS='for tool in mise node npm npx pnpm go python python3 bun nvim rg fd fzf lazygit tree-sitter lua-language-server stylua vtsls vscode-eslint-language-server bash-language-server gopls ruff mdformat; do printf "%-32s " "$tool"; command -v "$tool" || printf "MISSING\n"; done'

zsh -lic "$CHECK_TOOLS" > "$EVIDENCE/paths.interactive.after.txt" 2>&1
zsh -lc "$CHECK_TOOLS" > "$EVIDENCE/paths.noninteractive.after.txt" 2>&1
zsh -c "$CHECK_TOOLS" > "$EVIDENCE/paths.plain-script.after.txt" 2>&1
```

Run the project checks from a disposable worktree at the same Cortana commit;
never install dependencies into the active runtime checkout. Run the Neovim
checks from section 4 on the Mac mini as well. Record both results in the final
sign-off table.

Without restarting anything, repeat:

```bash
cd "$HOME/Developer/cortana-services"
pnpm runtime:status | tee "$EVIDENCE/runtime-status.no-restart.txt"
pnpm runtime:doctor | tee "$EVIDENCE/runtime-doctor.no-restart.txt"
brew services list > "$EVIDENCE/brew-services.no-restart.txt"
for pid in $(pgrep -f 'node|pnpm|cortana|hermes'); do
  ps -p "$pid" -o pid=,comm=
  lsof -a -p "$pid" -d txt -Fn 2>/dev/null | sed -n 's/^n//p'
done > "$EVIDENCE/runtime-executables.no-restart.txt"
```

Pass criteria:

- Interactive and non-interactive login shells pass the path matrix.
- Existing runtime process paths match the baseline.
- No service was restarted.
- Runtime health is unchanged.

## 6B. Mac mini Shared-convergence Activation

Do not run this section until manager-only section 6 is green and the separate
Phase 4B convergence change is approved. Use the repository's reviewed
backup-and-link pattern. It moves the machine-local transition config to a
timestamped backup beside the original path, then verifies the shared link:

```bash
DOTFILES="$HOME/Developer/dotfiles-hd"
SOURCE="$DOTFILES/config/mise"
DEST="$HOME/.config/mise"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [[ -L "$DEST" && "$(readlink "$DEST")" == "$SOURCE" ]]; then
  printf 'already linked: %s -> %s\n' "$DEST" "$SOURCE"
else
  if [[ -e "$DEST" || -L "$DEST" ]]; then
    mv "$DEST" "$DEST.backup-$STAMP"
  fi
  ln -s "$SOURCE" "$DEST"
fi

readlink "$DEST"
test -f "$DEST/config.toml"
```

Then rerun the shell, project, Neovim, no-restart runtime, and observation
checks from sections 4, 6, and 8. The shared link is accepted only if the full
matrix is green on both machines.

```bash
readlink "$HOME/.config/mise"
test -f "$HOME/.config/mise/config.toml"
mise install
mise doctor
```

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
cd "$HOME/Developer/cortana-services"
pnpm runtime:status | tee "$EVIDENCE/runtime-status.after-restart.txt"
pnpm runtime:doctor | tee "$EVIDENCE/runtime-doctor.after-restart.txt"
brew services list > "$EVIDENCE/brew-services.after-restart.txt"
for pid in $(pgrep -f 'node|pnpm|cortana|hermes'); do
  ps -p "$pid" -o pid=,comm=
  lsof -a -p "$pid" -d txt -Fn 2>/dev/null | sed -n 's/^n//p'
done > "$EVIDENCE/runtime-executables.after-restart.txt"
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

Do not run the full `goodMorning()` function during rollout because it includes
Homebrew upgrade, cleanup, and autoremove. Test the reviewed mise portion with
the commands below and separately verify that npm and npx remain present.

On both machines:

```bash
mise install | tee "$EVIDENCE/mise-install.first.txt"
mise install | tee "$EVIDENCE/mise-install.second.txt"
mise which npm
mise which npx
git -C "$HOME/Developer/dotfiles-hd" status --short --branch \
  | tee "$EVIDENCE/dotfiles-git.after.txt"
```

Observation checklist:

| Time | MacBook shell/project/Neovim | Mac mini shell/runtime/doctor | Result |
| --- | --- | --- | --- |
| Immediate | [ ] | [ ] | |
| One hour | [ ] | [ ] | |
| Next day | [ ] | [ ] | |

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

On the Mac mini, Homebrew Node 22 may instead resolve under its opt prefix:

```bash
/opt/homebrew/opt/node@22/bin/node --version
```

### Config rollback

1. Stop affected interactive work. Do not delete the failed evidence.
2. Restore the timestamped `.zprofile` or mise path backup.
3. Return the live dotfiles checkout to the recorded known-good commit or
   rollback branch with `git switch`. Do not use `git reset --hard`. If the
   worktree is dirty, stop for review rather than forcing the switch.
4. Start a fresh login shell.
5. Verify Homebrew fallback paths and versions.
6. Run the shell, project, Neovim, and runtime baseline checks again.

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

| Gate | MacBook | Mac mini | Evidence/notes |
| --- | --- | --- | --- |
| Clean baseline | [ ] | [ ] | |
| Symlinks verified | [ ] | [ ] | |
| Interactive shell | [ ] | [ ] | |
| Non-interactive shell | [ ] | [ ] | |
| IDE terminal | [ ] | [ ] | |
| Approved versions | [ ] | [ ] | |
| Project QA | [ ] | [ ] | |
| Neovim QA | [ ] | [ ] | |
| Services unchanged/healthy | N/A | [ ] | |
| Runtime doctor | N/A | [ ] | |
| Rollback proven | [ ] | [ ] | |
| One-hour check | [ ] | [ ] | |
| Next-day check | [ ] | [ ] | |
| Worktrees clean | [ ] | [ ] | |

Final approval:

- [ ] Hamel confirms both machines work normally.
- [ ] No fallback tool is removed until a separate cleanup PR is approved.
- [ ] Final symlink, version, exception, and bootstrap state is documented.
