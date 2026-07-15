# Dotfiles

This repo is the source of truth for rebuilding my personal and work machines.

## Repo Map

- `config/` - portable app and tool config. This is where personal settings, themes, keymaps, terminal config, and app exports live.
- `setup/` - machine setup scripts and machine-specific bootstrap files for macOS, Linux, VMs, and servers.

## Resilience Work Mac

Use [`setup/mac-resilience/README.md`](setup/mac-resilience/README.md) to install
and link the Ghostty, Herdr, and Neovim setup on the work laptop. That runbook is
intentionally narrower than the personal Mac inventory below so it does not
replace work-specific shell, runtime, credential, or certificate state.

## Shared Personal Toolchain

Personal macOS and Ubuntu share the exact Bun, Go, Node, pnpm, Python, and `gopls`
pins in `config/mise/config.toml`. Each OS owns the mise CLI, while mise owns
those development tools:

```bash
# Personal macOS
brew install mise
./setup/mise/bootstrap.sh personal

# Personal Ubuntu
./setup/ubuntu/install-mise.sh
```

Both paths create the same whole-directory link at `~/.config/mise`, back up
conflicts, and install the same pinned runtimes and pnpm. Node's bundled npm/npx
files are left untouched but are not used by these setup paths. See
[`setup/mise/README.md`](setup/mise/README.md). Do not apply this personal
toolchain to the Resilience work Mac.

## Portable Neovim Setup

Every personal, work, Linux, or cloud host uses the same capability-based setup:

```bash
cd /path/to/dotfiles-hd
./setup/nvim/link-config.sh
./setup/nvim/bootstrap.sh full
```

Profiles are cumulative: use `core` for a minimal headless/SSH server, `full`
for a development machine without desktop previews, or `desktop` for a Ghostty
machine with image/PDF previews. Choose one per machine—`desktop` already
includes `full` and `core`. The scripts preserve tools already supplied by mise
or the operating system and only fill missing capabilities. See
[`setup/nvim/README.md`](setup/nvim/README.md).

On Ubuntu 26.04 or newer, install the external dependencies with APT through
the focused Ubuntu adapter before running the shared bootstrap:

```bash
PROFILE=full
export PATH="$HOME/.local/bin:$PATH"
DOTFILES_DIR="$(git rev-parse --show-toplevel)"
MISE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
"$DOTFILES_DIR/setup/ubuntu/install-mise.sh"
mise -C "$MISE_CONFIG_DIR" exec -- \
  "$DOTFILES_DIR/setup/ubuntu/install-neovim-dependencies.sh" "$PROFILE"
"$DOTFILES_DIR/setup/nvim/link-config.sh"
mise -C "$MISE_CONFIG_DIR" exec -- \
  "$DOTFILES_DIR/setup/nvim/bootstrap.sh" "$PROFILE"
```

The mise step gives a personal development machine the same runtimes as macOS.
Controlled `mise exec` exposes those runtimes immediately without inheriting a
project-local config. Skip the mise step on a generic `core` server that
intentionally uses system-managed runtimes. The export keeps newly installed
user-local commands visible to the current shell.

See [`setup/ubuntu/README.md`](setup/ubuntu/README.md) for profile selection,
idempotence checks, and the safe path when an existing clone has changes.

## Current Personal Mac Symlinks

These are the active symlinks on this Mac.

| Tool | Live path | Dotfiles source | Status | Notes |
| --- | --- | --- | --- | --- |
| AeroSpace | `~/.config/aerospace/aerospace.toml` | `config/aerospace/aerospace.toml` | Linked file | Only `aerospace.toml` is linked; monitor IDs and app-to-workspace rules are machine-specific. Includes Ghostty tiling workaround. |
| btop | `~/.config/btop` | `config/btop` | Linked dir | Uses custom Nord theme `hamel-nord.theme`. |
| fastfetch | `~/.config/fastfetch` | `config/fastfetch` | Linked dir | Uses the anon logo config. |
| Ghostty | `~/Library/Application Support/com.mitchellh.ghostty/config` | `config/ghostty/config` | Linked file | Matches Zed's Maple Mono NF and Hamel Nord Blur appearance. |
| Karabiner | `~/.config/karabiner` | `config/karabiner` | Linked dir | Personal Mac should be 1:1 with dotfiles. |
| mise | `~/.config/mise` | `config/mise` | Linked dir | Global toolchain config. |
| Neovim | `~/.config/nvim` | `config/nvim` | Linked dir | Lua config, plugins, keymaps, LSP, and Hamel Nord. |
| Herdr | `~/.config/herdr/config.toml` | `config/herdr/config.toml` | Linked file | Only config is linked; runtime state stays local. |
| Zed settings | `~/.config/zed/settings.json` | `config/zed/settings.json` | Linked file | User-owned Zed settings. |
| Zed keymap | `~/.config/zed/keymap.json` | `config/zed/keymap.json` | Linked file | User-owned Zed keybindings. |
| Zed themes | `~/.config/zed/themes` | `config/zed/themes` | Linked dir | Custom Zed themes. |

## Link Current Mac Config

Use this pattern when setting up a new Mac or repairing symlinks. It backs up anything already at the live path before linking.

```bash
backup_and_link() {
  local src="$1"
  local dest="$2"
  local backup

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "already linked: $dest -> $src"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup="$dest.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$dest" "$backup"
    echo "backup: $backup"
  fi

  ln -s "$src" "$dest"
  echo "linked: $dest -> $src"
}

DOTFILES="$HOME/Developer/dotfiles-hd"

backup_and_link "$DOTFILES/config/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
backup_and_link "$DOTFILES/config/btop" "$HOME/.config/btop"
backup_and_link "$DOTFILES/config/fastfetch" "$HOME/.config/fastfetch"
backup_and_link "$DOTFILES/config/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
backup_and_link "$DOTFILES/config/karabiner" "$HOME/.config/karabiner"
backup_and_link "$DOTFILES/config/mise" "$HOME/.config/mise"
backup_and_link "$DOTFILES/config/nvim" "$HOME/.config/nvim"
backup_and_link "$DOTFILES/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
backup_and_link "$DOTFILES/config/zed/settings.json" "$HOME/.config/zed/settings.json"
backup_and_link "$DOTFILES/config/zed/keymap.json" "$HOME/.config/zed/keymap.json"
backup_and_link "$DOTFILES/config/zed/themes" "$HOME/.config/zed/themes"
```

## Existing Bootstrap Scripts

Personal mise toolchain:

```bash
~/Developer/dotfiles-hd/setup/mise/bootstrap.sh personal
```

On Ubuntu, use `setup/ubuntu/install-mise.sh`; it installs a missing mise command
with APT before calling the shared command.

Zed:

```bash
~/Developer/dotfiles-hd/config/zed/link-zed-config.sh
```

This links Zed settings, keymap, themes, and exposes Codex skills to Zed through `~/.agents/skills`.

### Switch Zed Themes

1. Open the command palette with `Cmd+Shift+P`.
2. Run `settings profile selector: toggle`.
3. Select `Hamel Nord` for the opaque theme or `Hamel Nord Blur` for the blurred theme.

The profiles also apply their matching sidebar and scrollbar settings.

### Change Zed Blur Opacity

Zed colors use `#RRGGBBAA`; the final two digits control opacity. The current value is `#3b4252ed`, where `ed` is 237/255, or 92.9%.

To choose another opacity, calculate `round((percentage / 100) × 255)` and convert the result to two-digit hexadecimal. Update `background`, `status_bar.background`, `title_bar.background`, and `title_bar.inactive_background` in both:

- `config/zed/themes/hamel-nord-blur.json`
- The `Hamel Nord Blur` theme override in `config/zed/settings.json`

Herdr:

```bash
~/Developer/dotfiles-hd/config/herdr/link-herdr-config.sh
```

This links only `~/.config/herdr/config.toml`.

## Not Linked By Default

| Area | Why |
| --- | --- |
| `~/.config/tmux` | The live directory contains plugins. Link/review `tmux.conf`, not the whole folder. |
| `~/.gitconfig` | Live config differs from repo. Review before linking. |
| `~/.config/herdr` | Contains logs, sockets, release notes, and session state. Link only `config.toml`. |
| `~/.config/raycast` | Raycast has extension/runtime state. Treat `config/raycast` as exports, not a live symlink target. |
| `~/.config/zed` | Contains prompt database state. Link settings, keymap, and themes only. |
| `~/.config/zed/prompts` | Zed runtime database state, not portable config. |
| `~/Library/Application Support/Zed` | App runtime state, not portable config. |
| `~/.config/1Password`, `~/.config/op`, `~/.config/gh`, `~/.config/cagent` | Credential, auth, or app-managed state. Do not link without a specific reason. |
| Terminal configs | Link only for tools actively used on the current machine. |
