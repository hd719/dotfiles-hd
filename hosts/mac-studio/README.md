# Mac Studio

The Studio becomes the default native macOS development workstation for every
repository: editors, coding agents, worktrees, builds, tests, Docker workloads
and development databases. It also owns the main Obsidian vault and canonical
coding-prompt source after cutover.

This is pre-arrival staging for [issue #117](https://github.com/hd719/dotfiles-hd/issues/117).
Current M3 Max, Ubuntu and mini routing stays active until verified cutover.
Keep the M3 Max MacBook Pro until the Studio and migrated data are verified,
then trade it in. Studio completion does not wait for the future Air.

## Target Roles

| Host             | Role after cutover                                                            |
| ---------------- | ----------------------------------------------------------------------------- |
| Studio           | Default native development, main personal workstation and local AI            |
| Ubuntu on Studio | Powered-off preserved VM, backed up on NAS; manual use only                   |
| Mac mini         | Hermes/Cortana Services production; explicitly selected secondary development |
| Future Air       | Lightweight local clients; SSH and Screen Sharing into Studio; no VMware      |

Studio and Air use the personal Apple Account. Mini retains its dedicated
Apple Account. Remote Login, Screen Sharing, Tailscale enrollment, hostnames,
SSH keys, authentication, databases and Ollama models are machine-owned.

## On Arrival

Install Xcode Command Line Tools, Homebrew and VMware Fusion manually. Finish
Fusion's first-run setup without starting or creating Ubuntu. Clone this repo
at `~/Developer/dotfiles-hd`, then review:

```bash
hosts/shared/macos/bootstrap.sh --profile mac-studio --dry-run
hosts/shared/macos/bootstrap.sh --profile mac-studio --check
```

After hardware arrival and approval of the reviewed checks:

```bash
DOTFILES_MAC_STUDIO_ARRIVED=1 \
  hosts/shared/macos/bootstrap.sh --profile mac-studio --apply
hosts/shared/macos/doctor.sh --profile mac-studio
```

The arrival flag is a hard gate; set it only on Studio. Bootstrap installs the
shared native development tools, the Studio Brewfile and configuration. It
never starts Ubuntu, Colima, PostgreSQL or Ollama. Normal checks audit installed
packages/configuration without requiring any guest, Docker daemon, database
server, VMware utility service or Ubuntu SSH route to be online.

## Native Development

Homebrew and the shared mise configuration provide the native toolchain.
Studio adds Colima, Docker, Compose, Buildx, PostgreSQL 17, pgvector and VS Code.
Colima's small VM supplies Docker only; repositories and toolchains stay native
on Studio. [Colima setup](https://github.com/abiosoft/colima#installation)
requires a separate, deliberate `colima start` after installation.

Merge `/opt/homebrew/lib/docker/cli-plugins` into the machine-owned
`cliPluginsExtraDirs` array in `~/.docker/config.json` to enable `docker compose`
and `docker buildx`; preserve existing authentication and other settings.
See the [Homebrew Compose caveat](https://formulae.brew.sh/formula/docker-compose).
Verify `docker compose version`, `docker buildx version` and, after starting
Colima, `docker info`. Dotfiles does not rewrite Docker configuration or data.

The Studio shell exposes PostgreSQL 17 client tools. Homebrew creates its
initial empty cluster during package installation; project database setup,
restores and server startup remain deliberate project steps. Verify local
builds/tests and database access for the repositories being moved, including
Cortana Services. Never use the mini's production database for development.

Use `arbiter-hd` for Studio agent GitHub work, verify the actor before writes,
and preserve current-head `hd719` approval requirements before merging agent
PRs. Deploy to the mini through the existing reviewed deployment process.
For mini development isolation, follow its [runbook](../mac-mini/README.md).

## Preserve Ubuntu Before Trade-In

1. Inventory and back up repositories, uncommitted work, unpushed branches,
   development databases and other required data on the M3 Max and guest.
1. Halt Ubuntu cleanly through its current Vagrant workflow. Preserve the cold
   VMware bundle and associated Vagrant metadata on Studio, with a NAS backup.
   Verify archive integrity and record paths and restoration steps before
   surrendering the M3 Max. Do not delete the preserved VM or run two copies.
1. Move development work and required data into native Studio workspaces.
   Authenticate Studio tools with machine-local credentials; the archived
   guest's credentials are not Studio credentials. Verify against the inventory.
1. Leave Ubuntu off. Its restore boot, provider setup, identity changes or
   rebuild happen only when Hamel explicitly requests them later.

The normal profile installs Vagrant but defers its VMware utility, Rosetta
requirement and pinned `vagrant-vmware-desktop` 3.0.5 provider until Ubuntu is
requested. Restore and verify both VM and `.vagrant` metadata before using the
helpers. Adjust host-specific paths and provide the guest's expected login
public key through a reviewed restoration procedure; never overwrite keys.

The shell exposes `uvm-status`, `uvm-up`, `uvm-stop`, `uvm-suspend`, `uvm-resume`
and `uvm-ip`. Loading the shell does not invoke Vagrant. Start/resume refuse a
missing restored VM; `uvm-up` disables automatic provisioning. There is no
Studio destroy shortcut. These helpers are for deliberate manual use only.

If Ubuntu is later activated, manually configure its SSH routes using
`hosts/mac-studio/ssh/ubuntu-vagrant.conf` after verifying host fingerprints.
The old `DOTFILES_MAC_STUDIO_CUTOVER` online-VM check is no longer required.

## Cutover and Remote Acceptance

Before trading in the M3 Max:

- Verify native repository builds/tests, development data and both VM copies.
- Move the main vault/canonical prompt source to Studio through a verified
  cutover. Update canonical `machine-topology`, `dotfiles-sync`, `personal-ready`
  and `sync-coding-prompts` at that point, then use their normal sync workflow.
- Make Studio the default development destination; mini development requires
  explicit selection. Exclude dormant Ubuntu and the absent Air from mandatory
  online checks. Record accepted routes and rollback procedures without secrets.
- Test Studio SSH and Screen Sharing from the M3 Max, including away-from-home
  Tailscale access, sleep/reconnection and restart recovery.
- Keep Hermes/Cortana Services production on mini and verify its readiness.

Configure the future Air independently when it arrives, using the dedicated
[`mac-air` profile](../mac-air/README.md). Ollama model selection and activation
remain separate from base-host acceptance; its cache stays machine-owned.
