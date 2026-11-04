# Rex

Rex Beta bindings copied from the M3 Max MacBook Pro's live
`~/.config/rex/init.lua`. The shared file also loads the optional image paste helper below.

Press **Ctrl+B**, release it, then press the key below.

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

Escape goes straight to programs such as Neovim. Ctrl+B opens a one-shot
shortcut menu. An unknown shortcut key leaves the menu waiting; Escape sends a
literal Escape and leaves the menu.

The current beta has no tmux-style copy-mode action (`Ctrl+B [` followed by
`v` and `y`). Use Rex's text selection and **Cmd+C**. The tmux navigator plugin
also has no direct Rex equivalent. `Ctrl+h/j/k/l` remain available to Neovim;
use Ctrl+B and an arrow key to move between Rex panes.

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

## Remote screenshot paste

The shared `init.lua` enables **Command + Shift + V** when the optional
[rex-image-paste helper](https://github.com/pablasso/rex-image-paste) is installed.
Install the helper on the Mac taking the screenshot, such as the Air. Other
hosts can load the shared config without installing it.

### How it works

A screenshot taken on the Air is not a file the Pro's Codex can open.
The helper supplies a Pro-side copy:

1. Read the image from the Air's clipboard.
1. Send it through Rex's existing connection into a temporary file on the Pro.
1. Check the copied file's SHA-256 checksum.
1. Paste the Pro file path into the focused Codex prompt.

The transfer uses a short-lived hidden terminal on the remote host. It needs
no SSH connection or additional remote package. Repeated pastes reuse the
copied image, and old helper images are cleaned up on later pastes.
The helper inserts an attachment; it does not press Enter.

### Install on the screenshot client

Use the reviewed upstream commit
[`1d883efb5d348477796733555306f2e445a3593e`](https://github.com/pablasso/rex-image-paste/tree/1d883efb5d348477796733555306f2e445a3593e).
This is a Rex configuration plugin; it needs no compiler or project runtime.

For a new installation, run on the Air:

```bash
rex_plugin_dir="$HOME/.config/rex/rex-image-paste"
git clone https://github.com/pablasso/rex-image-paste "$rex_plugin_dir" &&
  git -C "$rex_plugin_dir" checkout --detach 1d883efb5d348477796733555306f2e445a3593e &&
  rex config check ~/.config/rex/init.lua &&
  rex config reload
```

If the directory already exists, inspect it before changing it. A pinned-file
installation without Git metadata is also valid; its `init.lua` SHA-256 is
`8f4278ae57a44b249d326702da71586142cb9bb7af55dedd1ebc8afc6520c8c5`.

Keep the plugin beside the `~/.config/rex/init.lua` symlink, as upstream
documents. Dotfiles delivers the shared binding; the plugin installation
remains an explicit client-side step. Rex hosts, credentials, sessions, and
application state stay machine-owned.

### Use

1. In the Pro-hosted Codex prompt, type or paste the question first.
1. On the Air, copy a screenshot to the clipboard.
1. Click back into the Pro prompt and press **Command + Shift + V**.
1. Wait for **[Image #1]**, then press **Enter**.

This order was checked with Codex 0.166.0: an Air image reached the Pro and
Codex correctly described its colored shapes.

The standard region-to-clipboard shortcut is **Control + Command + Shift + 4**.
For a simpler key, set **Copy picture of selected area to the clipboard** to
**Option + 4** in macOS Keyboard Shortcuts > Screenshots.
That shortcut is a local macOS preference, not delivered by dotfiles.
See [Apple's screenshot guide](https://support.apple.com/guide/mac-help/take-a-screenshot-mh26782/mac).

The helper defaults to a 2000-pixel longest edge and a 25-second transfer
timeout. Native screenshot-thumbnail drag-and-drop into the Pro pane still
depends on Rex adding remote file-drop support.
