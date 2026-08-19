# Thin Mac Control Plane

Supported setup path for Hamel's Apple Silicon MacBook after the 2026 restore.
macOS is a control plane; the Ubuntu ARM64 VM owns development.

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
- Ghostty fonts
- Herdr as a remote Ubuntu client
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
- Vagrant and the VMware utility
- VLC
- VMware Fusion
- Zoom
- Zoxide
- Zsh Autosuggestions and Syntax Highlighting
- macOS SSH

Do not install project repositories, Docker, databases, project compilers,
language runtimes, other language servers, or project dependencies on macOS.

## Install

Prerequisites are Xcode Command Line Tools, Homebrew, the canonical
`~/Developer/dotfiles-hd` checkout, and restored `~/.ssh`. The bootstrap
installs Rosetta 2 when needed by Vagrant's VMware utility.

Preview and audit first:

```bash
hosts/thin-mac/bootstrap.sh --dry-run
hosts/thin-mac/bootstrap.sh --check
```

Apply from a clean canonical checkout, then repeat to prove idempotency:

```bash
hosts/thin-mac/bootstrap.sh --apply
hosts/thin-mac/bootstrap.sh --apply
hosts/thin-mac/doctor.sh
```

The bootstrap installs the policy packages, including the Codex CLI, and pins
the `vagrant-vmware-desktop` provider to `3.0.5`. Chezmoi delivers Bookokrat,
Fastfetch, the thin `.zshrc`, Ghostty, Herdr, Hunk, the shared Neovim config,
and the shared Starship config. Replaced paths are captured in the timestamped
Chezmoi backup printed during apply.

Sync reviewed `master` across the thin Mac, Ubuntu VM, and Mac mini from this
control plane:

```bash
hosts/thin-mac/sync-dotfiles.sh
```

## Adding Another CLI Tool

Fastfetch is the reference pattern:

1. Add the formula to `hosts/thin-mac/Brewfile`.
2. Keep declarative configuration under `config/`.
3. Add only approved child files to `chezmoi/profiles/mac-thin.paths`.
4. Adjust `.chezmoiignore.tmpl` for the `mac-thin` profile.
5. Update the doctor, focused tests, and this package inventory.

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
another plugin. Run `v` with no path for the shared Snacks dashboard and anon
mask; `v .` opens the current directory in Oil instead. Opening a PDF launches
Bookokrat instead of Snacks' image converter. `Space t` opens a bottom
terminal and `Space T` opens a floating terminal.

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
- VMware Fusion is not available as a current Homebrew cask. Download it
  through Broadcom's official flow:
  <https://knowledge.broadcom.com/external/article/315638/download-and-install-vmware-fusion.html>.

The doctor remains red until both applications exist in `/Applications`.

## First Run

1. Sign in to 1Password, Tailscale, Obsidian, and ChatGPT.
1. Grant Tailscale's requested network-extension permission.
1. Connect Hermes Desktop to `mac-mini-ts` with its **Connect via SSH** mode.
1. Complete VMware Fusion's one-time privileged setup.
1. Build the Ubuntu VM with `uvm-up` and keep VMware Fusion open.
1. Add `ubuntu-vm-ts` to Codex connections as the primary development route.
   Keep `ubuntu-vm` as the local VMware fallback.
1. Open Neovim once and run `:checkhealth`, `:checkhealth obsidian`, and
   `:checkhealth vim.lsp`.
1. Keep repositories and all development execution on the guests' native Linux
   filesystems.

The bootstrap never restores credentials, starts services, removes packages,
or installs project development tooling. It adds only the portable Git alias
include to the machine-owned global Git config.

The remaining Bash is operational: Rosetta, Vagrant/VMware lifecycle, package
installation, maintenance, doctors, and fallback operations. It is not a
second configuration-link writer.

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
hu           Attach Herdr through local Vagrant
hut          Attach Herdr through Tailscale
u            SSH into the Ubuntu VM
ut           SSH into Ubuntu through Tailscale
uvm-up       Start the Vagrant VM with the VMware GUI
uvm-stop     Gracefully halt the Vagrant VM
uvm-suspend Suspend the Vagrant VM
uvm-resume  Resume the Vagrant VM
uvm-status  Show Vagrant VM state
uvm-ip      Show the Vagrant guest addresses
uvm-destroy Interactively destroy only the Vagrant VM
```

Press `Ctrl-D` to leave the SSH session. `uvm-destroy` never uses Vagrant's
force flag and does not reference the legacy VMware VM.

The Vagrant local route is fixed at `127.0.0.1:2222`, so it works without
Tailscale or local networking. The remote route uses Tailscale MagicDNS.
`hosts/thin-mac/ssh/ubuntu-vagrant.conf` keeps host-key checking on and disables
agent forwarding.

Herdr runs on macOS only as a thin client for the Ubuntu server. Use `hu`
locally or offline and `hut` through Tailscale. To send an image, copy it in
Finder with `Cmd-C`, or capture directly to the clipboard with
`Shift-Cmd-Ctrl-4`, then press `Ctrl-V` inside remote Herdr. A dragged Finder
path remains Mac-local and is not readable inside Ubuntu.

Running plain `herdr` on the thin Mac focuses an existing local workspace for
the current directory or creates one there when needed. Repeated launches from
the same directory reuse its workspace.

After a fresh Ghostty launch, the thin-Mac host override opens one window with
`hu`, `hmini`, and local `herdr` tabs in that order. It disables macOS window
state restoration and full-screen startup so a prior layout cannot replace this
control-plane default.

The Ubuntu VM generates separate VM-local keys for GitHub `hd719`, Arbiter, and
Forgejo. No Git private key is copied from the Mac.

## No-Agent Operations Fallback

If Codex, Claude, or another interactive agent is unavailable, run the tracked
fallback directly from the canonical dotfiles checkout:

```bash
~/Developer/dotfiles-hd/hosts/thin-mac/ops-fallback.sh personal-ready
~/Developer/dotfiles-hd/hosts/thin-mac/ops-fallback.sh home-lab-ready
~/Developer/dotfiles-hd/hosts/thin-mac/ops-fallback.sh home-lab-ready 2026-08-10 2026-08-17
~/Developer/dotfiles-hd/hosts/thin-mac/ops-fallback.sh home-lab-recover
```

The commands run unattended and save timestamped Markdown reports under
`~/Desktop/Ops Fallback Reports/`. Home-lab readiness also saves its existing
Mac mini brief with a `-manual.md` suffix. Recovery automatically performs only
the documented service starts and verified PostgreSQL repairs. It stops for
credentials, router settings, HomeKit pairing, ACLs, firmware, destructive
actions, and unknown states.

`personal-ready` inspects Homebrew tap trust without changing it, always runs
`brew update` followed by `brew upgrade`, runs normal `goodMorning` on the Mac
mini, and reruns the thin-Mac doctor. Normal mode also removes the Zoom folder
and runs the cooldown-protected Downloads and `.DS_Store` cleanup. It selects
Tailscale or LAN before updating and never replays a failed maintenance command.
Cortana updates may restart only affected Cortana services through the repo-owned
`runtime:post-merge`; broad restarts and Hermes upgrades remain excluded.
The `personal-mac-ops` skill uses this same command as its canonical Default
Readiness runner, so agent and direct CLI runs share one implementation.
If the Ubuntu updater fails, the saved report preserves its most precise named
failure stage and exit code.

Run the focused offline test after changing the fallback:

```bash
bash hosts/thin-mac/tests/ops-fallback-test.sh
```

The implementation is split into commented Bash modules under
`hosts/thin-mac/ops-fallback/`. Start with
[`ops-fallback/README.md`](ops-fallback/README.md) for the command-to-module
map. The public commands stay in `ops-fallback.sh`; fallback-owned parsing uses
Bash, `curl`, and `jq` rather than embedded Python.

This is an explicit allowlist. Node/Bun/Go, Docker, Kubernetes, project
toolchains, VS Code, tmux, other language servers, and development aliases
remain inside the Linux VMs.

The shell is assembled from scoped modules:

- `config/zsh/shared/` provides portable Git, navigation, SSH, and reload helpers.
- `config/zsh/shared/codex-aliases.zsh` provides personal Mac and Linux Codex
  shortcuts.
- `config/zsh/mac/personal/codex-functions.zsh` provides the interactive Codex
  archive picker on personal Macs.
- `config/zsh/mac/aliases.zsh` adds safe macOS controls.
- `config/zsh/mac/personal/aliases.zsh` adds the vault control.
- `hosts/thin-mac/vm.zsh` stays host-specific and owns VMware shortcuts.
