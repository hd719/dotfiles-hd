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

## Personal Mac Config Inventory

This is the bootstrap target plus the explicitly noted existing manual link.

For a new personal Mac, use the backed-up, idempotent
[`Mac bootstrap runbook`](setup/mac-bootstrap/README.md) instead of copying the
link commands below by hand. The legacy `mac-vm` profile name is correct for
both a physical personal MacBook and a MacBook VM.

| Tool | Live path | Dotfiles source | Status | Notes |
| --- | --- | --- | --- | --- |
| Shell (MacBook) | `~/.zshrc` | `setup/mac-vm/zsh-config/.zshrc` | Bootstrap-managed link | Personal MacBook shell entry point. |
| Shell (Mac mini) | `~/.zshrc` | `setup/mac-mini/.zshrc` | Bootstrap-managed link | Mac mini shell entry point. |
| Login PATH | marker-owned block in `~/.zprofile` | `setup/mac-bootstrap/mise-shims.zsh` | Bootstrap-managed block | The rest of `.zprofile` remains user-owned. |
| AeroSpace | `~/.config/aerospace/aerospace.toml` | `config/aerospace/aerospace.toml` | Existing manual link | Not installed or linked by the new-Mac bootstrap because the app is not in its reviewed Brewfiles. |
| btop | `~/.config/btop` | `config/btop` | Linked dir | Uses custom Nord theme `hamel-nord.theme`. |
| fastfetch | `~/.config/fastfetch` | `config/fastfetch` | Linked dir | Uses the anon logo config. |
| Ghostty | `~/Library/Application Support/com.mitchellh.ghostty/config` | `config/ghostty/config` | Linked file | Matches Zed's Maple Mono NF and Hamel Nord Blur appearance. |
| Karabiner | `~/.config/karabiner` | `config/karabiner` | MacBook-only linked dir | The Mac mini profile does not link it. |
| mise | `~/.config/mise` | `config/mise` | Linked dir | Global toolchain config. |
| Neovim | `~/.config/nvim` | `config/nvim` | Linked dir | Lua config, plugins, keymaps, LSP, and Hamel Nord. |
| Herdr | `~/.config/herdr/config.toml` | `config/herdr/config.toml` | Linked file | Only config is linked; runtime state stays local. |
| Zed settings | `~/.config/zed/settings.json` | `config/zed/settings.json` | Linked file | User-owned Zed settings. |
| Zed keymap | `~/.config/zed/keymap.json` | `config/zed/keymap.json` | Linked file | User-owned Zed keybindings. |
| Zed themes | `~/.config/zed/themes` | `config/zed/themes` | Linked dir | Custom Zed themes. |

## Repair an Individual Link

Use this only to repair one existing link. New Macs use the personal-Mac
bootstrap above. Choose a source listed for the target machine; MacBook-only
sources such as Karabiner do not belong on the Mac mini. This example repairs
only the shared Neovim link and backs up anything already at the live path.

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

backup_and_link "$DOTFILES/config/nvim" "$HOME/.config/nvim"
```

## Existing Bootstrap Scripts

Personal Apple Silicon Mac:

```bash
setup/mac-bootstrap/bootstrap.sh --profile mac-vm --dry-run
setup/mac-bootstrap/bootstrap.sh --profile mac-vm --apply
setup/mac-bootstrap/doctor.sh --profile mac-vm
```

The Mac mini uses `--profile mac-mini`. Read the
[`Mac bootstrap runbook`](setup/mac-bootstrap/README.md) first; the current Mac
mini has a production-runtime boundary and must not be restarted by bootstrap
work.

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
