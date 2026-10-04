# MacBook Air Thin Client

The Apple Silicon MacBook Air uses SSH to work on the development Mac and
Mac mini. Keep project tooling, Docker, databases, and runtimes on those hosts.

## Boundary

The host installs only:

- Homebrew
- 1Password
- Brave and Google Chrome
- Bookokrat for terminal PDF reading
- ChatGPT desktop app
- Codex CLI
- DaisyDisk
- Fastfetch for system summaries
- Ghostty
- Ghostty fonts, including Symbols Nerd Font for Yazi icons
- Herdr as a remote editor client
- Hermes Desktop as a remote Mac mini agent client
- Hunk as the local diff viewer
- iStat Menus
- lsd for file listings
- Marksman as the only local language server
- Mullvad VPN
- Neovim with the shared `thin` profile
- noTunes
- Obsidian
- Pearcleaner
- Raycast
- ripgrep
- Starship
- TablePlus
- Tailscale
- Tree-sitter CLI only to build Neovim's two Markdown parsers
- VLC
- Zoom
- Yazi as a floating terminal file manager for Neovim
- Zoxide
- Zsh Autosuggestions and Syntax Highlighting
- macOS SSH

Do not install project repositories, Docker, databases, project compilers,
language runtimes, other language servers, or project dependencies on macOS.

## Install

Prerequisites are Xcode Command Line Tools, Homebrew, the canonical
`~/Developer/dotfiles-hd` checkout, and machine-owned `~/.ssh`.

Preview and audit first:

```bash
hosts/mac-air/bootstrap.sh --dry-run
hosts/mac-air/bootstrap.sh --check
```

Apply from a clean canonical checkout, then repeat to prove idempotency:

```bash
hosts/mac-air/bootstrap.sh --apply
hosts/mac-air/bootstrap.sh --apply
hosts/mac-air/doctor.sh
```

The bootstrap installs the policy packages, including the Codex CLI.
Chezmoi delivers Bookokrat,
Fastfetch, the thin `.zshrc`, Ghostty, Herdr, Hunk, the shared Neovim config,
and the shared Starship config. Replaced paths are captured in the timestamped
Chezmoi backup printed during apply.

Sync reviewed `master` between this Mac and the Mac mini:

```bash
/Users/hameldesai/.codex/skills/dotfiles-sync/scripts/fallback.sh
```

The vault-owned `dotfiles-sync` skill is the single source for both agent and
manual syncs.

## Adding Another CLI Tool

Fastfetch is the reference pattern:

1. Add the formula to `hosts/mac-air/Brewfile`.
1. Keep declarative configuration under `config/`.
1. Add only approved child files to `chezmoi/profiles/mac-air.paths`.
1. Adjust `.chezmoiignore.tmpl` for the `mac-air` profile.
1. Update the doctor, focused tests, and this package inventory.

Do not link a whole configuration directory when it contains mutable or legacy
state. After merge, sync `master`, preview, apply twice, and run the doctor.
The approved Fastfetch parent stays mode `700` so Chezmoi preserves private
directory modes across shell umasks.

Neovim uses the shared `config/nvim` and `lazy-lock.json`, but
`DOTFILES_NVIM_PROFILE=thin` restores only the approved thin plugin set and the
Markdown parsers. The Tree-sitter CLI exists only to build those parsers.
Marksman is the only installed language server, but it stays off by default.
In a Markdown file, use `Space m m` to turn it on or off only for that file.
`Space e` opens the existing Snacks file-explorer sidebar; it does not add
another plugin. `Space -` opens Yazi in a floating window without replacing
Oil; Chezmoi links Hamel Nord theme files under `~/.config/yazi/`. Run `v`
with no path for the shared Snacks dashboard and anon mask; `v .` opens the
current directory in Oil instead. Opening a PDF launches Bookokrat instead of
Snacks' image converter. `Space t` opens a bottom terminal and `Space T` opens
a floating terminal.

Mutable state remains local: Herdr sessions, Hermes Desktop connection state,
Hunk state, Neovim plugins/cache/undo, Zoxide history, Zsh history, and
completion caches are never symlinked.

## Manual Applications

- ChatGPT is the supported Codex desktop app. The standalone Codex CLI is
  installed by the Brewfile. Install ChatGPT from
  <https://chatgpt.com/download/> when it is not already present.
- Hermes Desktop is a remote client for the Mac mini Hermes stack. The official
  macOS default is the signed DMG, but its installer also installs a local
  Hermes runtime. Keep the thin Mac remote-only: build the Desktop app from the
  Mac mini's pinned, clean Hermes checkout with `hermes desktop --build-only`,
  copy `apps/desktop/release/mac-arm64/Hermes.app` into `/Applications`, then use
  **Connect via SSH** with `mac-mini-ts`. Do not run the installer's **Install
  Hermes** action on the thin Mac. Keep its connection state machine-owned. See
  <https://hermes-agent.nousresearch.com/docs/user-guide/desktop>.
  The doctor requires ChatGPT and Hermes Desktop in `/Applications`.

## First Run

1. Sign in to 1Password, Tailscale, Obsidian, and ChatGPT.
1. Grant Tailscale's requested network-extension permission.
1. Connect Hermes Desktop to `mac-mini-ts` with its **Connect via SSH** mode.
1. Use your machine-owned SSH aliases for the Mini and development Mac.
   Configure the Studio route once that machine arrives.
1. Open Neovim once and run `:checkhealth`, `:checkhealth obsidian`, and
   `:checkhealth vim.lsp`.
1. Keep project repositories and development execution on the development Mac.

The bootstrap never restores credentials, starts services, removes packages,
or installs project development tooling. It adds only the portable Git alias
include to the machine-owned global Git config.

The remaining Bash owns package installation, maintenance, and doctors. It is not a second
configuration-link writer.

## Personal Shell Allowlist

Start a fresh shell after bootstrap, then use:

```text
g, gs        Git and Git status
hdiff        Review unstaged changes with Hunk
hstaged      Review staged changes with Hunk
hshow        Review the latest commit with Hunk
hwatch       Watch changes with Hunk
gpull        Pull the current repository
gpush        Push the current repository
cod          Codex CLI
coda          Choose and archive a Codex session
codr, codrl   Resume a Codex session
dots         Enter the Mac dotfiles repository
vault        Enter the Obsidian vault repository
hosts        List configured SSH hosts
ls, lss, lsss Show directory trees one, two, or three levels deep
l, la, ll    Show compact, hidden, or detailed lsd listings
r            Reload the Zsh configuration
v FILE, v .  Edit a local file or directory with the thin Neovim profile
```

Use `minit` (Tailscale) or `mini` (LAN) for SSH to the Mac mini. Keep SSH configuration and
credentials machine-owned. Add the Studio route after that host arrives.
Press `Ctrl-D` to leave an SSH session.

Running plain `herdr` on the thin Mac focuses an existing local workspace for
the current directory or creates one there when needed. Repeated launches from
the same directory reuse its workspace.

`hdk`, short for `herdr server reset`, clears the accumulated local workspaces
and leaves one fresh `home` workspace. It only touches the local server, so the
`hmini` client and their remote sessions are unaffected. Add
`--dry-run` to preview it.

After a fresh Ghostty launch, the thin-Mac host override opens a regular shell
with window state restoration and full-screen startup disabled. Run
`hmini` or local `herdr` manually when needed.

## Manual No-Agent Operations

Manual home-lab readiness, recovery, and maintenance now live in their
local-only deployed skills under `~/.codex/skills/`. Dotfiles no longer carries
duplicate operational logic.

This is an explicit allowlist. Node/Bun/Go, Docker, Kubernetes, project
toolchains, VS Code, tmux, other language servers, and development aliases
remain on the development Mac.

The shell is assembled from scoped modules:

- `config/zsh/shared/` provides portable Git, navigation, SSH, and reload helpers.
- `config/zsh/shared/codex-aliases.zsh` provides personal Mac and Linux Codex
  shortcuts.
- `config/zsh/shared/codex-functions.zsh` provides the interactive Codex archive
  picker on personal Macs and Linux workstations.
- `config/zsh/mac/aliases.zsh` adds safe macOS controls.
- `config/zsh/mac/personal/aliases.zsh` adds the vault control.
