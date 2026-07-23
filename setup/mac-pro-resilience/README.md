# mac-pro-resilience

Production runbook for Hamel's Resilience work Mac.

## Scope

Manage only:

- Ghostty with Maple Mono NF and Hamel Nord Blur
- Herdr
- Hunk with the shared Catppuccin Mocha theme
- Neovim with locked plugins and pinned tools
- Bookokrat with the Hamel Nord theme

Keep the work `~/.zshrc`, `config/mise`, Git identity, credentials,
certificates, Docker state, Karabiner, and company-managed applications
machine-owned. Never use the personal Mac bootstrap or Mac mini Brewfile here.

`setup/mac-pro-resilience/.zshrc` loads the shared Mac interface and
work-specific behavior, but not `config/zsh/mac/personal.zsh`. This runbook
repairs an existing work shell; it never replaces or links `~/.zshrc`.

Zed is archived under `config/zed` but is not installed or linked by this
profile. The retired `setup/mac-resilience` and `setup/mac-vm` paths are invalid.

## 1. Preflight

Work only from the canonical clean clone:

```bash
cd "$HOME/Developer/dotfiles-hd"
xcode-select -p
command -v brew
git status --short --branch
git branch --show-current
git remote get-url origin
```

Stop if Xcode tools or Homebrew are unavailable, the origin is not
`git@github.com:hd719/dotfiles-hd.git`, the current branch is not `master`, or
the worktree is dirty or diverged. Use only the company-approved installation
path.

```bash
git pull --ff-only origin master

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

Inspect unexpected local state before replacing it.

## 2. Install or Repair

Install only missing scoped dependencies:

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

npm install -g --prefix "$HOME/.local/graphql-lsp" \
  'graphql-language-service-cli@3.5.0'
```

The GraphQL server uses a fixed prefix. Schema-aware features still require a
project-owned GraphQL config; never add one to a work repository without
approval. Prettier remains project-local.

Create the five managed links:

```bash
setup/mac-pro-resilience/link-terminal-editor-config.sh
```

The linker preflights every source, backs up each non-matching destination, and
is safe to rerun. It owns only:

| Live path                                                    | Source                     |
| ------------------------------------------------------------ | -------------------------- |
| `~/.config/bookokrat`                                        | `config/bookokrat`         |
| `~/Library/Application Support/com.mitchellh.ghostty/config` | `config/ghostty/config`    |
| `~/.config/herdr/config.toml`                                | `config/herdr/config.toml` |
| `~/.config/hunk/config.toml`                                 | `config/hunk/config.toml`  |
| `~/.config/nvim`                                             | `config/nvim`              |

Restore every locked Neovim plugin, including plugins gated off during normal
startup:

```bash
DOTFILES_NVIM_RESTORE_ALL=1 \
  nvim --headless '+Lazy! restore' +qa
nvim --headless \
  "+lua local parsers={'bash','ecma','go','gomod','gosum','gowork','graphql','javascript','json','jsx','lua','markdown','markdown_inline','python','query','toml','tsx','typescript','vim','vimdoc','yaml'}; assert(require('nvim-treesitter').install(parsers):wait(), 'Tree-sitter parser installation failed')" \
  +qa
```

Do not change a work repository's Node, package manager, or Go version to
satisfy editor tooling. Confirm its approved runtime still wins:

```bash
command -v node
node --version
```

Report Homebrew or security-policy blockers; never bypass them.

## 3. Shell and `goodMorning`

Verify the existing login shell already loads the current profile:

```bash
zsh -lic \
  'alias hwatch && alias hdiff && alias hstaged && alias hshow && whence -w goodMorning _resilience_update_repo _resilience_brew_cooldown_seconds'
```

If only the Hunk aliases are missing, back up `~/.zshrc` and add these lines:

```zsh
alias hwatch='hunk diff --watch'
alias hdiff='hunk diff'
alias hstaged='hunk diff --staged'
alias hshow='hunk show'
```

Do not load broader shell code automatically. If any Resilience function is
missing, report the stale shell instead of replacing `~/.zshrc`.

Normal daily maintenance is:

```bash
zsh -lic 'goodMorning'
```

`goodMorning`:

- fast-forwards only the verified `hd719/dotfiles-hd` checkout
- skips dirty Resilience repositories and uses `git pull --ff-only`
- upgrades Homebrew at most once every 72 hours
- skips Homebrew on virtual hosts
- accepts `--no-brew`; use `--force-brew` only with explicit approval
- continues independent stages after a failure, then returns nonzero

Never reset local changes or repeatedly retry a failed stage.

## 4. Verify

```bash
(
  set -euo pipefail

  brew bundle check --verbose \
    --file="$HOME/Developer/dotfiles-hd/setup/mac-pro-resilience/Brewfile"

  for cmd in \
    bash-language-server bookokrat fd fzf gopls herdr hunk lazygit \
    lua-language-server magick nvim rg stylua tree-sitter uv \
    vscode-eslint-language-server vscode-json-language-server vtsls \
    mdformat ruff
  do
    command -v "$cmd"
  done

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
  nvim --headless +qa!

  test ! -e "$HOME/Developer/dotfiles-hd/setup/mac-resilience"
  test ! -L "$HOME/Developer/dotfiles-hd/setup/mac-resilience"
  test ! -e "$HOME/Developer/dotfiles-hd/setup/mac-vm"
  test ! -L "$HOME/Developer/dotfiles-hd/setup/mac-vm"
  test "$(readlink "$HOME/.zshrc" 2>/dev/null || true)" != \
    "$HOME/Developer/dotfiles-hd/setup/mac-pro-resilience/.zshrc"
)
```

If Herdr is already running:

```bash
herdr server reload-config
herdr status
```

In exactly one fresh Ghostty window, confirm:

- the shell checks above pass
- Neovim `:checkhealth`, `:checkhealth vim.lsp`, `:ConformInfo`, and `:TSStatus`
  are healthy
- a PDF opens in Bookokrat with Hamel Nord, search, navigation, and zoom
- a TypeScript file has completion, ESLint, `Space p`, and `Space g`
- `hwatch` refreshes while the worktree changes

If GUI control is unavailable, report the UI checks as unverified. If Zed is
installed, report it without deleting the preserved archive.

## Agent Prompt

```text
Run the mac-pro-resilience post-merge readiness workflow from
~/Developer/dotfiles-hd. Read AGENTS.md and this runbook first. Preflight the
host, clean checkout, remote, links, and work-owned state. Fast-forward only,
then run normal `goodMorning` without forcing its cooldown. Repair only through
the scoped Brewfile, linker, pinned tools, and Neovim restore documented here.

Never replace the work .zshrc, change work runtimes or credentials, bypass
company policy, reset changes, or commit and push. Use at most one fresh
Ghostty window. Report: Repo, goodMorning, Dependencies, Links, Shared Zsh,
Ghostty, Neovim, Changed, Backups, Failed, and Approval needed.
```
