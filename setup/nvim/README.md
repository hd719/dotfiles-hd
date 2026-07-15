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

Every profile requires `curl` and Tree-sitter CLI 0.26.1 or newer. `wget` does
not replace `curl` because the locked Tree-sitter plugin invokes `curl`
directly.

## Setup

```bash
cd /path/to/dotfiles-hd
./setup/nvim/link-config.sh
./setup/nvim/bootstrap.sh full
```

The choice is per machine. Using `desktop` on your laptop and `core` or `full` on
a server is normal, but you do not combine profiles on one machine. If a
machine's role changes, rerun the higher profile—for example, move from `core`
to `full` when a basic server becomes a development host. Repeating or upgrading
is safe: matching links, installed commands, and pinned npm/uv tools become
no-ops, while Lazy converges plugins to the committed lockfile.

Run `bootstrap.sh --help` or `check-dependencies.sh --help` to see the same
profile guidance in the terminal.

The bootstrap uses Homebrew when it is already available. It never installs
Homebrew, invokes `sudo`, replaces a work-managed runtime, or modifies shell
startup files. On a server without Homebrew, install the reported base commands
with the approved system package manager, then rerun the same bootstrap.
Existing commands on `PATH` are accepted. When `graphql-lsp` is missing, the
bootstrap installs its pinned fallback under `~/.local/graphql-lsp`.
Install the machine's approved Go toolchain before using `full`; bootstrap never
silently replaces it just to supply `gofmt`.

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

```bash
./setup/nvim/check-dependencies.sh full
./setup/nvim/tests/check-dependencies.sh
nvim --headless -u NONE -l \
  ./config/nvim/tests/escape-save.lua
```

Prettier deliberately remains project-local. Desktop image/PDF support is
optional; its absence never prevents the core config from starting.
