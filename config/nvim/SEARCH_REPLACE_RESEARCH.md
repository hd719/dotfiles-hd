# Search and Replace Research

Researched 2026-07-16 against the current dotfiles and primary sources.

## Recommendation

Add [grug-far.nvim](https://github.com/MagicDuck/grug-far.nvim) and map
`Space R` to **replace the word under the cursor in the current file**.

Why this fits:

- It provides editable Search and Replace fields plus a live diff before applying
  changes. The default Replace action is `localleader r`; this config already sets
  local leader to Space. ([usage](https://github.com/MagicDuck/grug-far.nvim#searching-and-replacing))
- Its official cookbook supports pre-filling the current word, limiting Paths to
  the current file, and jumping directly to the replacement input.
  ([cookbook](https://github.com/MagicDuck/grug-far.nvim#cookbook))
- The installed Neovim 0.12.4 and ripgrep 15.2.0 satisfy its Neovim 0.11+ and
  ripgrep 14+ requirements. ([requirements](https://github.com/MagicDuck/grug-far.nvim#%EF%B8%8F-requirements))
- `Space r` is already used to reload files, so capital `Space R` avoids changing
  an established mapping.

Proposed flow:

1. Search for `java`, leaving the cursor on a match.
2. Press `Space R`.
3. Type the replacement in the visual Replace field.
4. Review the diff, then press `Space r` inside Grug Far to apply it.

The mapping should pre-fill the word under the cursor, the current file path,
and ripgrep's `--fixed-strings --word-regexp` flags. Those flags treat the word
literally and avoid changing `javascript` when replacing `java`.
([ripgrep guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#common-options))

## Native Neovim Options

### Search, change, and repeat

After `/java`:

```text
cgnkotlin<Escape>
.
.
```

`gn` selects the current or next match, so `cgn` changes it. Each `.` repeats
that complete change at the next match. This is excellent for reviewing matches
one at a time, but tedious when the intention is truly “replace all.”
([`gn`](https://neovim.io/doc/user/visual/#gn),
[dot command](https://neovim.io/doc/user/repeat/#single-repeat))

### Shorter substitute after an existing search

After `/java`, the empty search section reuses the last search:

```vim
:%s//kotlin/gc
```

This is shorter than repeating `java` and keeps confirmation. Removing `c`
applies all changes immediately. Neovim documents that an empty substitute
pattern uses the previous search pattern and that `g` means every occurrence
per line. ([substitute docs](https://neovim.io/doc/user/change/#:substitute))

This remains the fastest no-plugin method, but it is still command syntax rather
than the simple visual workflow requested.

## Snacks.nvim

Snacks supplies the existing file, buffer, and grep pickers, but its official
picker API has no search-and-replace workflow. Its grep picker finds and opens
matches; it does not edit all matches. ([picker docs](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md),
[picker actions](https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/actions.lua))

Conclusion: keep `Space /` for project grep; do not try to turn Snacks into the
replacement UI.

## Kuncheng Gui's Current Dotfiles

At commit [`872094d`](https://github.com/kunchenguid/dotfiles/tree/872094dcee58df9ab9109fe92975ea911b9a970a),
Kuncheng maps Snacks to files, grep, buffers, and definitions only. His lockfile
does not include Grug Far, Spectre, or another replacement plugin.
([navigation.lua](https://github.com/kunchenguid/dotfiles/blob/872094dcee58df9ab9109fe92975ea911b9a970a/home/.config/nvim/lua/plugins/navigation.lua),
[lazy-lock.json](https://github.com/kunchenguid/dotfiles/blob/872094dcee58df9ab9109fe92975ea911b9a970a/home/.config/nvim/lazy-lock.json))

Conclusion: there is no Kuncheng replacement workflow to copy. Grug Far would
be a deliberate improvement for this config.
