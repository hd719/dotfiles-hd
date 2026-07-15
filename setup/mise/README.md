# Personal mise Toolchain

Personal macOS and Ubuntu use the same runtime pins from
`config/mise/config.toml`. The operating system owns the `mise` command;
mise owns Bun, Go, Node, pnpm, Python, and the pinned Go language server
(`gopls`). pnpm `11.2.2` matches the version declared by the main development
workspace.

## Personal macOS

```bash
brew install mise
./setup/mise/bootstrap.sh personal
```

## Personal Ubuntu

```bash
./setup/ubuntu/install-mise.sh
```

On a fresh host, the Ubuntu command installs mise from its official APT
repository. It preserves an existing working mise command, then calls the same
shared bootstrap used on macOS.

The bootstrap safely links the whole mise directory at
`${XDG_CONFIG_HOME:-$HOME/.config}/mise`, backs up any conflict, runs
`mise install --yes`, and refreshes shims from that controlled directory so a
project-local mise config cannot override the machine pins. Node may include npm
and npx, but these personal setup paths do not invoke or alter them; pnpm is the
configured JavaScript package manager.

Verify the active pins from a new shell:

```bash
mise config ls
mise ls --current
command -v node pnpm go python bun
```

For commands run immediately from an older, not-yet-reloaded shell, use
`mise exec -- your-command`. New interactive Zsh sessions activate mise from
the shared shell configuration.

Do not run this personal bootstrap on the Resilience work Mac. Work repos own
their approved runtimes there.
