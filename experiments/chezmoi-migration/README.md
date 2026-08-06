# Chezmoi Migration Experiment

Status: planning only. This folder does not authorize changes to any live host.

## Destination

Prove a chezmoi-based user environment on disposable Ubuntu and macOS VMs,
then produce a production-ready migration and rollback plan for Ubuntu, the
thin Mac, the Mac mini, and the work Mac.

The experiment aims to replace most link and bootstrap orchestration with
chezmoi. Vagrant and Ansible keep their existing VM lifecycle and system setup
roles. Existing maintenance commands keep their public behavior.

## Guardrails

- Hamel is the manual approval and promotion gate.
- No production host changes belong to this experiment.
- Chezmoi and the current bootstrap never manage the same live path together.
- Chezmoi may own user configuration and package manifests.
- Chezmoi does not own VM lifecycle, recurring maintenance, macOS preferences,
  services, launchd jobs, credentials, SSH identities, tokens, `.env` files,
  Tailscale enrollment, or mutable application state.
- The production Mac mini remains untouched until both disposable canaries pass.
- The work Mac is last and optional. It remains untouched until every personal
  host works cleanly and Hamel explicitly approves it.

## Planned Shape

The prototype ticket may add these paths later:

```text
experiments/chezmoi-migration/
├── source/       # experimental chezmoi source state
├── evidence/     # sanitized diffs, checks, and rollback results
└── bootstrap.sh  # roughly 15-25 lines
```

The bootstrap entrypoint may only detect the OS, install chezmoi when missing,
and run the reviewed init/apply flow. Package lists, link logic, maintenance,
and VM lifecycle do not belong in that script.

## Route

```text
ownership inventory
  -> disposable Ubuntu canary
  -> Orka compatibility gate
  -> one disposable macOS VM: thin profile
  -> erase/rebuild the same VM: Mac mini profile
  -> production runbook
  -> later, separately approved production rollout
```

See [OWNERSHIP-INVENTORY.md](OWNERSHIP-INVENTORY.md),
[CANARY-PLAN.md](CANARY-PLAN.md), [PRODUCTION-PLAN.md](PRODUCTION-PLAN.md), and
[CONTEXT.md](CONTEXT.md).

Canonical tracker: [Migrate dotfiles delivery to chezmoi](https://github.com/hd719/dotfiles-hd/issues/82).

## Chezmoi References

- [Machine-specific templates](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [Managed target types](https://www.chezmoi.io/reference/target-types/)
- [Scripts and their tradeoffs](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)
- [Optional future 1Password integration](https://www.chezmoi.io/user-guide/password-managers/1password/)
