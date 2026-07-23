# mac-pro-resilience: Resilience Work-Mac Runbook

`mac-pro-resilience` is the canonical profile for reproducing Hamel's
terminal/editor setup on the Resilience work laptop without replacing
work-specific state.

## Scope

Set up only:

- Ghostty with Maple Mono NF and Hamel Nord Blur.
- Herdr with `Ctrl-b` as the prefix.
- Hunk with the shared Catppuccin Mocha review theme.
- Neovim with the committed plugins, keymaps, LSPs, formatters, and curriculum.
- Bookokrat with the custom `Hamel Nord` theme: transparent interface and an
  opaque Nord PDF canvas.

Do not replace `.zshrc`, `config/mise`, Git identity, credentials, certificates,
Docker state, Zed, Karabiner, or company-managed applications unless Hamel asks.
The retired `setup/mac-resilience` and `setup/mac-vm` paths are not compatibility
entry points. Zed remains archived under `config/zed`, but this profile does not
install or link it.

## Profile Boundaries

- `setup/mac-pro-resilience/.zshrc` loads the shared Mac interface from
  `config/zsh/mac/init.zsh`, then adds work-owned behavior and
  `setup/mac-pro-resilience/goodmorning.zsh`.
- The Resilience profile does not load `config/zsh/mac/personal.zsh`.
- The existing work `~/.zshrc` remains work-owned. Do not replace or link it.
- Work repositories keep their approved Node, package-manager, credential, and
  certificate setup.

## Quick Repair on an Existing Work Laptop

This fast path assumes the laptop was already bootstrapped and only needs its
Homebrew bundle or managed links repaired. Use the full agent workflow below
when a formatter, language server, or Neovim plugin is missing.

Run these commands only from a clean work-laptop clone:

```bash
cd ~/Developer/dotfiles-hd
git status --short --branch
git pull --ff-only
brew bundle install --no-upgrade --file=setup/mac-pro-resilience/Brewfile
./setup/mac-pro-resilience/link-terminal-editor-config.sh
hunk --version
zsh -lic \
  'alias hwatch && whence -w goodMorning _resilience_update_repo _resilience_brew_cooldown_seconds'
```

The bundle command installs missing tools without upgrading existing packages.
The linker creates timestamped backups before replacing a non-matching config.
Stop before pulling if `git status` shows local changes you do not recognize.
The Resilience `goodMorning` flow performs the same guarded
`hd719/dotfiles-hd` fast-forward before its other update steps. It refuses to
switch or pull either Resilience repo when that working tree is dirty, and all
repo pulls use `--ff-only`.

Homebrew upgrades run at most once every 72 hours. A successful run records
`~/.cache/goodmorning/resilience-homebrew-upgrade`; failures do not advance the
cooldown. Use `goodMorning --no-brew` to skip Homebrew or
`goodMorning --force-brew` to explicitly bypass the cooldown. Virtual hosts
always skip Homebrew. For normal daily readiness, run `goodMorning` without
flags; never force the cooldown unless Hamel explicitly asks. It continues
independent stages after a sync, Homebrew, or repository-update failure, then
returns nonzero so the failed stage remains visible.

If `alias hwatch` prints the alias, the existing work shell already loads the
shared Mac aliases and no `.zshrc` edit is needed. If it reports that `hwatch`
does not exist, preserve the work shell and add only these Hunk aliases:

```bash
cp "$HOME/.zshrc" "$HOME/.zshrc.backup-$(date +%Y%m%d-%H%M%S)"
nvim "$HOME/.zshrc"
```

```zsh
alias hwatch='hunk diff --watch'
alias hdiff='hunk diff'
alias hstaged='hunk diff --staged'
alias hshow='hunk show'
```

Save the file, then run `exec zsh` and `alias hwatch` again. Do not replace the
rest of the work `.zshrc`. This fallback does not load the Resilience
`goodMorning` policy. If any function in the `whence` check above is missing,
stop and report that the live work shell is stale instead of sourcing the full
profile without approval.

For daily Cursor reviews, open Ghostty in the same repo or worktree and run
`hwatch`. It includes new files and refreshes while Cursor edits. See the
[Hunk documentation](https://www.hunk.dev/), the
[shared theme](../../config/hunk/config.toml), and the
[shared aliases](../../config/zsh/aliases.zsh).

## Agent Workflow

### 1. Read and inspect

From `~/Developer/dotfiles-hd`, read:

- `AGENTS.md`
- `README.md`
- This file
- `config/nvim/README.md`

Then inspect before changing anything:

```bash
xcode-select -p
command -v brew
git status --short --branch

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Dotfiles has local changes; stop before pulling."
  exit 1
fi

git pull --ff-only

for path in \
  "$HOME/.config/bookokrat" \
  "$HOME/.config/nvim" \
  "$HOME/.config/herdr/config.toml" \
  "$HOME/.config/hunk/config.toml" \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
do
  ls -ld "$path" 2>/dev/null || true
  readlink "$path" 2>/dev/null || true
done
```

If Xcode Command Line Tools or Homebrew is missing, stop and use only the
company-approved install path. If a destination has unexpected local changes,
report them before replacing anything.

### 2. Install the scoped dependencies

Do not run `setup/mac-mini/Brewfile` or `setup/mac-pro/setup.sh` on this
laptop.

```bash
brew bundle install --no-upgrade \
  --file="$HOME/Developer/dotfiles-hd/setup/mac-pro-resilience/Brewfile"

uv tool install 'mdformat==1.0.0' \
  --with 'mdformat-gfm==1.0.0' \
  --with 'mdformat-frontmatter==2.1.2' \
  --with 'mdformat-footnote==0.1.3' \
  --with 'mdformat-gfm-alerts==2.0.0' \
  --with 'mdformat-wikilink==0.3.0'

uv tool install 'ruff==0.15.21'
export PATH="$(uv tool dir --bin):$PATH"

# GraphQL language server: an npm tool with no Homebrew formula. Install it to a
# fixed, node-version-independent prefix that the Neovim config references by
# absolute path (~/.local/graphql-lsp/bin/graphql-lsp), so it survives Node
# upgrades and does not depend on the work fnm Node. npm comes from the
# Homebrew Node that vtsls/ESLint pulled in above.
npm install -g --prefix "$HOME/.local/graphql-lsp" \
  'graphql-language-service-cli@3.5.0'
```

`graphql-lsp` gives syntax and single-file features immediately; schema-aware
completion, validation, and go-to-definition require a `graphql-config` file
(for example `graphql.config.ts`) in the work repo, which the language server
auto-detects as its root marker. Do not add that config to a work repo without
Hamel's request.

The Brewfile does not deliberately manage work-repo runtime versions. The
`vtsls` and ESLint formulae may install and link Homebrew Node as a dependency,
so confirm inside each work repo that its approved version manager still wins:

```bash
command -v node
node --version
```

Do not change the work Node version to satisfy the language servers. Their
Homebrew launchers can use their own Node dependency. `gofmt` becomes available
when the work laptop's approved Go toolchain is on `PATH`; ask Hamel before
installing a different Go runtime.

If Homebrew or a cask is blocked by company policy, report the blocker. Do not
bypass device management or security controls.

### 3. Link the portable configs

```bash
~/Developer/dotfiles-hd/setup/mac-pro-resilience/link-terminal-editor-config.sh
```

The script is idempotent and creates timestamped sibling backups before
replacing a non-matching destination. It links only these paths:

| Tool      | Live path                                                    | Source                     |
| --------- | ------------------------------------------------------------ | -------------------------- |
| Bookokrat | `~/.config/bookokrat`                                        | `config/bookokrat`         |
| Ghostty   | `~/Library/Application Support/com.mitchellh.ghostty/config` | `config/ghostty/config`    |
| Herdr     | `~/.config/herdr/config.toml`                                | `config/herdr/config.toml` |
| Hunk      | `~/.config/hunk/config.toml`                                 | `config/hunk/config.toml`  |
| Neovim    | `~/.config/nvim`                                             | `config/nvim`              |

### 4. Install plugins and project tools

```bash
DOTFILES_NVIM_RESTORE_ALL=1 \
  nvim --headless '+Lazy! restore' +qa
```

The restore-only environment flag includes locked plugins that stay disabled
during normal startup when their local prerequisite is absent, including
`obsidian.nvim` without the personal vault. Open Neovim once and let Tree-sitter
finish installing its committed parser list. In each work repo, use that repo's
documented package manager to install dependencies. Prettier stays
project-local, and the ESLint server discovers the project's own ESLint
configuration.

### 5. Verify

```bash
brew bundle check --verbose \
  --file="$HOME/Developer/dotfiles-hd/setup/mac-pro-resilience/Brewfile"

for cmd in \
  bash-language-server bookokrat fd fzf gopls herdr hunk lazygit lua-language-server \
  magick nvim rg stylua tree-sitter uv vscode-eslint-language-server \
  vscode-json-language-server vtsls mdformat ruff
do
  command -v "$cmd"
done

# graphql-lsp is installed at a fixed prefix (not on PATH); check it directly.
test -x "$HOME/.local/graphql-lsp/bin/graphql-lsp" && echo "graphql-lsp ok"
mdformat --version | grep -F 'mdformat 1.0.0'
ruff --version | grep -Fx 'ruff 0.15.21'
"$HOME/.local/graphql-lsp/bin/graphql-lsp" --version | grep -Fx '3.5.0'

test "$(readlink "$HOME/.config/bookokrat")" = \
  "$HOME/Developer/dotfiles-hd/config/bookokrat"
test "$(readlink "$HOME/.config/nvim")" = \
  "$HOME/Developer/dotfiles-hd/config/nvim"
test "$(readlink "$HOME/.config/herdr/config.toml")" = \
  "$HOME/Developer/dotfiles-hd/config/herdr/config.toml"
test "$(readlink "$HOME/.config/hunk/config.toml")" = \
  "$HOME/Developer/dotfiles-hd/config/hunk/config.toml"
test "$(readlink "$HOME/Library/Application Support/com.mitchellh.ghostty/config")" = \
  "$HOME/Developer/dotfiles-hd/config/ghostty/config"

/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config
herdr --version
hunk --version
zsh -lic \
  'alias hwatch && alias hdiff && alias hstaged && alias hshow && whence -w goodMorning _resilience_update_repo _resilience_brew_cooldown_seconds'
nvim --headless +qa!

test ! -e "$HOME/Developer/dotfiles-hd/setup/mac-resilience"
test ! -L "$HOME/Developer/dotfiles-hd/setup/mac-resilience"
test ! -e "$HOME/Developer/dotfiles-hd/setup/mac-vm"
test ! -L "$HOME/Developer/dotfiles-hd/setup/mac-vm"
```

If Herdr is already running, reload and inspect it:

```bash
herdr server reload-config
herdr status
```

Inside Neovim, check `:checkhealth`, `:checkhealth snacks`, `:LspInfo`,
`:ConformInfo`, and `:TSStatus`. Open a PDF and confirm that Bookokrat starts
in a Herdr tab with the `Hamel Nord` theme, search, page navigation, and zoom.
Open a work TypeScript file and confirm highlighting, completion, ESLint
diagnostics, `Space p` formatting, and `Space g` LazyGit. From the same
worktree, run `hwatch` in Ghostty and confirm Hunk refreshes while Cursor edits.
If GUI control is available, perform these checks in exactly one fresh Ghostty
window and close it afterward. Otherwise, report the GUI check as unverified
instead of repeatedly launching windows. If Zed is still installed, report it;
do not delete the preserved `config/zed` archive.

Report every backup and validation result. Do not commit or push from the work
laptop unless Hamel asks.

## Prompt for the Work-Laptop Agent

```text
Run a full post-merge readiness check on this Resilience work Mac.

Repository: ~/Developer/dotfiles-hd
Canonical profile: mac-pro-resilience

Read AGENTS.md, README.md, setup/mac-pro-resilience/README.md, and
config/nvim/README.md before acting.

Show the hostname, disk space, Git branch/status, HEAD, and remote. Stop before
pulling if the worktree is dirty or diverged. Otherwise, fast-forward only.

Run `zsh -lic 'goodMorning'` with its normal 72-hour Homebrew cooldown. Do not
use `--force-brew`, repeatedly retry failures, reset local changes, or switch a
dirty repository. If the `goodMorning` function is missing, stop and report the
stale live shell. If it returns nonzero, report the failed stage even if later
stages completed.

If a check fails, repair only through the scoped commands in this runbook:
`brew bundle install --no-upgrade`, the mac-pro-resilience linker, and the
documented Neovim restore. Preserve and report every timestamped backup.

Verify the Brewfile, all five Bookokrat/Ghostty/Herdr/Hunk/Neovim links, the
whole-directory Bookokrat link, shared Zsh aliases in a fresh login shell,
Ghostty config, Herdr, Hunk, and headless Neovim. Confirm the work `.zshrc`
was not replaced, personal Zsh workflows are not loaded, retired
`setup/mac-resilience` and `setup/mac-vm` paths are absent, and Zed is not
installed or managed by this profile. If GUI control is available, use exactly
one fresh Ghostty window for the shell and Neovim checks.

Never change work-repository runtimes, Git/SSH/GitHub auth, Git identity,
AWS/Doppler/1Password state, company certificates, Docker state, or security
policy. Do not commit or push.

Return a concise verdict with: Repo, goodMorning, Dependencies, Links,
Shared Zsh, Ghostty, Neovim, Changed, Backups, Failed, and Approval needed.
```
