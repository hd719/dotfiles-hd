# Mac Studio

The Mac Studio is the planned primary machine: full macOS development, local
AI, VM hosting, and control of the Ubuntu VM and Mac mini.

This profile is staged before the hardware arrives. It does not change the
current thin-Mac, Ubuntu, or Mac-mini routes. Do not apply it until the Studio
is present and Hamel approves the reviewed preview and check.

## Topology

```text
Mac Studio (primary controller and compute)
├── Ubuntu VM (lives inside the Studio; primary development workstation)
├── Ollama (native macOS app; models and cache stay on the Studio)
└── SSH / Screen Sharing -> Mac mini (Hermes runtime)

MacBook Air (mobile controller)
├── SSH / Screen Sharing -> Mac Studio
├── SSH -> Ubuntu VM
└── SSH -> Mac mini
```

The Studio and Air use Hamel's personal Apple Account. The Mac mini keeps its
existing dedicated Apple Account. Apple Account setup, Remote Login, Screen
Sharing, Tailscale enrollment, SSH keys, and Ollama models are machine-owned
and never copied by dotfiles.

The future Air reuses the existing `mac-thin` profile. No new Air-specific
profile is needed.

## On Arrival

Manually install and finish first-run setup for Xcode Command Line Tools,
Homebrew, and VMware Fusion. Then clone this repository to
`~/Developer/dotfiles-hd` and run:

```bash
hosts/shared/macos/bootstrap.sh --profile mac-studio --dry-run
hosts/shared/macos/bootstrap.sh --profile mac-studio --check
```

Review both results before approving:

```bash
DOTFILES_MAC_STUDIO_ARRIVED=1 \
  hosts/shared/macos/bootstrap.sh --profile mac-studio --apply
hosts/shared/macos/doctor.sh --profile mac-studio
```

The arrival flag is a hard safety gate. Never set it on another Mac.

The SSH config is machine-owned. After the Studio exists, manually add this
line before any older `Host ubuntu-vm*` blocks in `~/.ssh/config`:

```sshconfig
Include ~/Developer/dotfiles-hd/hosts/mac-studio/ssh/ubuntu-vagrant.conf
```

The apply installs the Ollama app, Vagrant, the VMware utility, Rosetta 2 when
needed, and `vagrant-vmware-desktop` 3.0.5. It does not launch Ollama, download
models, start services, create the VM, or alter remote-access settings.

## Ubuntu VM

After the Studio profile is green, move by rebuilding the Ubuntu VM from the
tracked Vagrant definition. Do not manually move or delete the current Fusion
VM. The cutover is a separate approval gate.

Cut over in this order:

1. Back up and verify uncommitted repositories, databases, and other VM-local
   data. Record the old VM's SSH host-key and Git-key fingerprints.

1. Halt the old VM and keep it recoverable. Never run both `ubuntu-dev`
   machines on the LAN or tailnet together.

1. Rebuild on the Studio without a Tailscale auth key. Verify localhost SSH,
   provisioning, repositories, tools, and restored data first.

1. Retire the old Tailscale node, enroll the new VM as `ubuntu-dev`, then
   replace known-host entries only after verifying its new fingerprint.

1. Run the full Ubuntu doctor and the Studio cutover check:

   ```bash
   DOTFILES_MAC_STUDIO_CUTOVER=1 \
     hosts/shared/macos/doctor.sh --profile mac-studio
   ```

1. Destroy the old VM and remove its registered Git keys only after Hamel
   approves the verified replacement.

The Studio shell exposes `uvm-up`, `uvm-stop`, `uvm-suspend`, `uvm-resume`,
`uvm-status`, `uvm-ip`, and interactive `uvm-destroy`. The VM remains the
primary home for project repositories, Docker, databases, and PR work.

## Ownership

- Dotfiles own the reviewed profile, shell, packages, and VM commands.
- Vagrant owns the Ubuntu VM definition and lifecycle.
- VMware Fusion owns the local VM runtime.
- Ollama models and `~/.ollama` stay machine-owned.
- The Mac mini remains the Hermes production runtime.
