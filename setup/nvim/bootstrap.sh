#!/usr/bin/env bash
# Stop on command errors (-e), unset variables (-u), and failures hidden inside
# pipelines (pipefail).
set -euo pipefail

# This script is safe to rerun: it fills missing capabilities, converges pinned
# tools, protects the caller's Node setup, and restores locked plugins.

# Print the command reference literally; quoting `EOF` prevents Bash from
# expanding examples or variables inside this help text.
print_usage() {
  cat <<'EOF'
Usage: bootstrap.sh [core|full|desktop]

Profiles are cumulative; choose one:
  core     Editor, search, Tree-sitter, LazyGit, and locked plugins.
           Use on a minimal headless or SSH server.
  full     Core plus configured language servers and formatters. (default)
           Use on a developer machine or cloud development host.
  desktop  Full plus image/PDF preview tools and a system file opener.
           Use with Ghostty or another Kitty-graphics-compatible terminal.

Choose one per machine; using desktop on a laptop and core on a server is normal.
Running desktop already includes full and core. You can safely rerun later with
a higher profile; the bootstrap only fills missing capabilities.
EOF
}

# `${1:-full}` uses the first argument, or `full` when none is supplied.
# Resolve paths from this file instead of the current directory so the script
# works no matter where it is launched from.
PROFILE="${1:-full}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

# Exit status 2 means the command was invoked incorrectly.
if (($# > 1)); then
  print_usage >&2
  exit 2
fi

case "$PROFILE" in
  core | full | desktop) ;;
  -h | --help)
    print_usage
    exit 0
    ;;
  *)
    print_usage >&2
    exit 2
    ;;
esac

# Avoid an unrelated Homebrew metadata refresh during setup; explicit installs
# of missing formulas still work.
export HOMEBREW_NO_AUTO_UPDATE=1

# Homebrew installs can relink Node. Keep enough state to restore and verify the
# exact Node command and version that the caller started with.
HOST_NODE_PATH=""
HOST_NODE_VERSION=""
HOST_BREW_NODE_FORMULA=""
NODE_RESTORE_PENDING=0

# Capability checks accept commands supplied by any package manager on PATH.
have() {
  command -v "$1" >/dev/null 2>&1
}

# Record the active Node. If it is Homebrew's public link, inspect its Cellar
# target to remember which formula owns it, such as `node` or `node@22`.
capture_host_node() {
  local brew_prefix node_link relative

  if ! have node; then
    return
  fi

  HOST_NODE_PATH="$(command -v node)"
  HOST_NODE_VERSION="$(node --version 2>/dev/null || true)"

  if ! have brew; then
    return
  fi

  brew_prefix="$(brew --prefix)"
  if [[ "$HOST_NODE_PATH" != "$brew_prefix/bin/node" ]]; then
    return
  fi

  node_link="$(readlink "$HOST_NODE_PATH" 2>/dev/null || true)"
  case "$node_link" in
    ../Cellar/*/*/bin/node)
      relative="${node_link#../Cellar/}"
      HOST_BREW_NODE_FORMULA="${relative%%/*}"
      ;;
  esac
}

# Some Homebrew language-server formulas require Node. Install it as an
# unlinked dependency only when needed so the caller's selected Node stays
# active. Refuse an outdated active `node` formula because Brew could upgrade
# or relink it as a side effect of another install.
prepare_homebrew_node_dependency() {
  local outdated_node=""

  if [[ -z "$HOST_NODE_PATH" ]] || ! have brew; then
    return
  fi

  if [[ "$HOST_BREW_NODE_FORMULA" == "node" ]]; then
    if ! outdated_node="$(brew outdated --quiet node 2>/dev/null)"; then
      echo "cannot verify whether the active Homebrew node formula is current" >&2
      return 1
    fi
    if [[ -n "$outdated_node" ]]; then
      echo "cannot safely install language servers while the active Homebrew node formula is outdated" >&2
      echo "upgrade Node intentionally, or activate a versioned/external Node, then rerun bootstrap" >&2
      return 1
    fi
  fi

  if brew list --versions node >/dev/null 2>&1; then
    return
  fi

  echo "installing Homebrew Node for language servers without linking it"
  brew install --skip-link --as-dependency node
  hash -r
}

# Undo any Node link change made during the Homebrew phase, then prove that both
# its command path and version match the original. `hash -r` clears Bash's
# cached command locations before each comparison.
restore_host_node() {
  local brew_prefix current_path current_version

  if [[ -z "$HOST_NODE_PATH" ]]; then
    return
  fi

  hash -r
  current_path="$(command -v node 2>/dev/null || true)"
  current_version="$(node --version 2>/dev/null || true)"
  if [[ "$current_path" == "$HOST_NODE_PATH" && "$current_version" == "$HOST_NODE_VERSION" ]]; then
    return
  fi

  if ! have brew; then
    echo "Node changed during bootstrap and Homebrew is unavailable to restore it" >&2
    return 1
  fi

  brew_prefix="$(brew --prefix)"
  # Relink a Brew-owned original; if Node originally came from elsewhere,
  # unlink Brew's Node so the external or version-manager path wins again.
  if [[ -n "$HOST_BREW_NODE_FORMULA" ]]; then
    if brew list --versions node >/dev/null 2>&1; then
      brew unlink node >/dev/null
    fi
    brew link --force --overwrite "$HOST_BREW_NODE_FORMULA" >/dev/null
  elif [[ "$HOST_NODE_PATH" != "$brew_prefix/bin/node" ]]; then
    if brew list --versions node >/dev/null 2>&1; then
      brew unlink node >/dev/null
    fi
  else
    echo "Node changed during bootstrap and its original Homebrew formula is unknown" >&2
    return 1
  fi

  hash -r
  current_path="$(command -v node 2>/dev/null || true)"
  current_version="$(node --version 2>/dev/null || true)"
  if [[ "$current_path" != "$HOST_NODE_PATH" || "$current_version" != "$HOST_NODE_VERSION" ]]; then
    echo "Node changed during bootstrap and could not be restored" >&2
    echo "before: $HOST_NODE_PATH ($HOST_NODE_VERSION)" >&2
    echo "after: ${current_path:-missing} (${current_version:-missing})" >&2
    return 1
  fi

  echo "restored host-managed Node: $HOST_NODE_PATH ($HOST_NODE_VERSION)"
}

# Emergency cleanup if `set -e` aborts during Brew work. `|| true` preserves
# the original error; the normal success path performs a strict checked restore.
restore_host_node_on_exit() {
  if ((NODE_RESTORE_PENDING == 1)); then
    restore_host_node || true
  fi
}

# Keep any working command already on PATH and use Homebrew only to fill a
# missing capability. This makes reruns no-ops for tools that are already ready.
ensure_brew_command() {
  local command_name="$1"
  local formula="$2"

  if have "$command_name"; then
    echo "already available: $command_name ($(command -v "$command_name"))"
    return
  fi

  if have brew; then
    echo "installing $formula for $command_name"
    brew install "$formula"
  else
    echo "cannot install $command_name automatically: Homebrew is not available" >&2
  fi
}

# Presence alone is insufficient for Go 1.26 development. Keep a current gopls
# from any package manager, upgrade an active Homebrew copy, and refuse to
# replace a stale externally managed command behind its owner's back.
gopls_is_usable() {
  local output major minor patch

  have gopls || return 1
  output="$(gopls version 2>/dev/null || true)"
  [[ "$output" =~ gopls[[:space:]]+v?([0-9]+)\.([0-9]+)\.([0-9]+) ]] || return 1
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  patch="${BASH_REMATCH[3]}"
  ((10#$major > 0 || 10#$minor > 23 || (10#$minor == 23 && 10#$patch >= 0)))
}

ensure_gopls() {
  local active_path brew_prefix

  if gopls_is_usable; then
    echo "already available: gopls ($(command -v gopls))"
    return
  fi

  if have gopls; then
    active_path="$(command -v gopls)"
    if ! have brew; then
      echo "gopls 0.23.0+ is required; upgrade $active_path with its package manager" >&2
      return 1
    fi

    brew_prefix="$(brew --prefix)"
    if [[ "$active_path" != "$brew_prefix/bin/gopls" ]]; then
      echo "gopls 0.23.0+ is required; upgrade $active_path with its package manager" >&2
      return 1
    fi

    echo "upgrading Homebrew gopls to 0.23.0+"
    brew upgrade gopls
  elif have brew; then
    echo "installing gopls"
    brew install gopls
  else
    echo "cannot install gopls automatically: Homebrew is not available" >&2
    return
  fi

  hash -r
  if ! gopls_is_usable; then
    echo "gopls 0.23.0+ is still unavailable after Homebrew setup" >&2
    return 1
  fi
}

# One Homebrew formula supplies all four commands, so the bundle is available
# only when every server can be found on PATH.
vscode_language_servers_available() {
  local command_name

  for command_name in \
    vscode-eslint-language-server \
    vscode-json-language-server \
    vscode-css-language-server \
    vscode-html-language-server
  do
    if ! have "$command_name"; then
      return 1
    fi
  done

  return 0
}

# Install the shared formula only when its complete command bundle is missing.
# A complete existing bundle makes this function a no-op on later runs.
ensure_vscode_language_servers() {
  if vscode_language_servers_available; then
    echo "already available: VSCode language servers"
  elif have brew; then
    echo "installing vscode-langservers-extracted"
    brew install vscode-langservers-extracted
  else
    echo "cannot install VSCode language servers automatically: Homebrew is not available" >&2
  fi
}

# Prefer any existing command. Otherwise install or reuse the exact version in
# a private prefix instead of changing the caller's global npm packages.
ensure_graphql_lsp() {
  local prefix="$HOME/.local/graphql-lsp"
  local package_json="$prefix/lib/node_modules/graphql-language-service-cli/package.json"
  local wanted_version="3.5.0"
  local installed_version=""

  if have graphql-lsp; then
    echo "already available: graphql-lsp ($(command -v graphql-lsp))"
    return
  fi

  if have node && [[ -f "$package_json" ]]; then
    installed_version="$(node -p "require('$package_json').version" 2>/dev/null || true)"
  fi

  if [[ "$installed_version" == "$wanted_version" && -x "$prefix/bin/graphql-lsp" ]]; then
    echo "already available: graphql-lsp $wanted_version ($prefix/bin/graphql-lsp)"
    return
  fi

  if ! have npm; then
    echo "cannot install graphql-lsp: npm is not available" >&2
    return
  fi

  echo "installing graphql-language-service-cli@$wanted_version"
  npm install -g \
    --prefix "$prefix" \
    "graphql-language-service-cli@$wanted_version"
}

# Compare uv's recorded packages and extensions before reinstalling them. Ruff
# is checked in uv's own bin directory to avoid a duplicate install when the
# caller's PATH is stale; the dependency doctor reports that PATH gap later.
ensure_uv_tools() {
  local listing=""
  local ruff_command=""
  local uv_bin=""

  if ! have uv; then
    echo "cannot install mdformat or ruff: uv is not available" >&2
    return
  fi

  uv_bin="$(uv tool dir --bin)"
  listing="$(uv tool list --show-with --show-version-specifiers 2>/dev/null || true)"

  if printf '%s\n' "$listing" | grep -q '^mdformat v1\.0\.0 ' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-gfm==1\.0\.0' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-frontmatter==2\.1\.2' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-footnote==0\.1\.3' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-gfm-alerts==2\.0\.0' \
    && printf '%s\n' "$listing" | grep -q 'mdformat-wikilink==0\.3\.0'; then
    echo "already available: mdformat 1.0.0 with Obsidian-safe extensions"
  else
    uv tool install --force 'mdformat==1.0.0' \
      --with 'mdformat-gfm==1.0.0' \
      --with 'mdformat-frontmatter==2.1.2' \
      --with 'mdformat-footnote==0.1.3' \
      --with 'mdformat-gfm-alerts==2.0.0' \
      --with 'mdformat-wikilink==0.3.0'
  fi

  if [[ -x "$uv_bin/ruff" ]]; then
    ruff_command="$uv_bin/ruff"
  elif have ruff; then
    ruff_command="$(command -v ruff)"
  fi

  if [[ -n "$ruff_command" && "$("$ruff_command" --version 2>/dev/null || true)" == "ruff 0.15.21" ]]; then
    echo "already available: ruff 0.15.21"
  else
    uv tool install --force 'ruff==0.15.21'
  fi
}

echo "Bootstrapping Neovim ($PROFILE) from $REPO_ROOT"

# Arm EXIT cleanup before the first Homebrew command can alter Node. The pending
# flag stays set until the original Node has been restored and verified.
capture_host_node
if [[ -n "$HOST_NODE_PATH" ]]; then
  NODE_RESTORE_PENDING=1
  trap restore_host_node_on_exit EXIT
fi

# Core capabilities are required by every profile.
ensure_brew_command nvim neovim
ensure_brew_command git git
ensure_brew_command rg ripgrep
ensure_brew_command fd fd
ensure_brew_command fzf fzf
ensure_brew_command tree-sitter tree-sitter-cli
ensure_brew_command lazygit lazygit
ensure_brew_command curl curl

# Full includes core and adds the configured language servers and formatters.
if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]]; then
  ensure_brew_command uv uv
  # Prepare Brew's private Node only if at least one Node-backed Brew formula
  # is actually missing.
  if have brew \
    && { ! have bash-language-server \
      || ! have vtsls \
      || ! vscode_language_servers_available; }; then
    prepare_homebrew_node_dependency
  fi
  ensure_brew_command bash-language-server bash-language-server
  ensure_gopls
  if have gofmt; then
    echo "already available: gofmt ($(command -v gofmt))"
  else
    echo "host-managed prerequisite missing: gofmt (install the approved Go toolchain)" >&2
  fi
  ensure_brew_command lua-language-server lua-language-server
  ensure_brew_command stylua stylua
  ensure_brew_command vtsls vtsls
  ensure_vscode_language_servers
fi

# Desktop includes full and adds tools used for terminal image and PDF previews.
if [[ "$PROFILE" == "desktop" ]]; then
  ensure_brew_command magick imagemagick
  ensure_brew_command gs ghostscript
fi

# Finish the Homebrew phase by restoring Node, then disarm its emergency EXIT
# cleanup before npm- and uv-managed tools run in the restored environment.
restore_host_node
NODE_RESTORE_PENDING=0
trap - EXIT

if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]]; then
  ensure_uv_tools
  ensure_graphql_lsp
fi

# Install helpers can report gaps when Homebrew is unavailable; this doctor is
# the strict gate that fails if any selected-profile requirement is still absent.
"$SCRIPT_DIR/check-dependencies.sh" "$PROFILE"

# Lazy may write its lockfile while installing plugins. Preserve the committed
# bytes in a temporary file so every exit path can restore and verify them.
LOCKFILE="$REPO_ROOT/config/nvim/lazy-lock.json"
LOCKFILE_BACKUP="$(mktemp "${TMPDIR:-/tmp}/nvim-lazy-lock.XXXXXX")"

# This function serves as both normal cleanup and the EXIT-trap cleanup used
# when plugin restoration fails or is interrupted.
restore_lockfile() {
  if [[ -n "${LOCKFILE_BACKUP:-}" && -f "$LOCKFILE_BACKUP" ]]; then
    cp "$LOCKFILE_BACKUP" "$LOCKFILE"
    rm -f "$LOCKFILE_BACKUP"
  fi
}

if ! cp "$LOCKFILE" "$LOCKFILE_BACKUP"; then
  rm -f "$LOCKFILE_BACKUP"
  exit 1
fi

# A signal exits with the conventional 128-plus-signal status, which then runs
# the EXIT trap and restores the committed lockfile.
trap restore_lockfile EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

echo "restoring locked Neovim plugins"
# Leading `NAME=value` assignments affect this Neovim process only. They load
# the repo config directly and make Tree-sitter wait before headless Neovim exits.
DOTFILES_NVIM_BOOTSTRAP=1 \
  XDG_CONFIG_HOME="$REPO_ROOT/config" \
  nvim --headless '+Lazy! restore' +qa

# Lazy may rewrite the lock while installing missing plugins. Put the committed
# pins back before a second restore so every checkout converges to those pins.
cp "$LOCKFILE_BACKUP" "$LOCKFILE"
DOTFILES_NVIM_BOOTSTRAP=1 \
  XDG_CONFIG_HOME="$REPO_ROOT/config" \
  nvim --headless '+Lazy! restore' +qa

if ! cmp -s "$LOCKFILE_BACKUP" "$LOCKFILE"; then
  echo "Neovim plugin restore changed $LOCKFILE" >&2
  exit 1
fi

# Cleanup succeeded, so clear the temporary path and disarm the traps instead of
# running the same restoration again when the script exits normally.
restore_lockfile
LOCKFILE_BACKUP=""
trap - EXIT HUP INT TERM
