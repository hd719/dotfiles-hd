# Rex

Rex Beta bindings copied from the M3 Max MacBook Pro's live
`~/.config/rex/init.lua`. The file contains keyboard bindings only.

Press **Escape**, release it, then press the key below.

| Key        | Action                          |
| ---------- | ------------------------------- |
| `s` / `v`  | Split below / to the right      |
| `r`        | Reload the Rex configuration    |
| `c`        | New tab (tmux window)           |
| `n` / `p`  | Next / previous tab             |
| `1`–`9`    | Select a tab, counting from one |
| Arrow keys | Focus a pane                    |
| `o`        | Focus the next pane             |
| `z`        | Toggle pane zoom                |
| `x`        | Close the pane                  |
| `,` / `$`  | Rename the tab / session        |
| Escape     | Send Escape to the terminal     |

Rex uses a one-shot key mode so pressing Escape twice sends Escape to programs
such as Neovim. An unknown prefix key leaves the mode waiting; Escape sends a
literal Escape and leaves the mode.

The current beta has no tmux-style copy-mode action (`Escape [` followed by
`v` and `y`). Use Rex's text selection and **Cmd+C**. The tmux navigator plugin
also has no direct Rex equivalent. `Ctrl+h/j/k/l` remain available to Neovim;
use Escape and an arrow key to move between Rex panes.

## Air delivery

The `mac-air` profile links only `~/.config/rex/init.lua` to this file through
Chezmoi. Existing configuration is backed up before apply; other files in
`~/.config/rex` stay machine-owned. Rex's host list, credentials, preferences,
and session data are not tracked or copied.

Install Rex using the [Air runbook](../../hosts/mac-air/README.md), then
apply that profile. After an approved change, run these commands locally:

```sh
rex config check ~/Developer/dotfiles-hd/config/rex/init.lua
rex config reload
```

Rex's configuration and key-mode behavior are documented in the
[configuration guide](https://www.superlogical.com/rex/docs/customize/config)
and [key-mode guide](https://www.superlogical.com/rex/docs/customize/key-modes).
