# Vagrant + Ansible Ubuntu Workstation Migration

## Goal

Rebuild the Ubuntu ARM64 development workstation with one command:

```text
vagrant up -> VMware Fusion -> Ansible -> mise + dotfiles -> doctor
```

The thin Mac remains a control plane. Development tools, repositories, Docker,
and daily work remain inside Ubuntu.

## Requirements

- Vagrant owns VM creation, start, SSH, stop, suspend, resume, and destroy.
- VMware Fusion runs a full-clone Ubuntu ARM64 VM.
- The Bento Ubuntu 26.04 box is pinned to an exact tested release.
- Ansible runs inside the guest and owns system configuration.
- mise owns development tools and versions.
- dotfiles owns user configuration and symlinks.
- `doctor.sh` is the final acceptance check.
- Tailscale provides the normal remote route; localhost SSH remains available
  offline through a fixed loopback-only forwarded port.
- GitHub `hd719`, Arbiter, and Forgejo each use a different VM-local key.
- The Codex forwarded-agent compatibility fix remains tested.
- The existing VMware VM is never imported, changed, destroyed, or reinstalled.

## Non-goals

- Terraform, Chef, Puppet, NixOS, cloud-init, or a custom Packer box.
- Copying project repositories, containers, databases, secrets, or Codex auth
  from the existing VM.
- Managing GNOME preferences that dotfiles does not already own.
- Replacing mise or the dotfiles linker with Ansible.
- Automatic registration of public SSH keys with external services.

## Implementation decisions

- Keep one small playbook with task files grouped by system, user, identities,
  tools, and verification.
- Bootstrap only `ansible-core` with a tiny guest shell script, then hand
  control to Ansible.
- Disable shared folders. Vagrant uploads the playbook for provisioning.
- Use explicit package lists and the existing update script for later upgrades.
- Generate unencrypted Ed25519 Git keys once and never overwrite them.
- Pass an optional one-time Tailscale auth key through a temporary guest file,
  hide it from logs, and delete it after use.
- Keep SSH password and root login disabled. The Mac supplies only its existing
  Ubuntu public key.
- Keep lifecycle commands thin wrappers around Vagrant so they can be tested
  with a fake executable.
- Make destroy interactive and scoped to this Vagrant project. Never pass
  Vagrant's force flag.

## User flow

1. Install VMware Fusion, Vagrant, the VMware utility, and the pinned provider.
1. Export an optional one-time Tailscale auth key.
1. Run the GUI or headless Vagrant-up alias.
1. Register the three printed public Git keys.
1. Change the dotfiles remote from HTTPS to SSH and sign in to Codex.
1. Run the full doctor.
1. Qualify two clean canary builds before switching the normal SSH aliases.

## Safety boundary

- The Vagrant project has its own name, state, disk, and clone directory.
- Canary testing runs only when the legacy VM is stopped because both guests
  cannot safely use 25 GB of RAM at once.
- The legacy VM is restarted after each canary session.
- Only the canary is destroyed during qualification.
- After cutover, retain the stopped legacy VM for 30 days.

## Verification

- Static and fake-Vagrant tests prove lifecycle arguments and destroy safety.
- Shell syntax, Markdown format, and repository regression suites pass.
- A first canary build passes the offline doctor.
- A second provision is idempotent and passes the offline doctor again.
- Three Git identities, Tailscale, localhost SSH, MagicDNS SSH, Codex login
  status, Docker, mise tools, and dotfile links pass the full doctor.
- The canary is destroyed interactively, rebuilt cleanly, and passes again.
- New SSH host keys are verified before only the affected `known_hosts` entries
  are rotated.

## Risks

- Bento is a third-party base box. Pin its exact ARM64 release and qualify it
  twice; revisit a Canonical Vagrant box only if one becomes dependable.
- The VMware provider may enlarge the virtual disk without enlarging the guest
  filesystem. The canary doctor must confirm usable root capacity.
- The Mac has 36 GB RAM, so the 25 GB legacy VM and canary must never run
  together.
- Git and Codex onboarding has manual external steps by design. The offline
  doctor can pass before them; the full doctor cannot.
- First provisioning requires package, box, font, and mise downloads. Later
  local SSH access remains available without the internet.

## Rollback

Stop the canary and start the unchanged legacy VMware VM. Restore the previous
SSH alias include if cutover had begun. No data migration is required because
repositories and secrets are restored from their normal sources.
