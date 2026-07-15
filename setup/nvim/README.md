# Portable Neovim Setup

These scripts are the shared setup path for personal Macs, work Macs, Linux
machines, and cloud servers. They are capability-based: tools already provided
by Homebrew, mise, a system package manager, or a work-managed runtime are kept.

## Profiles

Profiles are cumulative: `core` → `full` → `desktop`. Choose one profile; do not
run multiple profiles for the same setup. A higher profile already includes
everything to its left.

| Profile | What it includes | Use it when |
| --- | --- | --- |
| `core` | Neovim, Git, search tools, Tree-sitter, LazyGit, and locked plugins | You are on a small headless/SSH server and only need editing, search, and Git. |
| `full` | Everything in `core`, plus configured language servers and formatters | You are coding on a developer laptop, workstation, or capable cloud development host. This is the default. |
| `desktop` | Everything in `full`, plus ImageMagick, Ghostscript, and a system opener check | You are using Ghostty or another Kitty-graphics-compatible terminal and want image/PDF previews. |

The Go toolchain stays host-managed, and Prettier stays project-local. The
`desktop` profile does not install Ghostty or Herdr; machine-specific runbooks
own those applications.

`full` and `desktop` require host-managed Node 18+ and gopls 0.23.0+. On
Ubuntu, the dependency adapter preserves Node and installs its pinned gopls
when gopls is missing or stale.

Every profile requires `curl` and Tree-sitter CLI 0.26.1 or newer. `wget` does
not replace `curl` because the locked Tree-sitter plugin invokes `curl`
directly.

## Setup

On macOS or a host where the required commands are already installed:

```bash
cd /path/to/dotfiles-hd
./setup/nvim/link-config.sh
./setup/nvim/bootstrap.sh full
```

On Ubuntu 26.04 or newer, use the focused APT adapter first. Use the same
profile for the adapter and bootstrap:

```bash
cd /path/to/dotfiles-hd
PROFILE=full
export PATH="$HOME/.local/bin:$PATH"
./setup/ubuntu/install-mise.sh
mise exec -- ./setup/ubuntu/install-neovim-dependencies.sh "$PROFILE"
./setup/nvim/link-config.sh
mise exec -- ./setup/nvim/bootstrap.sh "$PROFILE"
```

The mise step is for Hamel's personal `full` and `desktop` machines; a generic
`core` server may keep its approved system runtimes. `mise exec --` exposes the
new pins immediately, while the export keeps user-local adapter commands visible
to the shared bootstrap.

The Ubuntu adapter uses APT, not Homebrew or Snap. It keeps a working host Node,
npm, and Go toolchain, then uses pinned user-level tools only where Ubuntu's
package is missing or too old. See [`../ubuntu/README.md`](../ubuntu/README.md).

The choice is per machine. Using `desktop` on your laptop and `core` or `full` on
a server is normal, but you do not combine profiles on one machine. If a
machine's role changes, rerun the higher profile—for example, move from `core`
to `full` when a basic server becomes a development host. Repeating or upgrading
is safe: matching links, installed commands, and pinned npm/uv tools become
no-ops, while Lazy and Tree-sitter converge to the committed plugin pins and
parser list without rewriting `lazy-lock.json`.

Run `bootstrap.sh --help` or `check-dependencies.sh --help` to see the same
profile guidance in the terminal.

The shared bootstrap uses Homebrew when it is already available. It never
installs Homebrew, invokes `sudo`, replaces a work-managed runtime, or modifies
shell startup files. The separate Ubuntu adapter invokes APT with `sudo`; the
bootstrap itself remains platform-neutral. On another server without Homebrew,
install the reported base commands with its approved system package manager,
then rerun the same bootstrap.
Existing commands on `PATH` are accepted. When `graphql-lsp` is missing, the
bootstrap installs its pinned fallback under `~/.local/graphql-lsp`.
Install the machine's approved Go toolchain before using `full`; bootstrap never
silently replaces it just to supply `gofmt`.

The Node command and version already on `PATH` also stay host-managed. When a
missing Homebrew language-server formula needs Homebrew Node, bootstrap installs
that dependency without linking it into the global Homebrew prefix. The
language-server launcher uses Homebrew's private Node path while the caller's
Node remains active. A post-install check restores the original Homebrew link
and fails if that invariant cannot be proven.

If an active unversioned Homebrew Node is outdated, bootstrap stops before
installing language servers. Upgrade that Node intentionally, or activate a
versioned/external Node, and rerun bootstrap.

For `full` and `desktop`, the directory printed by `uv tool dir --bin` must come
before any stale `mdformat` or Ruff copies on the persistent `PATH` used to
launch Neovim. The doctor validates the versions and extensions of the commands
that `PATH` actually resolves. Neither bootstrap nor the doctor temporarily
expands that `PATH`, because doing so could report success while a normal Neovim
session finds the wrong tools. If the doctor prints a path warning, apply its
ordering through the machine-approved shell setup, start a fresh shell, and
rerun bootstrap. For the current shell:

```bash
export PATH="$(uv tool dir --bin):$PATH"
```

## Verify

First rerun the selected machine adapter and bootstrap. A successful second run
proves that setup converges instead of duplicating tools or damaging host
runtimes. If the checkout already contains changes, test from a separate clone
or worktree rather than pulling or switching it in place.

```bash
export PATH="$HOME/.local/bin:$PATH"
./setup/ubuntu/install-mise.sh
mise exec -- ./setup/ubuntu/install-neovim-dependencies.sh full
```

Then, on every host:

```bash
./setup/nvim/bootstrap.sh full
./setup/nvim/check-dependencies.sh full
./setup/nvim/tests/link-config.sh
./setup/nvim/tests/check-dependencies.sh
./setup/nvim/tests/bootstrap.sh
nvim --headless -u NONE -l \
  ./config/nvim/tests/escape-save.lua
nvim --headless -u NONE -l \
  ./config/nvim/tests/treesitter-install.lua
```

Prettier deliberately remains project-local. Desktop image/PDF support is
optional; its absence never prevents the core config from starting.
