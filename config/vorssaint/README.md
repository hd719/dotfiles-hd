# Vorssaint settings

`settings.plist` is a manual settings backup exported by Vorssaint 3.4.3 on
the M3 Max MacBook Pro using the app's `--export-settings` command.

The built-in format includes portable settings and registered defaults. The
export was reviewed before committing: clipboard contents, Shelf items,
Command Bar history and its local key, agent-profile paths, and folder access
bookmarks are excluded. Never commit the raw preferences domain, application
support directory, caches, credentials, or private content.

Vorssaint is no longer installed by the `mac-pro` Brewfile. This snapshot is
preserved for a deliberate future reinstall; no profile links or imports it.

## Restore when explicitly requested

Install Vorssaint from its official source and quit it before importing.
Back up any existing setup with its Export settings control first. Use
Settings → Advanced → Import settings to select this file, or the app's CLI:

```sh
/Applications/Vorssaint.app/Contents/MacOS/Vorssaint --import-settings "$HOME/Developer/dotfiles-hd/config/vorssaint/settings.plist"
```

Import replaces the app's portable settings with this saved setup. Review its
launch-at-login and keep-awake behavior before using it on a server.
