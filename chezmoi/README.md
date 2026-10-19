# Chezmoi Configuration Delivery

Chezmoi is the production owner for approved user configuration. `config/`
remains canonical; Chezmoi creates profile-aware links into it and the matching
host directory.

It does not own VM lifecycle, system provisioning, recurring maintenance,
services, secrets, identity, enrollment, macOS preferences, or mutable state.

## Profiles

| Profile      | Host                                | Package behavior                                                              |
| ------------ | ----------------------------------- | ----------------------------------------------------------------------------- |
| `mac-air`    | MacBook Air thin client             | Installs the thin Brewfile                                                    |
| `mac-pro`    | Standalone full-development MacBook | Installs shared and profile Brewfiles through the Mac bootstrap               |
| `mac-studio` | Staged native development Studio    | Installs shared and profile Brewfiles through the Mac bootstrap               |
| `mac-mini`   | Production Mac mini                 | Configuration-only inside Chezmoi; packages stay in the guarded Mac bootstrap |
| `mac-work`   | Resilience work Mac                 | Reserved for a later opt-in rollout                                           |

Each `profiles/*.paths` file is the exact backup, apply, doctor, and rollback
allowlist. A matching `*.ancestors` file records parent directories whose
original type must be restored exactly.

## Preview and Apply

```bash
./chezmoi/bootstrap.sh mac-air --preview
```

Substitute `mac-pro`, `mac-studio`, `mac-mini`, or `mac-work` as needed.

After review and host approval:

```bash
DOTFILES_CHEZMOI_APPROVED=1 \
  ./chezmoi/bootstrap.sh mac-air --apply
```

Studio also requires `DOTFILES_MAC_STUDIO_ARRIVED=1` after hardware arrival.
Mac mini also requires `DOTFILES_MAC_MINI_CONFIG_ONLY=1`. Work Mac requires
`DOTFILES_WORK_MAC_OPT_IN=1` and remains deferred.

Apply requires a clean canonical checkout exactly matching its reviewed remote
branch, `master`. Apply creates a mode-`0700`
timestamped backup, validates rollback, requires a no-op second apply, verifies
clean status, and runs the profile doctor.

The host bootstraps are the normal entry points. They retain provisioning,
packages, maintenance, and doctor logic while delegating managed
user configuration to Chezmoi.

## Rollback

Apply prints the exact rollback command:

```bash
./chezmoi/rollback.sh PROFILE \
  "$HOME/.local/state/dotfiles-hd/chezmoi-backups/TIMESTAMP-PROFILE"
```

Preview the same rollback without writes:

```bash
./chezmoi/rollback.sh PROFILE \
  "$HOME/.local/state/dotfiles-hd/chezmoi-backups/TIMESTAMP-PROFILE" \
  --preview
```

Rollback accepts only the selected profile's guarded backup. It restores
original path types, links, modes, and file checksums. Replaced Chezmoi state is
retained inside the backup for inspection. It never revives removed link
writers and never uninstalls packages.

## Validate

```bash
CHEZMOI_BIN="$HOME/.local/bin/chezmoi" \
  bash chezmoi/tests/production-test.sh
```

The test renders and exercises all five profiles in temporary homes. It covers
backup, apply, second-apply idempotence, doctor, rollback, and recovery/reapply.
