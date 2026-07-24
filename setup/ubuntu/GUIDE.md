# Ubuntu Field Guide for a Mac User

This is the working guide for Hamel's Ubuntu development VM. It teaches the
Linux mental model behind the commands instead of treating Ubuntu like macOS
with different spellings.

The current workstation is Ubuntu 26.04 ARM64, Zsh, systemd, APT, mise, Docker,
Neovim, and tmux. The thin Mac is the control plane; development stays here.

## The 60-Second Orientation

From the Mac:

```bash
u                  # SSH into Ubuntu
exit               # Return to macOS
```

Inside Ubuntu:

```bash
pwd                # Where am I?
whoami             # Which user am I?
hostnamectl        # Which machine and OS?
uptime             # How long has it been running?
id                 # My UID, GID, and groups
```

The five systems to understand are:

1. **Filesystem** — everything has a path under `/`.
1. **Permissions** — users, groups, ownership, and mode bits control access.
1. **Processes** — every running program has a PID and receives signals.
1. **systemd** — starts, stops, and supervises system services.
1. **Package ownership** — APT owns system software; mise owns development
   tools; project package managers own project dependencies.

Use this document two ways:

- Need an answer now: use the quick card and troubleshooting ladder.
- Want mastery: read one section, run its read-only commands, then complete one
  practice drill.

## Quick Command Card

| Goal                    | Command                                        |
| ----------------------- | ---------------------------------------------- |
| Identify the machine    | `hostnamectl`                                  |
| Show user and groups    | `id`                                           |
| Show current directory  | `pwd`                                          |
| Inspect files           | `ll`, `stat PATH`, `readlink -f PATH`          |
| Monitor resources       | `btop`                                         |
| Check disk space        | `df -h`                                        |
| Check memory            | `free -h`                                      |
| Show addresses/routes   | `ip -br address`, `ip route`                   |
| Find listening ports    | `ss -lntup`                                    |
| Check a service         | `systemctl status SERVICE`                     |
| Read service logs       | `journalctl -u SERVICE -n 100 --no-pager`      |
| Check containers        | `docker compose ps`                            |
| Check a repository      | `gs`                                           |
| Inspect installed tools | `mise current`, `apt-cache policy PACKAGE`     |
| Preserve a remote shell | `tmux new -s work`, then `tmux attach -t work` |
| Return to the Mac       | `exit` or `Ctrl-D`                             |

## Mac-to-Ubuntu Map

| macOS                           | Ubuntu                                                      |
| ------------------------------- | ----------------------------------------------------------- |
| Finder                          | `ls`, `find`, `rg --files`, or a terminal file manager      |
| Activity Monitor                | `btop`, `top`, `ps`, `pgrep`                                |
| Console                         | `journalctl`                                                |
| `launchctl`                     | `systemctl`                                                 |
| Homebrew                        | APT for system packages; mise for development tools         |
| System Settings > Network       | `ip`, `networkctl`, `resolvectl`                            |
| Disk Utility                    | `lsblk`, `findmnt`, `df`, `du`                              |
| Keychain-backed SSH on the Mac  | Forwarded Mac SSH agent; private keys do not enter the VM   |
| `/Users/hameldesai`             | `/home/hamel`                                               |
| `/Applications`                 | Usually `/usr/bin`, `/usr/local/bin`, `/opt`, or containers |
| `~/Library/Application Support` | Usually `~/.config`, `~/.local/share`, or `~/.cache`        |

## Filesystem Mental Model

Linux has one directory tree. Mounted disks, virtual filesystems, and devices
all appear somewhere below `/`.

| Path             | Purpose                                        |
| ---------------- | ---------------------------------------------- |
| `/`              | Root of the entire filesystem                  |
| `/home/hamel`    | Your home directory; `~` expands here          |
| `/etc`           | System-wide configuration                      |
| `/var/log`       | Traditional service logs                       |
| `/var/lib`       | Persistent service and package state           |
| `/run`           | Runtime state recreated at boot                |
| `/tmp`           | Temporary files; do not treat as permanent     |
| `/usr/bin`       | Distribution-managed commands                  |
| `/usr/local`     | Administrator-managed local software           |
| `/opt`           | Optional third-party software                  |
| `/mnt`, `/media` | Mounted disks and removable media              |
| `/proc`          | Live kernel view of processes and system state |
| `/sys`           | Live kernel view of devices and drivers        |
| `~/.config`      | User configuration                             |
| `~/.local/share` | User application data                          |
| `~/.cache`       | Regenerable user caches                        |

Important differences from a typical Mac:

- Paths and filenames are case-sensitive.
- `/` is the path separator.
- Files beginning with `.` are hidden by convention.
- Executable files need an execute permission bit; extensions do not decide
  whether a file can run.
- Symlinks are common and intentional in this dotfiles setup.

### Navigate and inspect

```bash
pwd
ls
ll                         # Detailed tree alias
cd ~/Developer
cd -                       # Return to the previous directory
file path/to/item
stat path/to/item
readlink -f path/to/link
findmnt                    # Show mounted filesystems
```

Prefer `rg` for source trees:

```bash
rg "search text"
rg -n "search text" path/
rg --files
rg --files | rg "name"
```

### Copy, move, and synchronize

```bash
mkdir -p path/to/directory
cp -a source destination   # Preserve metadata
mv old-name new-name
rsync -avn source/ destination/   # Preview
rsync -av source/ destination/    # Apply
```

The trailing slash matters to `rsync`:

- `source/` means copy the contents.
- `source` means copy the directory itself.

## Users, Groups, and Permissions

Every file has:

- an owning user;
- an owning group;
- permissions for user, group, and everyone else.

```bash
ls -l file
stat file
id
groups
```

Example:

```text
-rwxr-x--- 1 hamel docker 1200 Jul 24 script.sh
```

- `-` means a regular file.
- `rwx` means the owner can read, write, and execute.
- `r-x` means the group can read and execute.
- `---` means everyone else has no access.

Prefer symbolic permission changes because they state intent:

```bash
chmod u+x script.sh        # Add execute for the owner
chmod go-rwx private-file  # Remove all group/other access
chmod 600 private-key      # Owner read/write only
chmod 644 public-file      # Owner write; everyone can read
```

Change ownership only when ownership is actually wrong:

```bash
sudo chown hamel:hamel path
```

Do not use `chmod -R 777`. It hides the ownership problem and creates a larger
security problem.

### Understand `sudo`

`sudo` runs one command as root. It is not a general-purpose fix for
permissions.

Before using it, ask:

1. Is this system state rather than user state?
1. Which exact path or service will change?
1. Is there a non-root command that gives the evidence first?

Good pattern:

```bash
systemctl status docker
sudo systemctl restart docker
systemctl status docker
```

## Processes, Jobs, and Signals

A process is a running program with a process ID.

```bash
btop
ps aux
ps -ef
pgrep -af docker
ps -p PID -o pid,ppid,user,%cpu,%mem,etime,command
```

Shell jobs belong to the current shell:

```bash
command &
jobs
fg %1
bg %1
```

For work that must survive disconnects, use tmux:

```bash
tm                     # Start tmux using the personal alias
tmux new -s work
tmux attach -t work
tmux ls
```

Signals are requests sent to processes:

```bash
kill PID               # SIGTERM: ask for a clean shutdown
pkill -TERM name
kill -KILL PID         # Last resort; no cleanup
```

Use `Ctrl-C` for an interactive interrupt. Try `SIGTERM` before `SIGKILL`.

## systemd: Services and Boot

systemd is Ubuntu's service manager. A service unit describes how a daemon
starts, stops, restarts, and reports health.

```bash
systemctl status docker
systemctl is-active docker
systemctl is-enabled docker
systemctl list-units --type=service --state=running
systemctl list-unit-files --type=service
```

State changes require root:

```bash
sudo systemctl start SERVICE
sudo systemctl stop SERVICE
sudo systemctl restart SERVICE
sudo systemctl enable --now SERVICE
sudo systemctl disable --now SERVICE
```

The words are distinct:

- **start/stop** changes the current boot.
- **enable/disable** changes automatic startup at future boots.
- **restart** stops and starts the service.
- **reload** asks a supporting service to reread configuration without a full
  restart.
- **daemon-reload** makes systemd reread unit files; it does not restart the
  service.

User services do not use `sudo`:

```bash
systemctl --user status
systemctl --user list-units --type=service
```

## Logs with journalctl

Start with a service's recent logs:

```bash
journalctl -u docker -n 100 --no-pager
journalctl -u SERVICE --since "30 minutes ago"
journalctl -u SERVICE -f
```

Useful system views:

```bash
journalctl -b             # Current boot
journalctl -b -1          # Previous boot
journalctl -p warning -b  # Warnings and worse this boot
sudo journalctl -k -b     # Kernel messages
```

Think in this order:

1. `systemctl status SERVICE`
1. `journalctl -u SERVICE -n 100`
1. inspect configuration and dependencies
1. make one change
1. repeat the status and log checks

## Software Ownership

Do not mix package managers casually. On this VM:

| Owner          | What it manages                                                  |
| -------------- | ---------------------------------------------------------------- |
| APT            | Docker, Ghostty, Zsh, system libraries, and OS-integrated tools  |
| mise           | Node, Go, Python, Bun, Neovim, language servers, and editor CLIs |
| pnpm/npm/bun   | Dependencies declared by a JavaScript project                    |
| Go modules     | Dependencies declared by a Go project                            |
| Docker/Compose | Container images and containerized services                      |

### APT

Read-only discovery:

```bash
apt search PACKAGE
apt show PACKAGE
apt-cache policy PACKAGE
apt list --installed
apt list --upgradable
dpkg -L PACKAGE          # Files installed by a package
dpkg -S /path/to/file    # Package that owns a file
```

State changes:

```bash
sudo apt update
sudo apt install PACKAGE
sudo apt remove PACKAGE
sudo apt autoremove --dry-run
sudo apt autoremove
```

For this workstation, prefer its tested updater:

```bash
cd ~/Developer/dotfiles-hd
bash setup/ubuntu/update-system.sh
```

`apt update` refreshes package metadata; it does not upgrade packages.

### mise

The tracked manifest is `setup/ubuntu/mise.toml`, linked to
`~/.config/mise/config.toml`.

```bash
mise current
mise ls
mise which nvim
mise doctor
mise install
mise reshim
mise exec -- COMMAND
```

Do not install a second Homebrew/Linuxbrew toolchain on this VM. Add a pinned
tool to the mise manifest or use APT when the tool is system-integrated.

## Storage and Memory

```bash
df -h                      # Free space by filesystem
du -sh path                # Total size of one path
du -h -d 1 path | sort -h  # Largest immediate children
lsblk -f                   # Block devices and filesystems
findmnt                    # Mount tree
free -h                    # RAM and swap
```

Docker has its own storage view:

```bash
docker system df
docker volume ls
docker image ls
```

Do not run `docker system prune`, delete volumes, or recursively remove a large
directory until you have identified exactly what owns the data.

## Networking

Start at the bottom and move upward:

```bash
ip -br address             # Interfaces and addresses
ip route                   # Routing table and default gateway
resolvectl status          # DNS configuration
ping -c 3 HOST             # Basic reachability
curl -fsSI URL             # HTTP response headers
ss -lntup                  # Listening TCP/UDP ports and owners
lsof -nP -iTCP:PORT -sTCP:LISTEN
```

Address meanings:

- `127.0.0.1` — reachable only inside Ubuntu.
- `0.0.0.0` — listens on every IPv4 interface.
- the VM's LAN/NAT address — reachable according to VMware and firewall rules.
- a Tailscale address — reachable through Tailscale when routing permits.

Common failure meanings:

| Error                | Usually means                                        |
| -------------------- | ---------------------------------------------------- |
| Connection refused   | Host is reachable; nothing accepts that port         |
| Connection timed out | Routing, firewall, VPN, or an unresponsive host      |
| No route to host     | No valid network path                                |
| Name not resolved    | DNS or hostname configuration                        |
| Permission denied    | Authentication worked poorly or authorization failed |

Local Docker containers, databases, and services can run without internet.
Internet is needed only for remote APIs, Git operations, package downloads,
image pulls, and other external dependencies.

## SSH and Git Identities

The Mac keeps the private keys. An SSH session opened through `ubuntu-vm`
forwards a live agent socket into Ubuntu.

```bash
ssh-add -l
ssh -T github.com-arbiter
ssh -T forgejo-truenas-lan
ssh -T forgejo-truenas-ts
```

Remote formats:

```text
git@github.com:hd719/<repository>.git
git@github.com-arbiter:arbiter-hd/<repository>.git
git@forgejo-truenas-lan:hd719/<repository>.git
git@forgejo-truenas-ts:hd719/<repository>.git
```

Inspect a repository before changing its remote:

```bash
git status --short --branch
git remote -v
git config --show-origin --get user.name
git config --show-origin --get user.email
```

Set Arbiter identity per repository when needed:

```bash
git config user.name "arbiter-hd"
git config user.email "YOUR-ARBITER-EMAIL"
```

Do not set an unverified email, copy private keys into Ubuntu, or replace the
machine-owned global `~/.gitconfig`.

## Docker and Databases

Docker concepts:

- **image** — immutable package used to create containers;
- **container** — running or stopped instance of an image;
- **volume** — persistent Docker-managed data;
- **network** — container connectivity;
- **Compose project** — related services described in a Compose file.

Everyday commands:

```bash
docker info
docker ps
docker ps -a
docker compose ps
docker compose up -d
docker compose logs -f --tail=100
docker compose exec SERVICE sh
docker inspect CONTAINER
docker stats
docker compose down
```

`docker compose down` removes containers and the Compose network. It normally
preserves named volumes. `docker compose down -v` deletes named volumes and can
destroy database data.

For a database, prove three separate things:

1. The process or container is running.
1. The expected address and port are listening.
1. A real client query succeeds.

Example investigation:

```bash
docker compose ps
docker compose logs --tail=100 DATABASE_SERVICE
ss -lntp
docker compose exec DATABASE_SERVICE sh
```

## Your Development Shell

This workstation uses Zsh. Configuration is linked from
`setup/ubuntu/.zshrc`, with portable aliases under `config/zsh/shared/`.

```bash
reload                     # Reload Zsh configuration
alias                      # List aliases
alias g
type hdiff
whence -v nvim
echo "$PATH" | tr ':' '\n'
```

Useful personal commands:

```bash
dots                       # Enter the dotfiles repository
gs                         # Git status with branch summary
hdiff                      # Hunk diff
hwatch                     # Watch changes with Hunk
ff                         # fastfetch
btop                       # Process and resource monitor
v FILE                     # Neovim
tm                         # tmux
```

When a command is missing:

```bash
type COMMAND
whence -a COMMAND
mise which COMMAND
mise current
echo "$PATH" | tr ':' '\n'
```

## Configuration and Runtime State

Learn the difference:

- **configuration** says how a tool should behave;
- **runtime state** is what the tool generates while running;
- **credentials** grant access and must remain machine-owned.

This repository links selected configuration into `~/.config`. It deliberately
does not link credentials, Git identity, SSH private keys, Docker data, caches,
databases, or mutable application state.

Inspect a link safely:

```bash
ls -ld ~/.config/nvim
readlink ~/.config/nvim
readlink -f ~/.config/nvim
test -L ~/.config/nvim && test -e ~/.config/nvim
```

## Troubleshooting Ladder

Use the same order every time:

1. **Context**

   ```bash
   pwd
   whoami
   hostname
   git status --short --branch 2>/dev/null
   ```

1. **Exact command and error**

   Read the full message. Do not fix the first noun you recognize.

1. **Ownership**

   ```bash
   type COMMAND
   stat PATH
   readlink -f PATH
   dpkg -S /path/to/system/file
   mise which COMMAND
   ```

1. **Current state**

   ```bash
   systemctl status SERVICE
   docker compose ps
   ps aux
   ```

1. **Logs**

   ```bash
   journalctl -u SERVICE -n 100 --no-pager
   docker compose logs --tail=100 SERVICE
   ```

1. **Resources and network**

   ```bash
   df -h
   free -h
   ip route
   ss -lntup
   ```

1. **Smallest change**

   Change one cause, then rerun the exact failing command.

### Fast diagnosis table

| Symptom                 | First checks                                          |
| ----------------------- | ----------------------------------------------------- |
| Command not found       | `type`, `whence`, `mise current`, `$PATH`             |
| Permission denied       | `id`, `ls -ld`, `stat`, parent-directory permissions  |
| Service will not start  | `systemctl status`, `journalctl -u`                   |
| Container exits         | `docker compose ps`, `docker compose logs`            |
| Port unavailable        | `ss -lntup`, `lsof -i`, service/container status      |
| Disk full               | `df -h`, `du`, `docker system df`                     |
| Broken symlink          | `ls -ld`, `readlink`, `readlink -f`, `test -e`        |
| Git uses wrong identity | `git config --show-origin`, `git remote -v`, `ssh -T` |

## Safety Rules Worth Memorizing

- Inspect before using `sudo`.
- Prefer an explicit path over a wildcard.
- Preview `rsync` with `-n`.
- Check `git status` before editing, pulling, or committing.
- Never use `git reset --hard` to clean up a repository you have not inspected.
- Never run `rm -rf` against `~`, `/`, an unresolved variable, or a broad
  directory.
- Never use `chmod -R 777`.
- Never pipe an unreviewed download into `sudo sh`.
- Never delete a Docker volume unless the contained data is disposable or
  backed up.
- Stop before changing firewall, disk partitions, mounts, boot configuration,
  SSH access, or database storage.

## Becoming Expert: Practice Path

### Stage 1 — Daily fluency

- Navigate without guessing: `pwd`, `cd`, `ls`, `find`, `rg`.
- Explain every column of `ls -l`.
- Use `stat`, `file`, and `readlink` before changing a path.
- Read `ps`, use `btop`, and understand PID/PPID.
- Know where APT, mise, Docker, and project dependencies belong.

### Stage 2 — Operating the machine

- Trace a service from `systemctl status` to `journalctl`.
- Explain start versus enable.
- Find which process owns a listening port.
- Explain routes, DNS, loopback, and bind addresses.
- Read `df`, `du`, `lsblk`, `findmnt`, and `free`.

### Stage 3 — Running development systems

- Diagnose a failing Compose stack without recreating it blindly.
- Locate persistent database data and prove backups.
- Use tmux for durable sessions.
- Trace Git identity separately from SSH authentication.
- Explain why local services work without internet.

### Stage 4 — Linux internals

- Learn system calls, file descriptors, signals, and process trees.
- Learn namespaces and cgroups behind containers.
- Learn filesystems, inodes, mounts, and virtual filesystems.
- Learn firewall chains, routing, and DNS resolution.
- Learn AppArmor, capabilities, and least privilege.

Practice by explaining the system before changing it. Expertise is the ability
to predict what a command will affect, verify the prediction, and recover when
it is wrong.

## Ten-Minute Practice Drills

1. Find Ubuntu's address, default route, and DNS server.
1. Find the PID that owns Docker's daemon and read its last 20 log lines.
1. Choose one installed APT package and identify every file it owns.
1. Choose one mise tool and find its executable and pinned version.
1. Find the largest directory immediately below `~/Developer`.
1. Open a tmux session, detach, disconnect SSH, reconnect, and reattach.
1. Find every listening TCP port and explain which process owns each.
1. Inspect a dotfiles symlink from live path to tracked source.
1. Prove Arbiter and Forgejo authentication without cloning anything.
1. Explain why `docker compose down -v` is more dangerous than
   `docker compose down`.

## When You Need Help

Bring the smallest complete evidence:

```bash
hostname
pwd
git status --short --branch 2>/dev/null
command-that-failed
systemctl status RELEVANT_SERVICE --no-pager
journalctl -u RELEVANT_SERVICE -n 50 --no-pager
```

Do not paste secrets, tokens, private keys, environment values, or complete
credential files.
