# Disposable Ubuntu Chezmoi Canary

This is a throwaway prototype for the Ubuntu profile. It has its own Vagrant
state, hostname, SSH port, and VMware display name. It does not reuse the
production Ubuntu VM, Tailscale identity, Git keys, or personal credentials.

## Isolation

| Property      | Canary value                                  |
| ------------- | --------------------------------------------- |
| Hostname      | `chezmoi-ubuntu-canary`                       |
| SSH forward   | `127.0.0.1:2223`                              |
| Vagrant state | this directory's `.vagrant/`                  |
| VMware name   | `chezmoi-ubuntu-canary`                       |
| VMware MAC    | `00:0C:29:10:D0:E7`                           |
| Display       | headless; no Fusion window is expected        |
| Resources     | 4 vCPUs, 8 GiB RAM, sparse 80 GiB disk        |
| User          | `hamel`, locked password, no personal SSH key |

The canary uses a separate VMware MAC so it can coexist with the production VM
without sharing DHCP identity.

## Flow

1. Start VMware Fusion.
1. Run `vagrant up --provider vmware_desktop` here.
1. Seed and back up the clean home with `prepare-home.sh`.
1. Run `bootstrap.sh --preview` as `hamel` and review the diff.
1. Run `bootstrap.sh --apply` twice and require the second run to be a no-op.
1. Run `doctor.sh`.
1. Run `rollback.sh`, verify the original marker, then apply and verify again.

Only this prototype's `source/` is passed to chezmoi. Vagrant and guest-local
Ansible remain responsible for the disposable VM and its system packages.
