#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
STAMP="${DOTFILES_STAMP:-$(date +%Y%m%d-%H%M%S)}"
PROFILE=""
MODE="dry-run"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage: bootstrap.sh --profile mac-vm|mac-mini [--dry-run|--check|--apply]

Modes:
  --dry-run  Show planned commands and filesystem changes without invoking
             package managers or writing files. This is the default.
  --check    Audit package state and show planned filesystem changes. It does
             not install packages or change managed config, but tools may
             refresh their own caches.
  --apply             Install missing dependencies and apply backed-up links.

The script never handles credentials, removes packages, cleans Homebrew, or
starts/restarts services. Xcode Command Line Tools, Homebrew, and a clean clone
at ~/Developer/dotfiles-hd are prerequisites.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      PROFILE="$2"
      shift 2
      ;;
    --dry-run)
      MODE="dry-run"
      shift
      ;;
    --check)
      MODE="check"
      shift
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "$PROFILE" ]] || { usage >&2; exit 2; }
load_profile "$PROFILE" "$DOTFILES_DIR" "$HOME"

[[ "$(uname -s)" == "Darwin" ]] || die "personal-Mac bootstrap requires macOS"
[[ "$(uname -m)" == "arm64" ]] || die "personal-Mac bootstrap currently supports Apple Silicon only"
xcode-select -p >/dev/null 2>&1 || die "install Xcode Command Line Tools first: xcode-select --install"
command -v brew >/dev/null 2>&1 || die "install Homebrew first: https://brew.sh"
git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "not a Git checkout: $DOTFILES_DIR"

if [[ "$MODE" == "apply" ]]; then
  [[ "$DOTFILES_DIR" == "$HOME/Developer/dotfiles-hd" \
    || "${DOTFILES_ALLOW_NONCANONICAL:-0}" == "1" ]] \
    || die "--apply requires the canonical clone at $HOME/Developer/dotfiles-hd"
  if [[ "${DOTFILES_ALLOW_DIRTY:-0}" != "1" ]]; then
    [[ -z "$(git -C "$DOTFILES_DIR" status --porcelain)" ]] \
      || die "dotfiles checkout must be clean before --apply"
  fi
fi

require_source "$COMMON_BREWFILE"
require_source "$PROFILE_BREWFILE"
require_source "$MISE_CONFIG"
require_source "$MISE_FRAGMENT"
load_mise_specs "$MISE_CONFIG"
validate_approved_mise_pins
validate_neovim_parser_manifest "$DOTFILES_DIR/config/nvim/lua/plugins/editor.lua"
validate_neovim_lockfile "$DOTFILES_DIR/config/nvim/lazy-lock.json"

for spec in "${LINK_SPECS[@]}"; do
  require_source "${spec%%|*}"
  reject_link_source_alias "${spec%%|*}" "${spec#*|}"
done

# Refuse known-bad profile state before installers or links can make a partial
# migration. The dry-run helper performs validation without writing.
write_zprofile_block "$HOME/.zprofile" "$MISE_FRAGMENT" "$STAMP" 1 >/dev/null

if [[ "$MODE" == "dry-run" ]]; then
  say "profile: $PROFILE"
  say "dotfiles: $DOTFILES_DIR"
  say "mode: dry-run (no package-manager calls or writes)"
  say "would install Brewfile: $COMMON_BREWFILE"
  say "would install Brewfile: $PROFILE_BREWFILE"
  say "would install pinned mise runtimes from: $MISE_CONFIG"
  say "would install pinned Ruff and mdformat tools with uv"
  say "would install GraphQL LSP 3.5.0 under: $HOME/.local/graphql-lsp"
  say "would restore locked Neovim plugins and required Tree-sitter parsers without changing lazy-lock.json"
  say "would run the verification doctor"

  for spec in "${LINK_SPECS[@]}"; do
    backup_and_link "${spec%%|*}" "${spec#*|}" "$STAMP" 1
  done
  write_zprofile_block "$HOME/.zprofile" "$MISE_FRAGMENT" "$STAMP" 1
  exit 0
fi

if [[ "$MODE" == "check" ]]; then
  status=0
  say "profile: $PROFILE"
  say "dotfiles: $DOTFILES_DIR"
  say "mode: check (no installs or managed-config writes)"

  for brewfile in "$COMMON_BREWFILE" "$PROFILE_BREWFILE"; do
    if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file "$brewfile"; then
      say "Brewfile satisfied: $brewfile"
    else
      say "Brewfile has missing dependencies: $brewfile"
      status=1
    fi
  done

  if command -v mise >/dev/null 2>&1; then
    MISE_NO_CONFIG=1 mise install --dry-run-code "${MISE_SPECS[@]}" || status=1
  else
    say "mise is not installed yet"
    status=1
  fi

  for spec in "${LINK_SPECS[@]}"; do
    backup_and_link "${spec%%|*}" "${spec#*|}" "$STAMP" 1
  done
  write_zprofile_block "$HOME/.zprofile" "$MISE_FRAGMENT" "$STAMP" 1
  exit "$status"
fi

say "Installing shared Homebrew dependencies without broad upgrades..."
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --no-upgrade --file "$COMMON_BREWFILE"
say "Installing $PROFILE Homebrew overlay without broad upgrades..."
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --no-upgrade --file "$PROFILE_BREWFILE"
hash -r

say "Installing pinned mise runtimes..."
MISE_NO_CONFIG=1 mise install "${MISE_SPECS[@]}"

say "Installing pinned formatter and language-server tools..."
uv tool install 'mdformat==1.0.0' \
  --with 'mdformat-gfm==1.0.0' \
  --with 'mdformat-frontmatter==2.1.2' \
  --with 'mdformat-footnote==0.1.3' \
  --with 'mdformat-gfm-alerts==2.0.0' \
  --with 'mdformat-wikilink==0.3.0'
uv tool install 'ruff==0.15.21'

graphql_package="$HOME/.local/graphql-lsp/lib/node_modules/graphql-language-service-cli/package.json"
if [[ -x "$HOME/.local/graphql-lsp/bin/graphql-lsp" ]] \
  && MISE_NO_CONFIG=1 mise exec "node@$NODE_VERSION" -- node -e \
    'const p=require(process.argv[1]);process.exit(p.version===process.argv[2]?0:1)' \
    "$graphql_package" 3.5.0; then
  say "GraphQL LSP 3.5.0 is already installed."
else
  MISE_NO_CONFIG=1 mise exec "node@$NODE_VERSION" -- \
    npm install -g --prefix "$HOME/.local/graphql-lsp" \
    'graphql-language-service-cli@3.5.0'
fi

for spec in "${LINK_SPECS[@]}"; do
  backup_and_link "${spec%%|*}" "${spec#*|}" "$STAMP" 0
done
write_zprofile_block "$HOME/.zprofile" "$MISE_FRAGMENT" "$STAMP" 0

say "Restoring locked Neovim plugins and required Tree-sitter parsers..."
restore_neovim_plugins "$DOTFILES_DIR/config/nvim/lazy-lock.json"

"$SCRIPT_DIR/doctor.sh" --profile "$PROFILE"
say "Personal Mac bootstrap complete. Start a fresh login shell."
