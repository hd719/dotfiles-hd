#!/usr/bin/env zsh

# update-fedora42.sh
# Daily update script for Fedora 42 dev environment
# - Uses dnf for all CLI tools and system packages
# - Uses Homebrew only for rbenv, ruby-build, and their dependencies
# - No more dnf/brew mix for individual tools
# - Simple, predictable, and well-commented

set -e

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

TOTAL_STEPS=7
CURRENT_STEP=0
step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "${YELLOW}[Update Step ${CURRENT_STEP}/${TOTAL_STEPS}] $1${NC}"
}

update_system_packages() {
    step "Updating system packages and CLI tools (dnf)"
    # This will update all system and CLI tools: starship, zoxide, bat, btop, etc.
    sudo dnf upgrade --refresh -y
    echo -e "${GREEN}✓ System packages and CLI tools updated via dnf${NC}"
}

update_homebrew() {
    step "Updating Homebrew (for rbenv, ruby-build, and dependencies only)"
    if command -v brew &>/dev/null; then
        brew update
        # Try brew upgrade and capture output, but don't exit on error
        set +e
        UPGRADE_OUTPUT=$(brew upgrade 2>&1)
        BREW_EXIT=$?
        set -e
        echo "$UPGRADE_OUTPUT"
        if echo "$UPGRADE_OUTPUT" | grep -q 'Cellar/openssl@3/.*/is not a directory'; then
            echo -e "${YELLOW}⚠️ Detected missing openssl@3 directory. Attempting to fix...${NC}"
            brew cleanup
            brew uninstall --ignore-dependencies openssl@3 || true
            brew install openssl@3
            echo -e "${YELLOW}Retrying brew upgrade...${NC}"
            brew upgrade || true
        fi
        if [ $BREW_EXIT -ne 0 ]; then
            echo -e "${YELLOW}⚠️ brew upgrade exited with code $BREW_EXIT, but continuing...${NC}"
        fi
        echo -e "${GREEN}✓ Homebrew packages updated ${NC}"
    else
        echo -e "${YELLOW}⚠️ Homebrew not installed. Skipping.${NC}"
    fi
}

update_pipx() {
    step "Updating pipx and all pipx packages (if installed)"
    if command -v pipx &>/dev/null; then
        pipx upgrade-all
        echo -e "${GREEN}✓ pipx packages updated${NC}"
    else
        echo -e "${YELLOW}⚠️ pipx not installed. Skipping.${NC}"
    fi
}

update_node_npm_global() {
    step "Updating Node.js (nvm) and global npm/pnpm packages (if installed)"
    if [ -d "$HOME/.nvm" ]; then
        export NVM_DIR="$HOME/.nvm"
        source "$NVM_DIR/nvm.sh"
        nvm install --lts --latest-npm
        nvm use --lts
        if command -v npm &>/dev/null; then
            npm update -g || echo -e "${YELLOW}⚠️ npm global update failed${NC}"
        fi
        if command -v pnpm &>/dev/null; then
            pnpm self-update
        fi
        echo -e "${GREEN}✓ Node.js and global npm/pnpm packages updated${NC}"
    else
        echo -e "${YELLOW}⚠️ nvm not installed. Skipping Node.js update.${NC}"
    fi
}

update_ruby_gems() {
    step "Updating global Ruby gems (if Ruby installed)"
    if command -v gem &>/dev/null; then
        gem update --system
        gem update
        echo -e "${GREEN}✓ Ruby gems updated${NC}"
    else
        echo -e "${YELLOW}⚠️ Ruby not installed. Skipping Ruby gems update.${NC}"
    fi
}

update_anycable_go() {
    step "Updating anycable-go binary (if present)"
    TOOL_DIR="$HOME/Developer/tools/anycable"
    if [ -d "$TOOL_DIR" ]; then
        ARCH=$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')
        URL="https://github.com/anycable/anycable-go/releases/latest/download/anycable-go-linux-${ARCH}"
        curl -sL "$URL" -o "$TOOL_DIR/anycable-go.new"
        chmod +x "$TOOL_DIR/anycable-go.new"
        mv "$TOOL_DIR/anycable-go.new" "$TOOL_DIR/anycable-go"
        echo -e "${GREEN}✓ anycable-go updated${NC}"
    else
        echo -e "${YELLOW}⚠️ anycable-go directory not found. Skipping.${NC}"
    fi
}

update_vscode() {
    step "Updating Visual Studio Code (code) via dnf"
    if command -v code &>/dev/null; then
        sudo dnf upgrade -y code
        echo -e "${GREEN}✓ VS Code updated via dnf${NC}"
    else
        echo -e "${YELLOW}⚠️ VS Code (code) not installed. Skipping.${NC}"
    fi
}

clean_up_old_packages() {
    step "Cleaning up old packages and cache (dnf)"
    sudo dnf autoremove -y
    sudo dnf clean all
    echo -e "${GREEN}✓ System cleaned up (autoremove, clean all)${NC}"
}

# Main execution

echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
echo -e "${GREEN}🚀 Starting Fedora 42 Dev Environment Daily Update...${NC}"

update_system_packages
update_vscode
update_homebrew
update_pipx
update_node_npm_global
update_ruby_gems
update_anycable_go

clean_up_old_packages


echo -e "\n${GREEN}🎉 Update complete! Restart your shell if needed.${NC}"
echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}" 