#!/usr/bin/env bash

# Install and set latest stable Ruby (LTS) as default via rbenv

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}\n"
echo -e "${YELLOW}💎 Installing Ruby LTS...${NC}\n"

# Check if rbenv is installed
if ! command -v rbenv &>/dev/null; then
    echo -e "${RED}❌ rbenv is not installed${NC}"
    echo -e "${YELLOW}Please install rbenv first by running the setup script${NC}"
    exit 1
fi

# Make sure rbenv is initialized
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"

# Check if ruby-build is installed
if [ ! -d "$HOME/.rbenv/plugins/ruby-build" ]; then
    echo -e "${YELLOW}📦 Installing ruby-build plugin...${NC}"
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo -e "${GREEN}✓ ruby-build installed${NC}\n"
fi

# Get the latest stable Ruby version (3.x series)
echo -e "${YELLOW}🔍 Finding latest stable Ruby version...${NC}"
LATEST_RUBY=$(rbenv install -l | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')

if [ -z "$LATEST_RUBY" ]; then
    echo -e "${RED}❌ Could not determine latest Ruby version${NC}"
    exit 1
fi

echo -e "${GREEN}Latest stable Ruby: ${LATEST_RUBY}${NC}\n"

# Check if this version is already installed
if rbenv versions | grep -q "$LATEST_RUBY"; then
    echo -e "${GREEN}✓ Ruby ${LATEST_RUBY} is already installed${NC}"
else
    # Install Ruby
    echo -e "${YELLOW}📦 Installing Ruby ${LATEST_RUBY}...${NC}"
    echo -e "${YELLOW}⚠️  This may take several minutes...${NC}\n"
    
    rbenv install "$LATEST_RUBY"
    
    echo -e "\n${GREEN}✓ Ruby ${LATEST_RUBY} installed successfully${NC}"
fi

# Set as global default
echo -e "${YELLOW}🌍 Setting Ruby ${LATEST_RUBY} as global default...${NC}"
rbenv global "$LATEST_RUBY"

# Rehash to update shims
rbenv rehash

# Verify installation
echo -e "\n${GREEN}✅ Ruby setup complete!${NC}"
echo -e "${GREEN}Active Ruby version:${NC}"
ruby --version

echo -e "\n${YELLOW}💡 Useful rbenv commands:${NC}"
echo -e "  rbenv versions          # List installed Ruby versions"
echo -e "  rbenv install -l        # List available Ruby versions"
echo -e "  rbenv global <version>  # Set global Ruby version"
echo -e "  rbenv local <version>   # Set Ruby version for current directory"
echo -e "  gem install bundler     # Install bundler gem"

echo -e "\n${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
