#!/usr/bin/env bash
# Stop on command errors, unset variables, and failures hidden in pipelines.
set -euo pipefail

# Ubuntu's normal packages should come from APT. A few editor tools are pinned
# below because Ubuntu 26.04 ships versions older than this Neovim config needs.

print_usage() {
  cat <<'EOF'
Usage: install-neovim-dependencies.sh [core|full|desktop]

Profiles are cumulative; choose one:
  core     Neovim, search, Tree-sitter, LazyGit, and build tools.
  full     Core plus language servers and formatters. (default)
  desktop  Full plus image/PDF previews and a system file opener.

This adapter supports Ubuntu 26.04 or newer. It uses APT and pinned upstream
Linux binaries; it never installs Homebrew or Snap packages.
EOF
}

PROFILE="${1:-full}"
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

# Tests substitute a disposable os-release file. Real machines use Ubuntu's
# standard file without needing a special flag.
OS_RELEASE_FILE="${DOTFILES_OS_RELEASE_FILE:-/etc/os-release}"
if [[ ! -r "$OS_RELEASE_FILE" ]]; then
  echo "cannot read OS information: $OS_RELEASE_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$OS_RELEASE_FILE"
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "this dependency adapter supports Ubuntu only (found: ${ID:-unknown})" >&2
  exit 1
fi

version_major="${VERSION_ID%%.*}"
version_minor="${VERSION_ID#*.}"
version_minor="${version_minor%%.*}"
if [[ ! "$version_major" =~ ^[0-9]+$ || ! "$version_minor" =~ ^[0-9]+$ ]] \
  || ((10#$version_major < 26)) \
  || ((10#$version_major == 26 && 10#$version_minor < 4)); then
  echo "Ubuntu 26.04 or newer is required (found: ${VERSION_ID:-unknown})" >&2
  exit 1
fi

case "$(dpkg --print-architecture 2>/dev/null || uname -m)" in
  arm64 | aarch64)
    DEB_ARCH="arm64"
    NVIM_ARCH="arm64"
    TREE_SITTER_ARCH="arm64"
    LUALS_ARCH="arm64"
    STYLUA_ARCH="aarch64"
    UV_ARCH="aarch64"
    ;;
  amd64 | x86_64)
    DEB_ARCH="amd64"
    NVIM_ARCH="x86_64"
    TREE_SITTER_ARCH="x64"
    LUALS_ARCH="x64"
    STYLUA_ARCH="x86_64"
    UV_ARCH="x86_64"
    ;;
  *)
    echo "unsupported CPU architecture" >&2
    exit 1
    ;;
esac

LOCAL_BIN="$HOME/.local/bin"
LOCAL_OPT="$HOME/.local/opt"
NODE_TOOLS_PREFIX="$HOME/.local/nvim-node-tools"
export PATH="$LOCAL_BIN:$PATH"

have() {
  command -v "$1" >/dev/null 2>&1
}

# The pinned TypeScript server requires Node 18 or newer. Keep newer host
# runtimes exactly as they are; stop instead of silently replacing an old one.
node_is_supported() {
  local version major

  have node || return 1
  version="$(node --version 2>/dev/null || true)"
  version="${version#v}"
  major="${version%%.*}"
  [[ "$major" =~ ^[0-9]+$ ]] && ((10#$major >= 18))
}

# Remember a working Node before any package operation. Full setup must not
# silently replace a mise-managed (or otherwise host-managed) runtime.
HOST_NODE_PATH=""
HOST_NODE_VERSION=""
if have node; then
  HOST_NODE_PATH="$(command -v node)"
  HOST_NODE_VERSION="$(node --version 2>/dev/null || true)"
fi

# Older revisions of these dotfiles removed npm from mise's Node installation.
# Reinstalling the exact same mise version repairs npm without selecting a new
# Node release. Any unexpected path or version change aborts setup.
repair_mise_npm() {
  local managed_node wanted_version current_path current_version
  local node_bin node_root global_modules entry entry_name

  [[ -n "$HOST_NODE_PATH" ]] || return 0
  have npm && return 0
  have mise || return 0

  managed_node="$(mise which node 2>/dev/null || true)"
  [[ "$managed_node" == "$HOST_NODE_PATH" ]] || return 0

  wanted_version="${HOST_NODE_VERSION#v}"
  [[ -n "$wanted_version" ]] || return 0

  node_bin="$(dirname "$HOST_NODE_PATH")"
  node_root="$(cd "$node_bin/.." && pwd -P)"
  global_modules="$node_root/lib/node_modules"

  # A forced mise reinstall replaces the complete Node version directory. It is
  # safe for the historical npm-only damage, but not when the user installed
  # unrelated global packages or commands into that same directory.
  if [[ -d "$global_modules" ]]; then
    for entry in "$global_modules"/*; do
      [[ -e "$entry" || -L "$entry" ]] || continue
      entry_name="${entry##*/}"
      case "$entry_name" in
        npm | corepack) ;;
        *)
          echo "automatic npm repair refused: existing global Node package $entry_name" >&2
          echo "repair npm manually, then rerun setup" >&2
          exit 1
          ;;
      esac
    done
  fi

  for entry in "$node_bin"/*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    entry_name="${entry##*/}"
    case "$entry_name" in
      node | npm | npx | corepack) ;;
      *)
        echo "automatic npm repair refused: existing global Node command $entry_name" >&2
        echo "repair npm manually, then rerun setup" >&2
        exit 1
        ;;
    esac
  done

  echo "repairing npm in the existing mise Node $wanted_version"
  if ! mise install --force "node@$wanted_version"; then
    echo "mise could not repair npm; APT will fill the missing npm capability" >&2
    return 0
  fi
  mise reshim
  hash -r

  current_path="$(command -v node 2>/dev/null || true)"
  current_version="$(node --version 2>/dev/null || true)"
  if [[ "$current_path" != "$HOST_NODE_PATH" || "$current_version" != "$HOST_NODE_VERSION" ]]; then
    echo "Node changed while repairing npm; stopping for safety" >&2
    echo "before: $HOST_NODE_PATH ($HOST_NODE_VERSION)" >&2
    echo "after: ${current_path:-missing} (${current_version:-missing})" >&2
    exit 1
  fi
}

if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]]; then
  # A half-visible Go toolchain is usually a PATH or host-manager problem. Stop
  # before npm repair or APT can mutate anything unrelated to that problem.
  if have go && ! have gofmt; then
    echo "the active Go toolchain provides go but not gofmt" >&2
    echo "repair that host-managed Go installation, then rerun setup" >&2
    exit 1
  elif ! have go && have gofmt; then
    echo "the active Go toolchain provides gofmt but not go" >&2
    echo "repair that host-managed Go installation, then rerun setup" >&2
    exit 1
  fi

  if have node && ! node_is_supported; then
    echo "Node 18 or newer is required for the full Neovim profile (found: $(node --version 2>/dev/null || echo unknown))" >&2
    echo "activate a supported host-managed Node, then rerun setup" >&2
    exit 1
  fi
  repair_mise_npm
fi

# Build one APT transaction from missing commands. This keeps the second run a
# no-op and accepts tools already supplied by a version manager or system image.
APT_PACKAGES=()
need_package() {
  local command_name="$1"
  local package_name="$2"

  have "$command_name" || APT_PACKAGES+=("$package_name")
}

need_package git git
need_package rg ripgrep
if ! have fd && ! have fdfind; then
  APT_PACKAGES+=(fd-find)
fi
need_package fzf fzf
need_package lazygit lazygit
need_package cc build-essential
if ! have curl; then
  APT_PACKAGES+=(ca-certificates curl)
fi
need_package unzip unzip
need_package tar tar
need_package gzip gzip

if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]]; then
  need_package node nodejs
  need_package npm npm
  if ! have go; then
    APT_PACKAGES+=(golang-go)
  fi
fi

if [[ "$PROFILE" == "desktop" ]]; then
  need_package magick imagemagick
  need_package gs ghostscript
  need_package xdg-open xdg-utils
fi

run_apt_install() {
  if ((EUID == 0)); then
    apt-get update
    env DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES[@]}"
    return
  fi

  have sudo || {
    echo "sudo is required to install Ubuntu packages for a non-root user" >&2
    exit 1
  }

  sudo apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES[@]}"
}

if ((${#APT_PACKAGES[@]} > 0)); then
  echo "installing missing Ubuntu packages: ${APT_PACKAGES[*]}"
  run_apt_install
  hash -r
fi

if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]] && ! node_is_supported; then
  echo "Node 18 or newer is required for the full Neovim profile (found: $(node --version 2>/dev/null || echo missing))" >&2
  exit 1
fi

mkdir -p "$LOCAL_BIN" "$LOCAL_OPT"

# Back up a conflicting user-local command rather than deleting it. Managed
# version directories are immutable, so later runs resolve to the same target.
link_local_command() {
  local source_path="$1"
  local command_name="$2"
  local destination="$LOCAL_BIN/$command_name"
  local current_target backup

  if [[ -L "$destination" ]]; then
    current_target="$(readlink "$destination")"
    [[ "$current_target" == "$source_path" ]] && return 0
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    backup="$destination.backup-$(date +%Y%m%d-%H%M%S)"
    echo "backing up conflicting command: $destination -> $backup"
    mv "$destination" "$backup"
  fi

  ln -s "$source_path" "$destination"
  hash -r
}

# Ubuntu names fd's binary `fdfind`. Expose the conventional command name that
# the shared Neovim doctor and plugins expect, with the same backup protection
# used for every other user-local link.
if ! have fd && have fdfind; then
  link_local_command "$(command -v fdfind)" fd
fi

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-ubuntu-nvim.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# Every upstream artifact is tied to both an exact release and SHA-256 digest.
# A corrupt, truncated, or replaced download fails before it reaches PATH.
download_verified() {
  local url="$1"
  local sha256="$2"
  local destination="$3"

  curl -fsSL --retry 3 -o "$destination" "$url"
  printf '%s  %s\n' "$sha256" "$destination" | sha256sum -c - >/dev/null
}

neovim_is_usable() {
  local line version major minor

  have nvim || return 1
  line="$(nvim --version 2>/dev/null | sed -n '1p')"
  version="${line#NVIM v}"
  version="${version%% *}"
  major="${version%%.*}"
  minor="${version#*.}"
  minor="${minor%%.*}"
  [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] || return 1
  ((10#$major > 0 || 10#$minor >= 12))
}

tree_sitter_is_usable() {
  local line version major minor patch remainder

  have tree-sitter || return 1
  line="$(tree-sitter --version 2>/dev/null || true)"
  version="${line#tree-sitter }"
  version="${version%% *}"
  [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]] || return 1
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  patch="${BASH_REMATCH[3]}"
  remainder="${version#*.*.}"
  : "$remainder"
  ((10#$major > 0 || 10#$minor > 26 || (10#$minor == 26 && 10#$patch >= 1)))
}

ensure_neovim() {
  local version="0.12.4"
  local asset="nvim-linux-$NVIM_ARCH.tar.gz"
  local sha256 target archive staging source_dir

  neovim_is_usable && return 0

  case "$DEB_ARCH" in
    arm64) sha256="ceb7e88c6b681f0515d135dcdfad54f5eb4373b25ce6172197cd9a69c758063f" ;;
    amd64) sha256="012bf3fcac5ade43914df3f174668bf64d05e049a4f032a388c027b1ebd78628" ;;
  esac

  target="$LOCAL_OPT/nvim/$version"
  if [[ ! -x "$target/bin/nvim" ]]; then
    archive="$TMP_ROOT/$asset"
    staging="$TMP_ROOT/nvim"
    mkdir -p "$staging" "$(dirname "$target")"
    download_verified \
      "https://github.com/neovim/neovim/releases/download/v$version/$asset" \
      "$sha256" "$archive"
    tar -xzf "$archive" -C "$staging"
    source_dir="$staging/nvim-linux-$NVIM_ARCH"
    [[ -x "$source_dir/bin/nvim" ]] || {
      echo "downloaded Neovim archive has an unexpected layout" >&2
      exit 1
    }
    rm -rf "$target"
    mv "$source_dir" "$target"
  fi

  link_local_command "$target/bin/nvim" nvim
}

ensure_tree_sitter() {
  local version="0.26.11"
  local asset="tree-sitter-linux-$TREE_SITTER_ARCH.gz"
  local sha256 target archive

  tree_sitter_is_usable && return 0

  case "$DEB_ARCH" in
    arm64) sha256="e47dd59bf2f21ad7c15771546a724464ee3c008a60fbb61c6860bd19a44b3060" ;;
    amd64) sha256="8dac3c89bb632eece700ea7a261ad963b251f2228c4aef3b58458ebea8dbe4eb" ;;
  esac

  target="$LOCAL_OPT/tree-sitter/$version/tree-sitter"
  if [[ ! -x "$target" ]]; then
    archive="$TMP_ROOT/$asset"
    mkdir -p "$(dirname "$target")"
    download_verified \
      "https://github.com/tree-sitter/tree-sitter/releases/download/v$version/$asset" \
      "$sha256" "$archive"
    gzip -dc "$archive" >"$target"
    chmod +x "$target"
  fi

  link_local_command "$target" tree-sitter
}

ensure_lua_language_server() {
  local version="3.18.2"
  local asset="lua-language-server-$version-linux-$LUALS_ARCH.tar.gz"
  local sha256 target archive staging

  have lua-language-server && return 0

  case "$DEB_ARCH" in
    arm64) sha256="273af33f26f4a1143f27c96d9f9e1188aba619c71e0807042134f66b4bd27f24" ;;
    amd64) sha256="ca71415dd19f19e30aaa35a4915aefca9fdb5fec31b98331cc3d77f778d539c5" ;;
  esac

  target="$LOCAL_OPT/lua-language-server/$version"
  if [[ ! -x "$target/bin/lua-language-server" ]]; then
    archive="$TMP_ROOT/$asset"
    staging="$TMP_ROOT/lua-language-server"
    mkdir -p "$staging" "$(dirname "$target")"
    download_verified \
      "https://github.com/LuaLS/lua-language-server/releases/download/$version/$asset" \
      "$sha256" "$archive"
    tar -xzf "$archive" -C "$staging"
    [[ -x "$staging/bin/lua-language-server" ]] || {
      echo "downloaded Lua language server has an unexpected layout" >&2
      exit 1
    }
    rm -rf "$target"
    mv "$staging" "$target"
  fi

  link_local_command "$target/bin/lua-language-server" lua-language-server
}

ensure_stylua() {
  local version="2.5.2"
  local asset="stylua-linux-$STYLUA_ARCH.zip"
  local sha256 target archive staging source_path

  have stylua && return 0

  case "$DEB_ARCH" in
    arm64) sha256="0ef2ebf0b7e5a652b65c4cb96c6d9ffb3981a98547de3c764465bbf54a8d761a" ;;
    amd64) sha256="bcb0d855e91f102f28a370e850f8566b3b44b79e6274d806ea5246837c0fd5ab" ;;
  esac

  target="$LOCAL_OPT/stylua/$version/stylua"
  if [[ ! -x "$target" ]]; then
    archive="$TMP_ROOT/$asset"
    staging="$TMP_ROOT/stylua"
    mkdir -p "$staging" "$(dirname "$target")"
    download_verified \
      "https://github.com/JohnnyMorganz/StyLua/releases/download/v$version/$asset" \
      "$sha256" "$archive"
    unzip -q "$archive" -d "$staging"
    source_path="$staging/stylua"
    [[ -x "$source_path" ]] || source_path="$staging/bin/stylua"
    [[ -x "$source_path" ]] || {
      echo "downloaded StyLua archive has an unexpected layout" >&2
      exit 1
    }
    mv "$source_path" "$target"
  fi

  link_local_command "$target" stylua
}

ensure_uv() {
  local version="0.11.28"
  local asset="uv-$UV_ARCH-unknown-linux-gnu.tar.gz"
  local sha256 target archive staging source_dir

  have uv && return 0

  case "$DEB_ARCH" in
    arm64) sha256="03e9fe0a81b0718d0bc84625de3885df6cc3f89a8b6af6121d6b9f6113fb6533" ;;
    amd64) sha256="e490a6464492183c5d4534a5527fb4440f7f2bb2f228162ad7e4afe076dc0224" ;;
  esac

  target="$LOCAL_OPT/uv/$version"
  if [[ ! -x "$target/uv" || ! -x "$target/uvx" ]]; then
    archive="$TMP_ROOT/$asset"
    staging="$TMP_ROOT/uv"
    mkdir -p "$staging" "$(dirname "$target")"
    download_verified \
      "https://github.com/astral-sh/uv/releases/download/$version/$asset" \
      "$sha256" "$archive"
    tar -xzf "$archive" -C "$staging"
    source_dir="$staging/uv-$UV_ARCH-unknown-linux-gnu"
    [[ -x "$source_dir/uv" && -x "$source_dir/uvx" ]] || {
      echo "downloaded uv archive has an unexpected layout" >&2
      exit 1
    }
    rm -rf "$target"
    mv "$source_dir" "$target"
  fi

  link_local_command "$target/uv" uv
  link_local_command "$target/uvx" uvx
}

ensure_node_servers() {
  local command_name source_path
  local -a missing_commands=()

  for command_name in \
    bash-language-server \
    vtsls \
    vscode-eslint-language-server \
    vscode-json-language-server \
    vscode-css-language-server \
    vscode-html-language-server \
    graphql-lsp
  do
    have "$command_name" || missing_commands+=("$command_name")
  done

  ((${#missing_commands[@]} > 0)) || return 0
  have node || {
    echo "Node is required for the full Neovim profile" >&2
    exit 1
  }
  have npm || {
    echo "npm is required for the full Neovim profile" >&2
    exit 1
  }

  # A private prefix avoids changing the user's global npm package set.
  npm install -g --prefix "$NODE_TOOLS_PREFIX" \
    'bash-language-server@5.6.0' \
    '@vtsls/language-server@0.3.0' \
    'vscode-langservers-extracted@4.10.0' \
    'graphql-language-service-cli@3.5.0'

  # Link only capabilities that were missing before installation. A working
  # server supplied by the host stays selected instead of being shadowed.
  for command_name in "${missing_commands[@]}"; do
    source_path="$NODE_TOOLS_PREFIX/bin/$command_name"
    [[ -x "$source_path" ]] || {
      echo "npm did not provide the expected command: $command_name" >&2
      exit 1
    }
    link_local_command "$source_path" "$command_name"
  done
}

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
  local local_gopls="$LOCAL_BIN/gopls"
  local backup

  gopls_is_usable && return 0
  have go || {
    echo "Go is required to install gopls" >&2
    exit 1
  }
  have gofmt || {
    echo "gofmt is required for the full Neovim profile" >&2
    exit 1
  }

  # `go install` writes directly to GOBIN. Preserve a stale user-local binary
  # before replacing it, just as we do for managed symlinks.
  if [[ -e "$local_gopls" || -L "$local_gopls" ]]; then
    backup="$local_gopls.backup-$(date +%Y%m%d-%H%M%S)"
    echo "backing up stale gopls: $local_gopls -> $backup"
    mv "$local_gopls" "$backup"
  fi

  GOBIN="$LOCAL_BIN" go install 'golang.org/x/tools/gopls@v0.23.0'
  hash -r
  gopls_is_usable || {
    echo "installed gopls does not report version 0.23.0 or newer" >&2
    exit 1
  }
}

verify_host_node() {
  local current_path current_version

  [[ -n "$HOST_NODE_PATH" ]] || return 0
  hash -r
  current_path="$(command -v node 2>/dev/null || true)"
  current_version="$(node --version 2>/dev/null || true)"
  if [[ "$current_path" != "$HOST_NODE_PATH" || "$current_version" != "$HOST_NODE_VERSION" ]]; then
    echo "Node changed during Ubuntu dependency setup" >&2
    echo "before: $HOST_NODE_PATH ($HOST_NODE_VERSION)" >&2
    echo "after: ${current_path:-missing} (${current_version:-missing})" >&2
    exit 1
  fi
}

echo "Installing Ubuntu Neovim dependencies ($PROFILE, $DEB_ARCH)"
ensure_neovim
ensure_tree_sitter

if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]]; then
  ensure_lua_language_server
  ensure_stylua
  ensure_uv
  ensure_node_servers
  ensure_gopls
  verify_host_node
fi

echo "Ubuntu Neovim dependency adapter complete."
echo "Next: export PATH=\"\$HOME/.local/bin:\$PATH\""
echo "Then: setup/nvim/link-config.sh"
echo "Then: setup/nvim/bootstrap.sh $PROFILE"
