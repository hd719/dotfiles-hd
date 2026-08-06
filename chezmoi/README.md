# Production Chezmoi Delivery

This directory is the reviewed implementation candidate for transferring user
configuration delivery to chezmoi. It is dormant until the matching host is
explicitly approved after merge.

`config/` remains canonical. Chezmoi owns profile-aware symlinks into the
repository, a small set of first-install actions, and host-local rollback.
Vagrant, Ansible system setup, recurring maintenance, services, secrets,
identity, enrollment, macOS preferences, and mutable state stay unchanged.

## Profiles

| Profile | Scope |
| ---------- | ---------------------------------------------------------- |
| `ubuntu` | Ubuntu user configuration and mise-owned tools |
| `mac-thin` | Thin-Mac configuration and first-install Brewfile |
| `mac-mini` | Configuration only; no packages or runtime actions |
| `work-mac` | Optional company-approved terminal/editor subset |

Each `profiles/*.paths` file is the exact backup, apply, doctor, and rollback
allowlist. `source/.chezmoiignore.tmpl` selects only that profile's entries.
The Mac mini's reviewed `profiles/mac-mini.ancestors` file additionally records
whole-directory links that must be restored exactly by rollback.

## Preview

From the canonical checkout:

```bash
./chezmoi/bootstrap.sh ubuntu --preview
```

Substitute `mac-thin`, `mac-mini`, or `work-mac`. Preview installs only the
pinned chezmoi binary when missing. It prints every target, symlink source,
chezmoi action, script, and missing-package check before target writes.

## Apply

Apply is intentionally locked to clean, reviewed `master` and requires a fresh
host approval:

```bash
DOTFILES_CHEZMOI_APPROVED=1 \
  ./chezmoi/bootstrap.sh ubuntu --apply
```

The Mac mini also requires `DOTFILES_MAC_MINI_CONFIG_ONLY=1`. The work Mac also
requires `DOTFILES_WORK_MAC_OPT_IN=1`. Apply creates a mode-`0700` host-local
backup, applies once, requires a no-op second apply, verifies empty status, and
runs the profile doctor. A successful Ubuntu apply then activates a host-local
ownership marker. The existing link scripts become no-ops while recurring
package and Neovim maintenance continues unchanged.

Before target writes, apply also validates the exact generated backup with the
non-mutating rollback preview.

Never apply an unmerged branch. Promotion order remains Ubuntu, thin Mac, Mac
mini, then the optional work Mac. Each host needs its own approval.

## Roll Back

Apply prints the exact command. It has this form:

```bash
./chezmoi/rollback.sh PROFILE \
  "$HOME/.local/state/dotfiles-hd/chezmoi-backups/TIMESTAMP-PROFILE"
```

Validate the same backup without changing anything:

```bash
./chezmoi/rollback.sh PROFILE \
  "$HOME/.local/state/dotfiles-hd/chezmoi-backups/TIMESTAMP-PROFILE" \
  --preview
```

Rollback accepts only a backup under the guarded backup root and only targets
from the selected profile manifest. It moves current chezmoi state aside,
restores original types, links, modes, and file checksums, and retains both
copies for review. It also restores the prior ownership-marker state, so an
initial Ubuntu rollback automatically re-enables the legacy link writers. It
never uninstalls packages.

## Validate

Run the isolated four-profile render, apply, doctor, backup, and rollback test
with the pinned chezmoi binary:

```bash
CHEZMOI_BIN=/path/to/chezmoi-2.72.0 \
  bash chezmoi/tests/production-test.sh
```

The test uses temporary home directories and never targets a live profile.
