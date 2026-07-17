# Resilience Work Mac: Ghostty, Herdr, Hunk, and Neovim

This is the agent runbook for reproducing Hamel's terminal/editor setup on the
Resilience work laptop without replacing work-specific state.

## Scope

Set up only:

- Ghostty with Maple Mono NF and Hamel Nord Blur.
- Herdr with `Ctrl-b` as the prefix.
- Hunk with the shared Hamel Nord review theme.
- Neovim with the committed plugins, keymaps, LSPs, formatters, and curriculum.

Do not replace `.zshrc`, `config/mise`, Git identity, credentials, certificates,
Docker state, Zed, Karabiner, or company-managed applications unless Hamel asks.

## Apply This Setup on the Existing Work Laptop

Run these commands only from a clean work-laptop clone:

```bash
cd ~/Developer/dotfiles-hd
git status --short --branch
git pull --ff-only
brew bundle install --no-upgrade --file=setup/mac-resilience/Brewfile
./setup/mac-resilience/link-terminal-editor-config.sh
exec zsh
hunk --version
alias hwatch
```

The bundle command installs missing tools without upgrading existing packages.
The linker creates timestamped backups before replacing a non-matching config.
Stop before pulling if `git status` shows local changes you do not recognize.

If `alias hwatch` prints the alias, the existing work shell already loads the
shared Mac aliases and no `.zshrc` edit is needed. If it reports that `hwatch`
does not exist, preserve the work shell and add only this source line:

```bash
cp "$HOME/.zshrc" "$HOME/.zshrc.backup-$(date +%Y%m%d-%H%M%S)"
nvim "$HOME/.zshrc"
```

```zsh
source "$HOME/Developer/dotfiles-hd/config/zsh/hunk-aliases.zsh"
```

Save the file, then run `exec zsh` and `alias hwatch` again. Do not replace the
rest of the work `.zshrc`.

For daily Cursor reviews, open Ghostty in the same repo or worktree and run
`hwatch`. It includes new files and refreshes while Cursor edits. See the
[Hunk documentation](https://www.hunk.dev/), the
[shared theme](../../config/hunk/config.toml), and the
[shared aliases](../../config/zsh/hunk-aliases.zsh).

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

Do not run `setup/mac-mini/Brewfile` or `setup/mac-vm/setup-vm.sh` on this
laptop.

```bash
brew bundle install --no-upgrade \
  --file="$HOME/Developer/dotfiles-hd/setup/mac-resilience/Brewfile"

uv tool install 'mdformat==1.0.0' \
  --with mdformat-gfm \
  --with mdformat-frontmatter \
  --with mdformat-footnote \
  --with mdformat-gfm-alerts \
  --with 'mdformat-wikilink==0.3.0'

uv tool install ruff@latest
uv tool update-shell
export PATH="$(uv tool dir --bin):$PATH"

# GraphQL language server: an npm tool with no Homebrew formula. Install it to a
# fixed, node-version-independent prefix that the Neovim config references by
# absolute path (~/.local/graphql-lsp/bin/graphql-lsp), so it survives Node
# upgrades and does not depend on the work fnm Node. npm comes from the Homebrew
# Node that vtsls/ESLint pulled in above.
npm install -g --prefix "$HOME/.local/graphql-lsp" graphql-language-service-cli
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
~/Developer/dotfiles-hd/setup/mac-resilience/link-terminal-editor-config.sh
```

The script is idempotent and creates timestamped sibling backups before
replacing a non-matching destination. It links only these paths:

| Tool | Live path | Source |
| --- | --- | --- |
| Ghostty | `~/Library/Application Support/com.mitchellh.ghostty/config` | `config/ghostty/config` |
| Herdr | `~/.config/herdr/config.toml` | `config/herdr/config.toml` |
| Hunk | `~/.config/hunk/config.toml` | `config/hunk/config.toml` |
| Neovim | `~/.config/nvim` | `config/nvim` |

### 4. Install plugins and project tools

```bash
nvim --headless '+Lazy! restore' +qa
```

Open Neovim once and let Tree-sitter finish installing its committed parser
list. In each work repo, use that repo's documented package manager to install
dependencies. Prettier stays project-local, and the ESLint server discovers the
project's own ESLint configuration.

### 5. Verify

```bash
brew bundle check --verbose \
  --file="$HOME/Developer/dotfiles-hd/setup/mac-resilience/Brewfile"

for cmd in \
  bash-language-server fd fzf gopls gs herdr hunk lazygit lua-language-server \
  magick nvim rg stylua tree-sitter uv vscode-eslint-language-server \
  vscode-json-language-server vtsls mdformat ruff
do
  command -v "$cmd"
done

# graphql-lsp is installed at a fixed prefix (not on PATH); check it directly.
test -x "$HOME/.local/graphql-lsp/bin/graphql-lsp" && echo "graphql-lsp ok"

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
zsh -lic 'alias hwatch; alias hdiff; alias hstaged; alias hshow'
nvim --headless +qa!
```

If Herdr is already running, reload and inspect it:

```bash
herdr server reload-config
herdr status
```

Inside Neovim, check `:checkhealth`, `:checkhealth snacks`, `:LspInfo`,
`:ConformInfo`, and `:TSStatus`. Open a PDF in Ghostty and confirm that it
renders. Open a work TypeScript file and confirm highlighting, completion,
ESLint diagnostics, `Space p` formatting, and `Space g` LazyGit. From the same
worktree, run `hwatch` in Ghostty and confirm Hunk refreshes while Cursor edits.

Report every backup and validation result. Do not commit or push from the work
laptop unless Hamel asks.

## Prompt for the Work-Laptop Agent

```text
Open ~/Developer/dotfiles-hd and read AGENTS.md, README.md,
setup/mac-resilience/README.md, and config/nvim/README.md. Follow the
mac-resilience runbook to set up only Ghostty, Herdr, Hunk, and Neovim. Inspect the
repo and every live destination first, preserve all work-specific state, and
timestamp-backup any non-matching destination before linking. Never touch
Git/SSH/GitHub auth, Git identity, AWS/Doppler/1Password state, company
certificates, Docker state, .zshrc, or work-repo runtimes. Install only the
documented scoped dependencies, verify every link and app, and report every
backup or company-policy blocker. If `hwatch` is not loaded, report the one-line
source instruction from this runbook instead of editing .zshrc. Do not commit or
push.
```
