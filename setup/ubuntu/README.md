# Ubuntu Workstation

Ubuntu 26.04 ARM64 is the primary development workstation. The thin Mac runs
Vagrant and VMware Fusion only as its control plane.

## Rebuild

Prerequisites on the thin Mac:

- VMware Fusion is installed and its first-run setup is complete.
- `setup/mac-thin/bootstrap.sh --apply` has installed Vagrant, the VMware
  utility, and the pinned provider.
- `~/.ssh/id_ed25519_ubuntu_vm.pub` exists.
- The tailnet policy defines `tag:ubuntu-dev` and lets `hd719@github` connect
  to that tag as the `hamel` user.

The Forgejo Tailscale route also requires ordinary network access from Ubuntu
to TrueNAS. Add this rule to the tailnet policy's `acls` array:

```json
{
  "action": "accept",
  "src": ["tag:ubuntu-dev"],
  "proto": "tcp",
  "dst": ["tag:truenas-scale:30143"],
}
```

This does not belong in the `ssh` section: Forgejo uses normal SSH on TCP
`30143`. Keep `forgejo-truenas-lan` as the fallback route.

Create an optional one-time, preauthorized Tailscale auth key. Enter it without
putting it in shell history:

```zsh
read -rs "TAILSCALE_AUTH_KEY?One-time Tailscale key: "
export TAILSCALE_AUTH_KEY
uvm-up
unset TAILSCALE_AUTH_KEY
```

Keep VMware Fusion open while the VM runs. Without an auth key, provisioning
still succeeds and localhost SSH works; join Tailscale later with
`sudo tailscale up --hostname=ubuntu-dev --advertise-tags=tag:ubuntu-dev --ssh`.
With an auth key, Vagrant requests that tag and enables Tailscale SSH by
default. Override only the tag with `UBUNTU_VM_TAILSCALE_TAG` when needed.

`vagrant up` performs this flow:

```text
Bento Ubuntu 26.04 ARM64
  -> Ubuntu ansible-core package
  -> Ansible system and user configuration
  -> mise tools and dotfile links
  -> doctor.sh --offline
```

The box is pinned to `bento/ubuntu-26.04` version `202606.01.0`. VMware creates
a full clone with 10 vCPUs, 25 GB RAM, and a 250 GB virtual disk under the
existing `~/Virtual Machines.localized/VMWIsoImages` directory. Shared folders
are disabled.

Vagrant provisions the current pushed Git branch. On `master`, the normal
rebuild stays on `master`. `DOTFILES_GIT_REF` can override this only for an
intentional test.

## First Onboarding

Provisioning prints three public keys. Register them with the matching service:

```bash
cat ~/.ssh/id_ed25519_hd719.pub
cat ~/.ssh/id_ed25519_arbiter_hd.pub
cat ~/.ssh/id_ed25519_forgejo_truenas.pub
```

Each key is VM-local, unencrypted, generated once, and selected by the
dotfiles-owned `~/.ssh/config`. The thin Mac does not forward its agent.

The local `hamel` console and sudo password is `0000`. SSH password login and
root login are disabled; SSH accepts only the Mac's existing Ubuntu public key.

After registration:

```bash
cd ~/Developer/dotfiles-hd
git remote set-url origin git@github.com:hd719/dotfiles-hd.git
git remote add arbiter git@github.com-arbiter:arbiter-hd/dotfiles-hd.git
gh auth login --hostname github.com --git-protocol ssh --web
test "$(gh api user --jq .login)" = "arbiter-hd"
codex login --device-auth
bash setup/ubuntu/doctor.sh
```

Secrets and `.env` files are restored manually from 1Password. Project
repositories are fresh clones. Containers, images, volumes, and databases are
not migrated.

## SSH Routes

Before the first `u` connection, compare the guest and scanned Ed25519 host-key
fingerprints from the thin Mac:

```bash
cd ~/Developer/dotfiles-hd/setup/ubuntu
vagrant ssh -c \
  'sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub'
ssh-keyscan -p 2222 127.0.0.1 2>/dev/null | ssh-keygen -lf -
```

Only when they match, replace the existing entry:

```bash
ssh-keygen -R ubuntu-dev
ssh-keyscan -p 2222 127.0.0.1 2>/dev/null \
  | awk '{$1="ubuntu-dev"; print}' >> ~/.ssh/known_hosts
```

The tracked SSH policy keeps host-key checking enabled:

| Alias          | Route                           |
| -------------- | ------------------------------- |
| `ubuntu-vm`    | `127.0.0.1:2222`                |
| `ubuntu-vm-ts` | Tailscale MagicDNS `ubuntu-dev` |

Use `u` locally with the Mac's Ubuntu key and `ut` through Tailscale SSH.

## Lifecycle

Run these on the thin Mac:

```text
uvm-up             Start with the VMware GUI
uvm-stop           Graceful Vagrant halt
uvm-suspend        Suspend
uvm-resume         Resume
uvm-status         Show Vagrant state
uvm-ip             Show guest addresses
uvm-destroy        Interactive VM destroy
```

VMware Fusion 26 must remain open while this VM runs. Once the VM is running,
use `uvm-status` and connect with `u` instead of starting it again. Stop or
suspend it with `uvm-stop` or `uvm-suspend`, not by quitting VMware Fusion.

`uvm-destroy` prints the Git key fingerprints when the guest is reachable,
reminds you to remove registered keys, and calls interactive `vagrant destroy`.
It never passes `-f` and cannot target the legacy VM.

Transfer files with `rsync` or `scp`; there is no host-mounted development
folder.

## Ownership

| Owner    | State                                                         |
| -------- | ------------------------------------------------------------- |
| Vagrant  | VM lifecycle, box version, resources, disk, and SSH transport |
| Ansible  | Ubuntu packages, user, services, Tailscale, and Git keys      |
| mise     | Pinned core runtimes; other development tools track latest    |
| dotfiles | User configuration, symlinks, and portable Git alias include  |
| doctor   | Final read-only acceptance check                              |

Managed links:

| Live path                              | Source                          |
| -------------------------------------- | ------------------------------- |
| `~/.zshrc`                             | `setup/ubuntu/.zshrc`           |
| `~/.config/ghostty/config`             | `setup/ubuntu/ghostty.conf`     |
| `~/.config/starship.toml`              | `config/starship/starship.toml` |
| `~/.gitignore_global`                  | `config/git/.gitignore_global`  |
| `~/.ssh/config`                        | `setup/ubuntu/ssh/config`       |
| `~/.config/bookokrat`                  | `config/bookokrat`              |
| `~/.config/btop`                       | `config/btop`                   |
| `~/.config/fastfetch`                  | `config/fastfetch`              |
| `~/.config/herdr/config.toml`          | `config/herdr/config.toml`      |
| `~/.config/hunk/config.toml`           | `config/hunk/config.toml`       |
| `~/.config/mise/config.toml`           | `setup/ubuntu/mise.toml`        |
| `~/.config/nvim`                       | `config/nvim`                   |
| `~/.config/tmux`                       | `config/tmux`                   |
| `~/.local/bin/codex`                   | `setup/ubuntu/bin/codex`        |
| `~/.local/graphql-lsp/bin/graphql-lsp` | `setup/ubuntu/bin/graphql-lsp`  |

Hunk is the canonical diff viewer on every profile. Use `hdiff`, `hstaged`,
`hshow`, or `hwatch`; the shell does not install a Git pager override.

Small Bash boundaries remain:

- `config/git/configure-aliases.sh` adds only the portable alias include and preserves
  machine-owned Git identity.
- `bootstrap-ansible.sh` installs only Ubuntu's `ansible-core`.
- `grow-root-filesystem.sh` grows Bento's partition to the Vagrant disk.
- `link-dotfiles.sh` preserves backup-safe symlink behavior.
- `setup-neovim.sh` manages the existing mise and Neovim workflow.
- `update-system.sh` performs later Ubuntu and tool updates.
- `doctor.sh` verifies the finished workstation.

Ansible installs Caskaydia Cove Nerd Font, Hasklug Nerd Font, and Maple Mono NF
for the Ubuntu user. Maple Mono NF is the first Ghostty font family, so it is
the terminal default; Hasklug remains the fallback.

## Verify

The offline doctor runs automatically during provisioning. It verifies local
state but skips Tailscale connectivity and external logins:

```bash
bash setup/ubuntu/doctor.sh --offline
```

The full doctor verifies Tailscale, the three local Git keys, four remote Git
routes, the Arbiter GitHub CLI login, and local Codex login status without
making a paid API request:

```bash
bash setup/ubuntu/doctor.sh
```

## Rebuild Safety

The Vagrant-managed VM is the supported workstation. No legacy VMware VM
remains as a rollback.

Before `uvm-destroy`:

1. Push every repository and confirm each worktree is clean.
1. Confirm required secrets are recoverable from 1Password.
1. Record the three Git public-key fingerprints printed by `uvm-destroy`.
1. Remove the old Git and Tailscale registrations only after the replacement
   VM passes the full doctor.

Rollback means reverting the unproven pin or provisioning change and rebuilding
the last known-good version from Git.

## Routine Maintenance

Inside Ubuntu:

```bash
bash setup/ubuntu/update-system.sh
bash setup/ubuntu/doctor.sh
```

The updater accepts only the SSH dotfiles origin, pulls `master` with
`--ff-only`, updates all APT packages, refreshes mise itself, reinstalls pinned
runtimes, upgrades every unpinned mise tool, restores locked Neovim plugins,
and updates `~/.local/bin/herdr` for the remote Mac client. Project manifests
and lockfiles are intentionally excluded.
Provisioning installs a scoped sudo rule for only the updater's exact APT
commands. Every other `sudo` command still requires authentication.
If it reports that a reboot is required, leave the SSH session and use
`uvm-stop` followed by `uvm-up`.

Routine maintenance does not change the pinned Bento box, VMware provider, or
reviewed mise runtime versions.

## Pinned Upgrades

Change pins deliberately in a reviewed branch:

- Bento box name, version, and matching `vmware.base_mac`:
  `setup/ubuntu/Vagrantfile`.
- Vagrant VMware provider: `setup/mac-thin/bootstrap.sh`, its doctor, and its
  tests.
- Development tools: `setup/ubuntu/mise.toml`.

A new Bento pin affects only a newly created VM. Before destroying the current
VM, run the repository tests and complete the rebuild-safety checks above.
Then rebuild, provision twice to prove idempotence, and run both doctors.

## Major Ubuntu Releases

Do not run `do-release-upgrade`. A major Ubuntu release is a fresh workstation
rebuild:

1. Update the Bento box and exact box version in a branch.
1. Update release-specific repositories, tests, and documentation.
1. Run the repository tests before destroying the current VM.
1. Rebuild with Vagrant and provision twice.
1. Complete Git, Tailscale, and Codex onboarding.
1. Run the offline and full doctors before resuming development.

If qualification fails, revert to the previous pins and rebuild the last
known-good release.
