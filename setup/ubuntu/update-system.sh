#!/usr/bin/env bash

# System Update Script for Ubuntu
# Updates all packages, snaps, and other package managers

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"

echo -e "${MAGENTA}🔄 Starting System Update...${NC}\n"

# Update apt packages
echo -e "${BLUE}📦 Updating APT packages...${NC}"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean
echo -e "${GREEN}✓ APT packages updated${NC}\n"

# Update snap packages
if command -v snap &>/dev/null; then
    echo -e "${BLUE}📦 Updating Snap packages...${NC}"
    sudo snap refresh
    echo -e "${GREEN}✓ Snap packages updated${NC}\n"
fi

# Update flatpak packages (if installed)
if command -v flatpak &>/dev/null; then
    echo -e "${BLUE}📦 Updating Flatpak packages...${NC}"
    flatpak update -y
    echo -e "${GREEN}✓ Flatpak packages updated${NC}\n"
fi

# Update npm global packages (if installed)
if command -v npm &>/dev/null; then
    echo -e "${BLUE}📦 Updating NPM global packages...${NC}"
    npm update -g
    echo -e "${GREEN}✓ NPM packages updated${NC}\n"
fi

# Update pnpm (if installed)
if command -v pnpm &>/dev/null; then
    echo -e "${BLUE}📦 Updating pnpm...${NC}"
    pnpm update -g
    echo -e "${GREEN}✓ pnpm updated${NC}\n"
fi

# Update pipx packages (if installed)
if command -v pipx &>/dev/null; then
    echo -e "${BLUE}📦 Updating pipx packages...${NC}"
    pipx upgrade-all
    echo -e "${GREEN}✓ pipx packages updated${NC}\n"
fi

# Update uv (if installed)
if command -v uv &>/dev/null; then
    echo -e "${BLUE}📦 Updating uv...${NC}"
    pipx upgrade uv
    echo -e "${GREEN}✓ uv updated${NC}\n"
fi

# Update Rust packages (if installed)
if command -v rustup &>/dev/null; then
    echo -e "${BLUE}📦 Updating Rust...${NC}"
    rustup update
    echo -e "${GREEN}✓ Rust updated${NC}\n"
fi

# Update Go (if installed via modules)
if command -v go &>/dev/null; then
    echo -e "${BLUE}📦 Updating Go modules...${NC}"
    go get -u all 2>/dev/null || echo -e "${YELLOW}⚠️  No Go modules to update${NC}"
    echo -e "${GREEN}✓ Go modules updated${NC}\n"
fi

# Update Docker images (optional - commented out by default)
# Uncomment if you want to update Docker images automatically
# if command -v docker &>/dev/null; then
#     echo -e "${BLUE}🐳 Updating Docker images...${NC}"
#     docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>" | xargs -L1 docker pull
#     echo -e "${GREEN}✓ Docker images updated${NC}\n"
# fi

# Update firmware (requires fwupd)
if command -v fwupdmgr &>/dev/null; then
    echo -e "${BLUE}🔧 Checking for firmware updates...${NC}"
    fwupdmgr refresh --force 2>/dev/null || true
    fwupdmgr get-updates 2>/dev/null || echo -e "${GREEN}✓ No firmware updates available${NC}"
    echo ""
fi

# Clean up package caches
echo -e "${BLUE}🧹 Cleaning up...${NC}"
sudo apt autoremove -y
sudo apt autoclean
if command -v snap &>/dev/null; then
    # Remove old snap revisions
    LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
    done
fi
echo -e "${GREEN}✓ Cleanup complete${NC}\n"

# Display system info
echo -e "${MAGENTA}📊 System Information:${NC}"
echo -e "Kernel: $(uname -r)"
echo -e "Uptime: $(uptime -p)"
if command -v apt &>/dev/null; then
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0")
    echo -e "Pending APT updates: $UPDATES"
fi

echo -e "\n${GREEN}✅ System update complete!${NC}"
echo -e "${YELLOW}💡 Tip: Reboot your system if kernel was updated${NC}"

echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
