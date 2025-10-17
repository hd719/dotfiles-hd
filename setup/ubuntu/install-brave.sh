#!/usr/bin/env bash

# Install Brave Browser on Ubuntu
# Brave often has better performance in VMs compared to Firefox

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}\n"
echo -e "${YELLOW}🦁 Installing Brave Browser...${NC}\n"

# Check if Brave is already installed
if command -v brave-browser &>/dev/null; then
    echo -e "${GREEN}✓ Brave Browser is already installed${NC}"
    brave-browser --version
    exit 0
fi

# Install prerequisites
echo -e "${YELLOW}📦 Installing prerequisites...${NC}"
sudo apt install -y curl

# Add Brave GPG key
echo -e "${YELLOW}🔑 Adding Brave GPG key...${NC}"
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

# Add Brave repository
echo -e "${YELLOW}📋 Adding Brave repository...${NC}"
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

# Update package lists
echo -e "${YELLOW}🔄 Updating package lists...${NC}"
sudo apt update

# Install Brave Browser
echo -e "${YELLOW}⬇️  Installing Brave Browser...${NC}"
sudo apt install -y brave-browser

# Verify installation
if command -v brave-browser &>/dev/null; then
    echo -e "\n${GREEN}✅ Brave Browser installed successfully!${NC}"
    echo -e "${GREEN}Version: $(brave-browser --version)${NC}"
    echo -e "\n${YELLOW}💡 Tips for better video performance:${NC}"
    echo -e "  • Lower video quality to 720p or 480p"
    echo -e "  • Close other applications when watching videos"
    echo -e "  • Brave often performs better than Firefox in VMs"
    echo -e "\n${YELLOW}🚀 Launch Brave from:${NC}"
    echo -e "  • Application menu, or"
    echo -e "  • Terminal: brave-browser"
else
    echo -e "\n${RED}❌ Installation failed${NC}"
    exit 1
fi

echo -e "\n${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
