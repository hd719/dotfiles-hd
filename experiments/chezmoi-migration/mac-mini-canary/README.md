# Disposable Mac Mini Chezmoi Canary

This throwaway delta prototype reuses the accepted thin-Mac design and adds
only the approved Mac-mini user configuration and safe user tools. The existing
repository `config/` tree remains canonical.

It manages configuration through symlinks plus one narrow Git include action.
It does not manage macOS preferences, secrets, identities, services, launchd
jobs, Tailscale, VM lifecycle, or mutable state.

## Flow

1. Install Apple's Command Line Tools and Homebrew in the disposable VM.
1. Place this checkout at `~/Developer/dotfiles-hd`.
1. Run `prepare-home.sh` to create and back up harmless pre-chezmoi state.
1. Run `bootstrap.sh --preview` and review the diff.
1. Run `bootstrap.sh --apply` twice; the second apply must be a no-op.
1. Run `brew bundle install --no-upgrade --file ~/.config/homebrew/Brewfile`.
1. Run `restore-neovim.sh`; it must restore the tracked lockfile byte-for-byte.
1. Run `doctor.sh`; duplicate interactive shell/editor QA is not required.
1. Run `rollback.sh`, verify the original state, then reapply and verify again.

The package test uses the narrow `Brewfile` in this directory. It deliberately
excludes credentials, network enrollment, Vagrant, VMware, production apps,
background services, and runtime-sensitive Node, PostgreSQL, pgvector, pnpm,
and Tailscale packages.

The third-party `remindctl` tap remains machine-approved rather than being
trusted by this canary.
