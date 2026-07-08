# Dotfiles

## Zed

Zed user-owned config lives in `config/zed` and should be treated as the source of truth.

Bootstrap/sync on macOS:

```bash
~/Developer/dotfiles-hd/config/zed/link-zed-config.sh
```

This links:

- `~/.config/zed/settings.json` -> `config/zed/settings.json`
- `~/.config/zed/keymap.json` -> `config/zed/keymap.json`
- `~/.config/zed/themes` -> `config/zed/themes`
- `~/.agents/skills/*` -> matching skills under `~/.codex/skills`, including nested `.system` skills exposed directly for Zed

It intentionally leaves `~/.config/zed/prompts` and `~/Library/Application Support/Zed` alone because those are runtime/user-state databases rather than portable config.

## Herdr

Herdr user-owned config lives in `config/herdr` and should be treated as the source of truth.

Bootstrap/sync on macOS:

```bash
~/Developer/dotfiles-hd/config/herdr/link-herdr-config.sh
```

This links:

- `~/.config/herdr/config.toml` -> `config/herdr/config.toml`

It intentionally leaves Herdr logs, sockets, plugin state, and session state under `~/.config/herdr` alone because those are runtime state.
