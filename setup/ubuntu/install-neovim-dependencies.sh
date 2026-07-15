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
NODE_TOOLS_PREFIX="$HOME/.local/nvim-pnpm-tools"
NODE_TOOLS_GLOBAL_DIR="$NODE_TOOLS_PREFIX/global"
NODE_TOOLS_BIN_DIR="$NODE_TOOLS_PREFIX/bin"
NODE_TOOLS_STORE_DIR="$NODE_TOOLS_PREFIX/store"
NODE_TOOLS_MANIFEST="$NODE_TOOLS_PREFIX/.dotfiles-package-pins"
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

# Run the command instead of trusting a possibly broken shim. The private
# global-directory layout below is defined for pnpm 11, which personal machines
# receive from the shared mise config.
pnpm_is_supported() {
  local version major

  have pnpm || return 1
  version="$(pnpm --version 2>/dev/null || true)"
  major="${version%%.*}"
  [[ "$major" =~ ^[0-9]+$ ]] && ((10#$major >= 11))
}

# Remember a working Node before any package operation. Full setup must not
# silently replace a mise-managed (or otherwise host-managed) runtime.
HOST_NODE_PATH=""
HOST_NODE_VERSION=""
if have node; then
  HOST_NODE_PATH="$(command -v node)"
  HOST_NODE_VERSION="$(node --version 2>/dev/null || true)"
fi

if [[ "$PROFILE" == "full" || "$PROFILE" == "desktop" ]]; then
  # A half-visible Go toolchain is usually a PATH or host-manager problem. Stop
  # before APT can mutate anything unrelated to that problem.
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

  # Personal machines receive this exact command from the shared mise config.
  # Other full-profile hosts must provide an approved pnpm before system changes.
  pnpm_is_supported || {
    echo "pnpm 11 or newer is required for the full Neovim profile" >&2
    echo "on a personal Ubuntu machine, run setup/ubuntu/install-mise.sh first" >&2
    exit 1
  }
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

# Never delete an unexpected file or directory in a managed location. A
# timestamped sibling preserves it for inspection, and a numeric suffix handles
# two repairs that begin during the same second.
backup_conflicting_path() {
  local path="$1"
  local base backup suffix=1

  [[ -e "$path" || -L "$path" ]] || return 0
  base="$path.backup-$(date +%Y%m%d-%H%M%S)"
  backup="$base"
  while [[ -e "$backup" || -L "$backup" ]]; do
    backup="$base-$suffix"
    suffix=$((suffix + 1))
  done

  echo "backing up conflicting path: $path -> $backup"
  mv "$path" "$backup"
}

# Back up a conflicting user-local command rather than deleting it. Managed
# version directories are immutable, so later runs resolve to the same target.
link_local_command() {
  local source_path="$1"
  local command_name="$2"
  local destination="$LOCAL_BIN/$command_name"
  local current_target

  if [[ -L "$destination" ]]; then
    current_target="$(readlink "$destination")"
    [[ "$current_target" == "$source_path" ]] && return 0
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    backup_conflicting_path "$destination"
  fi

  ln -s "$source_path" "$destination"
  hash -r
}

# pnpm's generated command shims locate their packages relative to `$0`. A
# symlink from ~/.local/bin changes `$0` and makes those shims search in the
# wrong directory, so expose them through a tiny wrapper that executes the real
# shim by its absolute path. Existing machine-local commands are backed up by
# the same rule as every other managed command.
install_local_exec_wrapper() {
  local source_path="$1"
  local command_name="$2"
  local destination="$LOCAL_BIN/$command_name"
  local temporary

  if pnpm_wrapper_is_current "$source_path" "$destination"; then
    return 0
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    backup_conflicting_path "$destination"
  fi

  temporary="$(mktemp "$LOCAL_BIN/.${command_name}.XXXXXX")"
  pnpm_wrapper_contents "$source_path" >"$temporary"
  chmod +x "$temporary"
  mv "$temporary" "$destination"
  hash -r
}

# Keep wrapper generation and validation byte-for-byte identical. The executable
# bit is part of the contract; a launcher that cannot run is not a healthy no-op.
pnpm_wrapper_contents() {
  local source_path="$1"

  printf '#!/usr/bin/env bash\n'
  printf '# dotfiles-managed pnpm wrapper: %s\n' "$source_path"
  printf 'exec %q "$@"\n' "$source_path"
}

pnpm_wrapper_is_current() {
  local source_path="$1"
  local destination="$2"
  local actual expected

  [[ -f "$destination" && ! -L "$destination" && -x "$destination" ]] \
    || return 1
  actual="$(<"$destination")"
  expected="$(pnpm_wrapper_contents "$source_path")"
  [[ "$actual" == "$expected" ]]
}

is_managed_pnpm_wrapper() {
  local source_path="$1"
  local destination="$2"

  [[ -f "$destination" && ! -L "$destination" ]] \
    && grep -Fqx "# dotfiles-managed pnpm wrapper: $source_path" "$destination"
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
    backup_conflicting_path "$target"
    mv "$source_dir" "$target"
  fi

  link_local_command "$target/bin/nvim" nvim
}

ensure_tree_sitter() {
  local version="0.26.11"
  local asset="tree-sitter-linux-$TREE_SITTER_ARCH.gz"
  local sha256 target archive staging

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
    staging="$TMP_ROOT/tree-sitter"
    gzip -dc "$archive" >"$staging"
    chmod +x "$staging"
    backup_conflicting_path "$target"
    mv "$staging" "$target"
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
    backup_conflicting_path "$target"
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
    backup_conflicting_path "$target"
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
    backup_conflicting_path "$target"
    mv "$source_dir" "$target"
  fi

  link_local_command "$target/uv" uv
  link_local_command "$target/uvx" uvx
}

# Ask pnpm for the installed package graph and let Node validate the exact pins
# plus each package directory. Executable shims alone are not proof of a healthy
# install: a deleted global payload leaves those small launcher files behind.
pnpm_node_tools_match_install() {
  local expected_manifest="$1"
  local listing command_name
  shift

  for command_name in "$@"; do
    [[ -x "$NODE_TOOLS_BIN_DIR/$command_name" ]] || return 1
  done

  listing="$(
    PNPM_HOME="$NODE_TOOLS_PREFIX" PATH="$NODE_TOOLS_BIN_DIR:$PATH" \
      pnpm list --global --depth=0 \
        --global-dir "$NODE_TOOLS_GLOBAL_DIR" \
        --json 2>/dev/null
  )" || return 1

  NODE_TOOL_SPECS="$expected_manifest" node -e '
    const fs = require("fs");
    const roots = JSON.parse(fs.readFileSync(0, "utf8"));
    const dependencies = roots[0]?.dependencies ?? {};

    for (const spec of process.env.NODE_TOOL_SPECS.split("\n")) {
      const separator = spec.lastIndexOf("@");
      const name = spec.slice(0, separator);
      const version = spec.slice(separator + 1);
      const dependency = dependencies[name];

      if (!dependency || dependency.version !== version || !fs.existsSync(dependency.path)) {
        process.exit(1);
      }
    }
  ' <<<"$listing"
}

ensure_node_servers() {
  local command_name current_path current_target expected_manifest source_path
  local managed_commands=0
  local needs_install=0
  local -a missing_commands=()
  local -a package_specs=(
    'bash-language-server@5.6.0'
    '@vtsls/language-server@0.3.0'
    'vscode-langservers-extracted@4.10.0'
    'graphql-language-service-cli@3.5.0'
  )
  local -a command_names=(
    bash-language-server
    vtsls
    vscode-eslint-language-server
    vscode-json-language-server
    vscode-css-language-server
    vscode-html-language-server
    graphql-lsp
  )

  expected_manifest="$(printf '%s\n' "${package_specs[@]}")"

  for command_name in "${command_names[@]}"; do
    if ! have "$command_name"; then
      missing_commands+=("$command_name")
      continue
    fi

    current_path="$(command -v "$command_name")"
    if [[ "$current_path" == "$LOCAL_BIN/$command_name" ]]; then
      if [[ -L "$current_path" ]]; then
        current_target="$(readlink "$current_path")"
        if [[ "$current_target" == "$NODE_TOOLS_BIN_DIR/$command_name" \
          || "$current_target" == "$HOME/.local/nvim-node-tools/bin/$command_name" ]]; then
          # Migrate both the broken pnpm symlink shape and links produced by the
          # earlier npm-backed implementation to absolute exec wrappers.
          managed_commands=1
          missing_commands+=("$command_name")
        fi
      elif is_managed_pnpm_wrapper "$NODE_TOOLS_BIN_DIR/$command_name" "$current_path"; then
        managed_commands=1
        pnpm_wrapper_is_current "$NODE_TOOLS_BIN_DIR/$command_name" "$current_path" \
          && [[ -x "$NODE_TOOLS_BIN_DIR/$command_name" ]] \
          || missing_commands+=("$command_name")
      fi
    fi
  done

  # A manifest means this adapter owns a private package set even if every host
  # command currently resolves somewhere else. Validate that owned state instead
  # of letting a corrupt payload remain hidden behind executable launcher files.
  if ((managed_commands == 1)) || [[ -f "$NODE_TOOLS_MANIFEST" ]]; then
    if [[ ! -f "$NODE_TOOLS_MANIFEST" ]] \
      || [[ "$(<"$NODE_TOOLS_MANIFEST")" != "$expected_manifest" ]] \
      || ! pnpm_node_tools_match_install "$expected_manifest" "${command_names[@]}"; then
      needs_install=1
    fi
  fi

  if ((${#missing_commands[@]} == 0 && needs_install == 0)); then
    return 0
  fi

  have node || {
    echo "Node is required for the full Neovim profile" >&2
    exit 1
  }
  pnpm_is_supported || {
    echo "pnpm 11 or newer is required for the full Neovim profile" >&2
    exit 1
  }

  # Keep Neovim's pinned packages in a private pnpm store and bin directory.
  # PNPM_HOME plus PATH satisfies pnpm's global-bin safety check without
  # changing the caller's normal global packages or shell configuration.
  mkdir -p "$NODE_TOOLS_GLOBAL_DIR" "$NODE_TOOLS_BIN_DIR" "$NODE_TOOLS_STORE_DIR"
  PNPM_HOME="$NODE_TOOLS_PREFIX" PATH="$NODE_TOOLS_BIN_DIR:$PATH" \
    pnpm add --global \
      --global-dir "$NODE_TOOLS_GLOBAL_DIR" \
      --global-bin-dir "$NODE_TOOLS_BIN_DIR" \
      --store-dir "$NODE_TOOLS_STORE_DIR" \
      --save-exact \
      "${package_specs[@]}"

  pnpm_node_tools_match_install "$expected_manifest" "${command_names[@]}" || {
    echo "pnpm did not provide the complete pinned language-server set" >&2
    exit 1
  }
  printf '%s\n' "${package_specs[@]}" >"$NODE_TOOLS_MANIFEST"

  # Wrap only capabilities that were missing before installation. A working
  # server supplied by the host stays selected instead of being shadowed.
  for command_name in "${missing_commands[@]}"; do
    source_path="$NODE_TOOLS_BIN_DIR/$command_name"
    [[ -x "$source_path" ]] || {
      echo "pnpm did not provide the expected command: $command_name" >&2
      exit 1
    }
    install_local_exec_wrapper "$source_path" "$command_name"
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
    backup_conflicting_path "$local_gopls"
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
