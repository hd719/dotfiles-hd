#!/usr/bin/env bash
# Stop on command errors, unset variables, and failures hidden in pipelines.
set -euo pipefail

usage() {
  echo "Usage: $0" >&2
  echo "Installs and configures mise for a personal Ubuntu machine." >&2
}

if [[ $# -ne 0 ]]; then
  usage
  exit 2
fi

# DOTFILES_DIR lets a QA clone own the link without touching another checkout.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
OS_RELEASE_FILE="${DOTFILES_OS_RELEASE_FILE:-/etc/os-release}"

if [[ ! -r "$OS_RELEASE_FILE" ]]; then
  echo "Cannot read Ubuntu version information: $OS_RELEASE_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$OS_RELEASE_FILE"
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "This installer supports Ubuntu only (detected: ${ID:-unknown})." >&2
  exit 1
fi

IFS=. read -r UBUNTU_MAJOR UBUNTU_MINOR _ <<<"${VERSION_ID:-}"
if [[ ! "$UBUNTU_MAJOR" =~ ^[0-9]+$ || ! "$UBUNTU_MINOR" =~ ^[0-9]+$ ]] \
  || ((10#$UBUNTU_MAJOR < 26)) \
  || ((10#$UBUNTU_MAJOR == 26 && 10#$UBUNTU_MINOR < 4)); then
  echo "Ubuntu 26.04 or newer is required (detected: ${VERSION_ID:-unknown})." >&2
  exit 1
fi

run_as_root() {
  if [[ "$(id -u)" == "0" ]]; then
    "$@"
    return
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required to install mise through APT." >&2
    exit 1
  fi

  sudo "$@"
}

# Accept an existing working mise command. On a fresh Ubuntu host, extrepo
# enables mise's official stable APT repository for both ARM64 and AMD64.
if command -v mise >/dev/null 2>&1; then
  if ! mise --version >/dev/null 2>&1; then
    echo "The mise command on PATH is broken: $(command -v mise)" >&2
    echo "Repair or remove that shadowing command, then rerun setup." >&2
    exit 1
  fi
else
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "apt-get is required to install mise on Ubuntu." >&2
    exit 1
  fi

  run_as_root apt-get update
  run_as_root apt-get install -y extrepo
  run_as_root extrepo enable mise
  run_as_root apt-get update
  run_as_root apt-get install -y mise
  hash -r
fi

if ! command -v mise >/dev/null 2>&1 || ! mise --version >/dev/null 2>&1; then
  echo "mise installation completed, but no working command is available on PATH." >&2
  exit 1
fi

SHARED_BOOTSTRAP="$DOTFILES_DIR/setup/mise/bootstrap.sh"
if [[ ! -x "$SHARED_BOOTSTRAP" ]]; then
  echo "Missing executable shared mise bootstrap: $SHARED_BOOTSTRAP" >&2
  exit 1
fi

# The shared seam owns the whole config link and every pinned runtime. The
# Ubuntu adapter owns only installation of the mise CLI itself.
"$SHARED_BOOTSTRAP" personal

echo "Ubuntu mise setup is ready."
