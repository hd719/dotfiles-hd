# Production Migration Plan

Status: draft for future use. Every live-host action requires a new, explicit
approval from Hamel.

## Preconditions

- The Ubuntu and macOS canaries have passed their acceptance gates.
- The exact [ownership inventory](OWNERSHIP-INVENTORY.md) and rollback steps are
  reviewed.
- The current host has a recoverable backup of every path changing ownership.
- Chezmoi preview shows only the approved paths.
- The current bootstrap remains available for rollback and is not a concurrent
  writer for transferred paths.
- VM lifecycle and recurring maintenance behavior remain unchanged.

## Promotion Order

| Stage | Host               | Initial scope                           | Extra gate                                     |
| ----- | ------------------ | --------------------------------------- | ---------------------------------------------- |
| 1     | Ubuntu workstation | User config and package manifests       | Vagrant and Ansible lifecycle unchanged        |
| 2     | Thin Mac           | Approved control-plane user environment | Ubuntu remains healthy and reachable           |
| 3     | Mac mini           | User config only                        | No service, launchd, or runtime changes        |
| 4     | Work Mac           | Approved work-safe subset only          | All personal hosts are clean and Hamel opts in |

Each host is a separate cutover. A suggested observation period is seven days,
but Hamel alone decides when a host is stable enough to promote the next.

## Per-Host Cutover

1. Confirm the host, profile, clean source revision, and current doctor result.
1. Back up every path whose ownership will transfer.
1. Run and review `chezmoi diff`.
1. Apply only the approved profile and path set.
1. Apply again and require no changes.
1. Run the profile's existing tests and doctor.
1. Use the machine normally until Hamel accepts the soak result.
1. Record the evidence and either promote, hold, or roll back.

Never let chezmoi and the old bootstrap write the same path during this flow.

## Rollback

Rollback is host-local and does not advance another host:

1. Stop further chezmoi applies on the affected host.
1. Restore the timestamped pre-cutover backups.
1. Restore the last known-good ownership path from the current bootstrap.
1. Run the existing doctor and verify normal host behavior.
1. Record the failure before changing the design or retrying.

After all approved hosts have migrated and passed their soak periods, move the
replaced Bash implementation into `legacy/`. Preserve it for reference and
recovery; do not delete it.

## Mac mini Safety

- Require a fresh interactive approval immediately before any apply.
- Keep the runtime checkout, services, launchd jobs, databases, agents, and
  connection state outside chezmoi.
- Abort if the preview contains any runtime-owned path.
- Do not restart or reload a service as part of configuration migration.
- Roll back the Mac mini independently if any runtime behavior changes.

## Work-Mac Safety

The work Mac is not an automatic fourth rollout. Revisit it only after Ubuntu,
the thin Mac, and the Mac mini work without errors. Use a separate work-safe
profile, follow company policy, and never import personal credentials, services,
or machine-owned runtime state.
