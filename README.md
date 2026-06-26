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
