# Disposable macOS Chezmoi Canary

This throwaway prototype answers whether chezmoi can replace thin-Mac link
orchestration while keeping the existing repository `config/` tree canonical.

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
1. Run `doctor.sh` and complete interactive shell/editor QA.
1. Run `rollback.sh`, verify the original state, then reapply and verify again.

The package test uses the narrow `Brewfile` in this directory. It deliberately
excludes credentials, network enrollment, security tools, Vagrant, VMware,
background services, and personal applications.
