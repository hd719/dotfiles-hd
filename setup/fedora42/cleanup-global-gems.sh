#!/usr/bin/env zsh

# cleanup-global-gems.sh
# Safe cleanup script for global Ruby gems
# - Shows what gems will be removed before doing anything
# - Keeps essential gems (bundler, rake, etc.)
# - Provides safety checks and warnings
# - Should be run ONCE, not regularly

set -e

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

# Essential gems to keep (these are needed for basic Ruby development)
ESSENTIAL_GEMS=(
    "bundler"
    "rake"
    "rdoc"
    "irb"
    "json"
    "minitest"
    "test-unit"
    "rubygems-update"
)

echo -e "${MAGENTA}🧹 Global Ruby Gems Cleanup Script${NC}"
echo -e "${YELLOW}⚠️  WARNING: This script will remove global gems!${NC}"
echo -e "${YELLOW}⚠️  Only run this ONCE after switching to project-specific gem management${NC}"
echo ""

# Check if Ruby is installed
if ! command -v gem &>/dev/null; then
    echo -e "${RED}❌ Ruby/gem not found. Exiting.${NC}"
    exit 1
fi

# Show current gem count
TOTAL_GEMS=$(gem list | wc -l)
echo -e "${BLUE}📊 Current global gems: $TOTAL_GEMS${NC}"

# Show what gems would be removed
echo -e "\n${YELLOW}🔍 Analyzing gems to remove...${NC}"

# Get list of all gems (excluding default gems)
ALL_GEMS=$(gem list | grep -v "default" | awk '{print $1}' | sort)

# Filter out essential gems
GEMS_TO_REMOVE=""
for gem in $ALL_GEMS; do
    if [[ ! " ${ESSENTIAL_GEMS[@]} " =~ " ${gem} " ]]; then
        GEMS_TO_REMOVE="$GEMS_TO_REMOVE $gem"
    fi
done

# Count gems to remove
REMOVE_COUNT=$(echo $GEMS_TO_REMOVE | wc -w)

echo -e "${RED}🗑️  Gems that would be removed ($REMOVE_COUNT):${NC}"
echo "$GEMS_TO_REMOVE" | tr ' ' '\n' | head -20
if [ $REMOVE_COUNT -gt 20 ]; then
    echo -e "${YELLOW}... and $((REMOVE_COUNT - 20)) more${NC}"
fi

echo -e "\n${GREEN}✅ Gems that would be kept:${NC}"
for gem in "${ESSENTIAL_GEMS[@]}"; do
    if gem list | grep -q "^$gem "; then
        echo "  ✅ $gem"
    fi
done

echo ""
echo -e "${YELLOW}⚠️  SAFETY CHECKS:${NC}"
echo "1. Make sure you're using Bundler in your projects"
echo "2. Ensure your projects have Gemfiles"
echo "3. Test your projects after cleanup"

echo ""
echo -n "Do you want to proceed with the cleanup? (y/N): "
read -r REPLY

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Cleanup cancelled.${NC}"
    exit 0
fi

# Final confirmation
echo -e "${RED}⚠️  FINAL WARNING: This will remove $REMOVE_COUNT gems!${NC}"
echo -n "Are you absolutely sure? Type 'YES' to continue: "
read -r REPLY

if [[ $REPLY != "YES" ]]; then
    echo -e "${YELLOW}❌ Cleanup cancelled.${NC}"
    exit 0
fi

# Perform the cleanup
echo -e "\n${GREEN}🧹 Starting cleanup...${NC}"

for gem in $GEMS_TO_REMOVE; do
    echo -e "${BLUE}Removing $gem...${NC}"
    gem uninstall -aIx "$gem" 2>/dev/null || echo -e "${YELLOW}⚠️  Could not remove $gem${NC}"
done

# Show final count
FINAL_GEMS=$(gem list | wc -l)
echo ""
echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo -e "${BLUE}📊 Gems before: $TOTAL_GEMS, after: $FINAL_GEMS${NC}"
echo -e "${GREEN}🎉 Removed $((TOTAL_GEMS - FINAL_GEMS)) gems${NC}"

echo ""
echo -e "${MAGENTA}💡 Next steps:${NC}"
echo "1. Use 'bundle install' in your Ruby projects"
echo "2. Add gems to Gemfile instead of installing globally"
echo "3. Run 'bundle update' when you need to update gems"
echo ""
echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}" 
