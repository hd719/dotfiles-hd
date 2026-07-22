# Obsidian Plugin Research

Checked 2026-07-14. No Obsidian plugin was installed or configured.

## Answer

Yes. The leading maintained Neovim plugin is
[obsidian-nvim/obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim),
a community-maintained successor to `epwalsh/obsidian.nvim`. The current stable
release is
[v3.16.5](https://github.com/obsidian-nvim/obsidian.nvim/releases/tag/v3.16.5),
released June 25, 2026, and
[development continued in July](https://github.com/obsidian-nvim/obsidian.nvim/commits/main/).

The [original repository](https://github.com/epwalsh/obsidian.nvim) is not
technically archived, but its latest release is
[v3.9.0 from July 2024](https://github.com/epwalsh/obsidian.nvim/releases/tag/v3.9.0).
It has only had isolated commits since then. Use the community successor, not
the original repository.

[IlyasYOY/obs.nvim](https://github.com/IlyasYOY/obs.nvim) is another current
option, but its own README calls it a work in progress and its first release was
July 12, 2026. It is too new to recommend over the established successor.

## What It Provides

- Vault-aware link following, backlinks, tags, search, quick switch, and table
  of contents.
- Wiki-link, tag, and footnote completion through an in-process LSP.
- Daily notes, templates, image paste, attachment handling, and opening a note
  in the Obsidian app.
- LSP references, rename, code actions, symbols, and folding.
- Optional Obsidian Sync support. It is disabled by default.

The project explicitly describes itself as a complement to Obsidian, not a
replacement for the app or its graph and mobile features. See the
[feature and command list](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/README.md#-features).

## Fit With This Neovim Config

| Existing component     | Fit                                                                                                                                                                                                                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Neovim 0.12.4          | Good. The v3.16.5 runtime check requires 0.11 and recommends 0.12, despite an older 0.10 claim still present in the README. See the [health check](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/lua/obsidian/health.lua#L107-L123).                                                                             |
| `lazy.nvim`            | Good. The project documents a release-pinned Lazy spec and recommends stable releases over `main`.                                                                                                                                                                                                                             |
| ripgrep                | Good. It is already required here and powers Obsidian search features.                                                                                                                                                                                                                                                         |
| Snacks picker          | Good. `snacks.picker` is a supported picker and is already enabled in [navigation.lua](lua/plugins/navigation.lua).                                                                                                                                                                                                            |
| Snacks image           | Good. It is the plugin's supported inline-image backend. Obsidian-style attachment paths need the documented [resolver hook](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/docs/Images.md#inline-image-viewing). PDFs are excluded from Snacks and routed to Bookokrat; Obsidian attachment links use `vim.ui.open` by default. |
| `blink.cmp`            | Good. The plugin exposes completion through LSP, and this config already includes `lsp` in Blink's default sources in [lsp.lua](lua/plugins/lsp.lua). No Markdown-specific override blocks it. See the [completion guide](https://github.com/obsidian-nvim/obsidian.nvim/wiki/Completion).                                     |
| Tree-sitter Markdown   | Compatible, but not required by the plugin. The existing parsers remain useful for highlighting and folding.                                                                                                                                                                                                                   |
| `render-markdown.nvim` | Good. obsidian.nvim detects it and skips its own legacy UI renderer, avoiding duplicate decorations. See [workspace.lua](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/lua/obsidian/workspace.lua#L160-L164).                                                                                                    |
| `mdformat`             | Independent. This config already installs frontmatter and Obsidian-wikilink extensions, and formatting remains manual.                                                                                                                                                                                                         |

`pngpaste` is only needed for `:Obsidian paste_img` on macOS. It is not
currently installed or listed in this repo's Brewfiles. Search, links, and
navigation do not need it. The dependency list is in the
[v3.16.5 README](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/README.md#system-requirements).

## Risks For This Vault

| Risk                              | Why it matters here                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Safe starting posture                                                                                                                            |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Frontmatter rewrites              | On every vault-buffer save, the plugin calls `update_frontmatter`; frontmatter management defaults on and sorts `id`, `aliases`, and `tags`. That can insert or re-serialize YAML. See [autocmds.lua](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/lua/obsidian/autocmds.lua#L88-L97) and [defaults](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/lua/obsidian/config/default.lua#L70-L85). This config's Escape-to-save makes the hook especially easy to trigger. | Start with frontmatter management disabled. This sacrifices frontmatter-aware aliases and tags until a vault-safe policy is designed.            |
| Accidental note creation          | Completion can create missing notes by default. New-note, daily, template, follow-link, and visual actions also write files. The default note ID is a random Zettelkasten ID, which does not match the vault's lowercase-with-dashes workflow. See [defaults](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/lua/obsidian/config/default.lua#L15-L40).                                                                                                                               | Start navigation-only with completion creation disabled. Keep using the vault's ingest workflows for authored notes.                             |
| Default `Enter` mapping           | The plugin maps normal-mode `Enter` to a smart action. On a paragraph it can create a checkbox because checkbox creation also defaults on. See [autocmds.lua](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/lua/obsidian/autocmds.lua#L55-L66) and the [checkbox defaults](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/lua/obsidian/config/default.lua#L416-L427).                                                                                                  | Disable the plugin's default keymaps and add only explicit, documented mappings later.                                                           |
| Link convention and privacy walls | Wiki links are the correct default, but the plugin uses the shortest path and does not enforce the vault's `_wiki` to `_private` one-way rule. Completion could suggest a private target while editing a public note. See the [link rules](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/docs/Link.md).                                                                                                                                                                             | Keep wiki style, but do not use generated links until path formatting and private/raw ignore filters are defined.                                |
| Broad refactors                   | Rename updates references across the vault, while file-rename auto-update is only confirmation-gated by default. This can touch many notes. See the [LSP rename behavior](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/docs/LSP.md#rename).                                                                                                                                                                                                                                        | Keep auto-update off. Avoid rename, move, merge, template, and attachment actions until tested on a clean Git tree.                              |
| Wrong workspace path              | The plugin creates a missing workspace directory automatically. See [workspace.lua](https://github.com/obsidian-nvim/obsidian.nvim/blob/v3.16.5/lua/obsidian/workspace.lua#L137-L158).                                                                                                                                                                                                                                                                                                            | Use `/Users/hameldesai/Developer/hd`, where `.obsidian` actually lives. Do not use `/Users/hameldesai/Developer/hd/Knowledge` as the vault root. |

## Recommendation

Use `obsidian-nvim/obsidian.nvim` only if vault-aware backlinks, navigation, and
completion are worth the extra behavior. It fits the current stack well, but it
should be added in a separate, reviewable change and pinned to a stable release.

For Hamel, the first configuration should be navigation-only: correct `hd`
vault root, Snacks picker, built-in UI off, plugin default keymaps off,
frontmatter management off, completion note creation off, link auto-update off,
sync off, and private/raw paths excluded from suggestions. Test it with
`:Obsidian check` and confirm a normal edit/save produces only the intended Git
diff before enabling any mutation feature.

## Implemented 2026-07-22

- Installed the maintained `obsidian-nvim/obsidian.nvim` fork at stable release
  `v3.16.5`; `lazy-lock.json` pins its exact commit.
- Adapted Salar's configuration instead of copying it verbatim because the
  linked plugin file delegates its options to a separate private helper module.
- Configured the actual vault root, `~/Developer/hd`, with the existing Snacks
  picker.
- Made `Space o` the discoverable Obsidian menu. The old external/PDF opener is
  preserved at `Space o e`.
- Disabled default plugin mappings and automatic mutation features. Private
  and work-only vault paths are excluded from pickers.
- `:checkhealth obsidian`, headless startup, workspace/mapping assertions, and
  a checksum-before-and-after save test passed. The only health warning is for
  the optional `ob` sync CLI; sync is intentionally disabled.
- Human checkpoint: restart Neovim, open a Markdown note in the `HD` vault,
  press `Space o`, then try `q` for quick switch or `s` for search.
