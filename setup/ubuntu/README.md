# Ubuntu Workstation

Ubuntu 26.04 ARM64 is the primary development workstation. The thin Mac runs
Vagrant and VMware Fusion only as its control plane.

## Rebuild

Prerequisites on the thin Mac:

- VMware Fusion is installed and its first-run setup is complete.
- `setup/mac-thin/bootstrap.sh --apply` has installed Vagrant, the VMware
  utility, and the pinned provider.
- `~/.ssh/id_ed25519_ubuntu_vm.pub` exists.

Create an optional one-time, preauthorized Tailscale auth key. Enter it without
putting it in shell history:

```zsh
read -rs "TAILSCALE_AUTH_KEY?One-time Tailscale key: "
export TAILSCALE_AUTH_KEY
uvm-up
unset TAILSCALE_AUTH_KEY
```

Use `uvm-up-headless` instead when no VMware window is wanted. Without an auth
key, provisioning still succeeds and localhost SSH works; join Tailscale later
with `sudo tailscale up --hostname=ubuntu-dev-canary`.

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

During canary development, Vagrant provisions the current pushed Git branch.
On `master`, the normal rebuild stays on `master`. `DOTFILES_GIT_REF` can
override this only for an intentional test.

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
codex login --device-auth
bash setup/ubuntu/doctor.sh
```

Secrets and `.env` files are restored manually from 1Password. Project
repositories are fresh clones. Containers, images, volumes, and databases are
not migrated.

## SSH Routes

Before the first `uc` connection, compare the guest and scanned Ed25519 host-key
fingerprints from the thin Mac:

```bash
cd ~/Developer/dotfiles-hd/setup/ubuntu
vagrant ssh -c \
  'sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub'
ssh-keyscan -p 2222 127.0.0.1 2>/dev/null | ssh-keygen -lf -
```

Only when they match, replace the canary entry:

```bash
ssh-keygen -R ubuntu-dev-canary
ssh-keyscan -p 2222 127.0.0.1 2>/dev/null \
  | awk '{$1="ubuntu-dev-canary"; print}' >> ~/.ssh/known_hosts
```

The tracked SSH policy keeps host-key checking enabled:

| Alias                 | Route                              |
| --------------------- | ---------------------------------- |
| `ubuntu-vm-canary`    | `127.0.0.1:2222`                   |
| `ubuntu-vm-canary-ts` | Tailscale MagicDNS canary hostname |
| `ubuntu-vm`           | `127.0.0.1:2222` after cutover     |
| `ubuntu-vm-ts`        | Tailscale MagicDNS `ubuntu-dev`    |

Use `uc` and `uct` during qualification. Existing `u` and `ut` routes remain
unchanged until cutover.

## Lifecycle

Run these on the thin Mac:

```text
uvm-up             Start with the VMware GUI
uvm-up-headless    Start without a VMware window
uvm-stop           Graceful Vagrant halt
uvm-suspend        Suspend
uvm-resume         Resume
uvm-status         Show Vagrant state
uvm-ip             Show guest addresses
uvm-destroy        Interactive canary destroy
```

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
| mise     | Pinned runtimes, Neovim, Codex, and development tools         |
| dotfiles | User configuration and symlinks                               |
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

Small Bash boundaries remain:

- `bootstrap-ansible.sh` installs only Ubuntu's `ansible-core`.
- `grow-root-filesystem.sh` grows Bento's partition to the Vagrant disk.
- `link-dotfiles.sh` preserves backup-safe symlink behavior.
- `setup-neovim.sh` manages the existing mise and Neovim workflow.
- `update-system.sh` performs later Ubuntu and tool updates.
- `doctor.sh` verifies the finished workstation.
- `cleanup-legacy.sh` remains separate and destructive; Vagrant never runs it.

`setup.sh` remains temporarily for the unchanged legacy VM. Remove it only
after the 30-day rollback window.

## Verify

The offline doctor runs automatically during provisioning. It verifies local
state but skips Tailscale connectivity and external logins:

```bash
bash setup/ubuntu/doctor.sh --offline
```

The full doctor verifies Tailscale, the three local Git keys, four remote Git
routes, and local Codex login status without making a paid API request:

```bash
bash setup/ubuntu/doctor.sh
```

## Canary and Cutover

1. Stop the legacy VM before starting the 25 GB canary.
1. Build the canary and run `vagrant provision` a second time.
1. Run the full doctor after onboarding.
1. Use interactive `uvm-destroy`.
1. Repeat a clean build and all checks.
1. Rename the qualified Tailscale node to `ubuntu-dev`.
1. Put `Include ~/Developer/dotfiles-hd/setup/mac-thin/ssh/ubuntu-vagrant.conf`
   before the old Ubuntu blocks in `~/.ssh/config`.
1. Verify the new `ubuntu-dev` host key, then test `u` and `ut`.
1. Keep the legacy VM powered off for 30 days.

Rollback is simple: stop the canary, remove the new SSH include, and start the
unchanged legacy VMware VM.

## Update

Inside Ubuntu:

```bash
bash setup/ubuntu/update-system.sh
```

The updater accepts only the SSH dotfiles origin, pulls `master` with
`--ff-only`, runs APT maintenance, and refreshes mise and Neovim state.
