# Portable Neovim Setup

These scripts are the shared setup path for personal Macs, work Macs, Linux
machines, and cloud servers. They are capability-based: tools already provided
by Homebrew, mise, a system package manager, or a work-managed runtime are kept.

## Profiles

- `core`: editor, search, Tree-sitter, LazyGit, and locked plugins.
- `full`: core plus configured global language servers and formatters. The Go
  toolchain stays host-managed, and Prettier stays project-local.
- `desktop`: full plus ImageMagick and Ghostscript for image/PDF previews.

## Setup

```bash
cd /path/to/dotfiles-hd
./setup/nvim/link-config.sh
./setup/nvim/bootstrap.sh full
```

Use `desktop` on Ghostty machines and `core` on a minimal cloud server. Repeating
either command is safe: matching links, installed commands, and pinned npm/uv
tools become no-ops, while Lazy converges plugins to the committed lockfile.

The bootstrap uses Homebrew when it is already available. It never installs
Homebrew, invokes `sudo`, replaces a work-managed runtime, or modifies shell
startup files. On a server without Homebrew, install the reported base commands
with the approved system package manager, then rerun the same bootstrap.
Existing commands on `PATH` are accepted. When `graphql-lsp` is missing, the
bootstrap installs its pinned fallback under `~/.local/graphql-lsp`.
Install the machine's approved Go toolchain before using `full`; bootstrap never
silently replaces it just to supply `gofmt`.

## Verify

```bash
./setup/nvim/check-dependencies.sh full
nvim --headless -u NONE -l \
  ./config/nvim/tests/escape-save.lua
```

Prettier deliberately remains project-local. Desktop image/PDF support is
optional; its absence never prevents the core config from starting.
