#!/usr/bin/env bash

# System Update Script for Ubuntu

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if [[ -d "$HOME/.local/share/pnpm" ]]; then
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

section() {
    echo -e "${BLUE}$1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}\n"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

has() {
    command -v "$1" >/dev/null 2>&1
}

update_apt() {
    section "📦 Updating APT packages..."
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
    sudo DEBIAN_FRONTEND=noninteractive apt autoremove -y
    sudo apt autoclean
    success "APT packages updated"
}

update_snap() {
    has snap || return 0

    section "📦 Updating Snap packages..."
    sudo snap refresh

    LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' | while read -r snapname revision; do
        sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
    done

    success "Snap packages updated"
}

update_flatpak() {
    has flatpak || return 0

    section "📦 Updating Flatpak packages..."
    flatpak update -y
    success "Flatpak packages updated"
}

update_node_packages() {
    if has pnpm; then
        section "📦 Updating pnpm global packages..."
        pnpm self-update || pnpm add -g pnpm@latest || warn "pnpm self-update skipped or failed"
        pnpm update -g || warn "pnpm global update skipped or failed"
        success "pnpm checked"
    fi
}

update_uv() {
    has uv || return 0

    section "📦 Updating uv..."
    uv self update || curl -LsSf https://astral.sh/uv/install.sh | sh
    success "uv updated"
}

update_mise() {
    has mise || return 0

    section "📦 Updating mise toolchain..."
    # CLI upgrades belong to the Ubuntu bootstrap/package owner. This update
    # path converges only the shared runtime and language-server pins.
    mise install --yes
    mise reshim
    eval "$(mise activate bash)"
    # Keep npm and npx. Neovim uses npm to install some language servers.
    mise outdated || true
    success "mise toolchain updated"
}

update_rust() {
    has rustup || return 0

    section "📦 Updating Rust..."
    rustup update
    success "Rust updated"
}

check_firmware() {
    has fwupdmgr || return 0

    section "🔧 Checking firmware updates..."
    fwupdmgr refresh --force 2>/dev/null || true
    fwupdmgr get-updates 2>/dev/null || echo -e "${GREEN}✓ No firmware updates available${NC}"
    echo ""
}

pending_apt_count() {
    apt list --upgradable 2>/dev/null | awk 'NR > 1 {count++} END {print count + 0}'
}

print_summary() {
    echo -e "${MAGENTA}📊 System Information:${NC}"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Pending APT updates: $(pending_apt_count)"

    if [[ -f /var/run/reboot-required ]]; then
        warn "Reboot required"
    else
        echo "Reboot required: no"
    fi

    echo -e "\n${GREEN}✅ System update complete!${NC}"
}

main() {
    echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
    echo -e "${MAGENTA}🔄 Starting System Update...${NC}\n"

    sudo -v

    update_apt
    update_snap
    update_flatpak
    update_mise
    update_uv
    update_node_packages
    update_rust
    check_firmware
    print_summary

    echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
}

main "$@"
