#!/usr/bin/env zsh

# uninstall-pycharm.sh
# Comprehensive PyCharm uninstaller for Fedora 42
# Handles multiple installation methods: Snap, Flatpak, JetBrains Toolbox, manual, and dnf
# Safe and thorough removal with user confirmation

set -e

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
echo -e "${BLUE}🗑️  PyCharm Uninstaller for Fedora 42${NC}"
echo -e "${YELLOW}This script will detect and remove PyCharm from all common installation methods.${NC}\n"

# Function to ask for user confirmation
confirm() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
    read -q "REPLY?Continue? (y/N): "
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Function to remove directory safely with confirmation
remove_directory() {
    local dir="$1"
    local description="$2"
    
    if [ -d "$dir" ]; then
        echo -e "${YELLOW}Found $description at: $dir${NC}"
        if confirm "Remove $description directory?"; then
            rm -rf "$dir"
            echo -e "${GREEN}✓ Removed $description${NC}"
        else
            echo -e "${YELLOW}⚠️ Skipped $description removal${NC}"
        fi
    fi
}

# Function to remove file safely with confirmation
remove_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo -e "${YELLOW}Found $description at: $file${NC}"
        if confirm "Remove $description?"; then
            rm -f "$file"
            echo -e "${GREEN}✓ Removed $description${NC}"
        else
            echo -e "${YELLOW}⚠️ Skipped $description removal${NC}"
        fi
    fi
}

echo -e "${BLUE}🔍 Detecting PyCharm installations...${NC}\n"

# 1. Check for Snap installation
if command_exists snap; then
    SNAP_PYCHARM=$(snap list | grep -i pycharm || true)
    if [ -n "$SNAP_PYCHARM" ]; then
        echo -e "${YELLOW}📦 Found PyCharm Snap package:${NC}"
        echo "$SNAP_PYCHARM"
        if confirm "Remove PyCharm Snap package?"; then
            sudo snap remove pycharm-community 2>/dev/null || true
            sudo snap remove pycharm-professional 2>/dev/null || true
            sudo snap remove pycharm-educational 2>/dev/null || true
            echo -e "${GREEN}✓ PyCharm Snap packages removed${NC}"
        fi
    else
        echo -e "${GREEN}✓ No PyCharm Snap packages found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Snap not installed, skipping Snap check${NC}"
fi

# 2. Check for Flatpak installation
if command_exists flatpak; then
    FLATPAK_PYCHARM=$(flatpak list | grep -i pycharm || true)
    if [ -n "$FLATPAK_PYCHARM" ]; then
        echo -e "${YELLOW}📦 Found PyCharm Flatpak package:${NC}"
        echo "$FLATPAK_PYCHARM"
        if confirm "Remove PyCharm Flatpak package?"; then
            flatpak uninstall com.jetbrains.PyCharm-Community 2>/dev/null || true
            flatpak uninstall com.jetbrains.PyCharm-Professional 2>/dev/null || true
            echo -e "${GREEN}✓ PyCharm Flatpak packages removed${NC}"
        fi
    else
        echo -e "${GREEN}✓ No PyCharm Flatpak packages found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Flatpak not installed, skipping Flatpak check${NC}"
fi

# 3. Check for dnf/rpm installation
if command_exists dnf; then
    DNF_PYCHARM=$(dnf list installed | grep -i pycharm || true)
    if [ -n "$DNF_PYCHARM" ]; then
        echo -e "${YELLOW}📦 Found PyCharm dnf/rpm package:${NC}"
        echo "$DNF_PYCHARM"
        if confirm "Remove PyCharm dnf/rpm package?"; then
            sudo dnf remove -y pycharm-community pycharm-professional 2>/dev/null || true
            echo -e "${GREEN}✓ PyCharm dnf/rpm packages removed${NC}"
        fi
    else
        echo -e "${GREEN}✓ No PyCharm dnf/rpm packages found${NC}"
    fi
fi

# 4. Check for JetBrains Toolbox installation
TOOLBOX_DIR="$HOME/.local/share/JetBrains/Toolbox"
if [ -d "$TOOLBOX_DIR" ]; then
    echo -e "${YELLOW}🧰 Found JetBrains Toolbox directory${NC}"
    # Look for PyCharm installations managed by Toolbox
    PYCHARM_TOOLBOX_DIRS=$(find "$TOOLBOX_DIR" -name "*pycharm*" -type d 2>/dev/null || true)
    if [ -n "$PYCHARM_TOOLBOX_DIRS" ]; then
        echo -e "${YELLOW}Found PyCharm installations via Toolbox:${NC}"
        echo "$PYCHARM_TOOLBOX_DIRS"
        if confirm "Remove PyCharm Toolbox installations?"; then
            echo "$PYCHARM_TOOLBOX_DIRS" | while read -r dir; do
                [ -n "$dir" ] && rm -rf "$dir"
            done
            echo -e "${GREEN}✓ PyCharm Toolbox installations removed${NC}"
        fi
    else
        echo -e "${GREEN}✓ No PyCharm Toolbox installations found${NC}"
    fi
fi

# 5. Check for manual installations in common locations
MANUAL_LOCATIONS=(
    "/opt/pycharm"
    "/opt/pycharm-community"
    "/opt/pycharm-professional"
    "/usr/local/pycharm"
    "$HOME/pycharm"
    "$HOME/.local/share/pycharm"
    "$HOME/Applications/PyCharm"
)

echo -e "\n${BLUE}🔍 Checking for manual PyCharm installations...${NC}"
for location in "${MANUAL_LOCATIONS[@]}"; do
    remove_directory "$location" "manual PyCharm installation"
done

# 6. Remove PyCharm configuration and cache directories
echo -e "\n${BLUE}🗂️  Checking for PyCharm configuration and cache directories...${NC}"

# PyCharm config directories (various versions)
CONFIG_DIRS=(
    "$HOME/.config/JetBrains/PyCharm*"
    "$HOME/.cache/JetBrains/PyCharm*"
    "$HOME/.local/share/JetBrains/PyCharm*"
    "$HOME/Library/Preferences/PyCharm*"  # macOS style, just in case
    "$HOME/Library/Caches/PyCharm*"       # macOS style, just in case
)

for pattern in "${CONFIG_DIRS[@]}"; do
    # Use glob expansion to find matching directories
    # Set null_glob option to handle no matches gracefully
    setopt null_glob
    for dir in $~pattern; do
        if [ -d "$dir" ]; then
            remove_directory "$dir" "PyCharm configuration/cache"
        fi
    done
    unsetopt null_glob
done

# 7. Remove desktop entries and menu shortcuts
echo -e "\n${BLUE}🖥️  Checking for PyCharm desktop entries...${NC}"

DESKTOP_ENTRIES=(
    "$HOME/.local/share/applications/pycharm.desktop"
    "$HOME/.local/share/applications/pycharm-community.desktop"
    "$HOME/.local/share/applications/pycharm-professional.desktop"
    "/usr/share/applications/pycharm.desktop"
    "/usr/share/applications/pycharm-community.desktop"
    "/usr/share/applications/pycharm-professional.desktop"
)

for entry in "${DESKTOP_ENTRIES[@]}"; do
    remove_file "$entry" "PyCharm desktop entry"
done

# 8. Remove any PyCharm symlinks from PATH
echo -e "\n${BLUE}🔗 Checking for PyCharm symlinks in PATH...${NC}"

PATH_LOCATIONS=(
    "/usr/local/bin/pycharm"
    "/usr/bin/pycharm"
    "$HOME/.local/bin/pycharm"
    "$HOME/bin/pycharm"
)

for link in "${PATH_LOCATIONS[@]}"; do
    if [ -L "$link" ] || [ -f "$link" ]; then
        remove_file "$link" "PyCharm executable/symlink"
    fi
done

# 9. Clean up any remaining PyCharm processes
echo -e "\n${BLUE}🔄 Checking for running PyCharm processes...${NC}"
# Look for actual PyCharm IDE processes, excluding this script
ACTUAL_PYCHARM=$(ps aux | grep -E "(pycharm\.sh|PyCharm|jetbrains.*pycharm)" | grep -v grep | grep -v "uninstall-pycharm.sh" || true)
if [ -n "$ACTUAL_PYCHARM" ]; then
    echo -e "${YELLOW}Found running PyCharm processes:${NC}"
    echo "$ACTUAL_PYCHARM"
    if confirm "Kill running PyCharm processes?"; then
        # Kill specific PyCharm IDE processes only
        pkill -f "pycharm\.sh" 2>/dev/null || true
        pkill -f "PyCharm" 2>/dev/null || true
        pkill -f "jetbrains.*pycharm" 2>/dev/null || true
        # Also try common PyCharm process names
        pkill -f "idea.*pycharm" 2>/dev/null || true
        echo -e "${GREEN}✓ PyCharm processes terminated${NC}"
    fi
else
    echo -e "${GREEN}✓ No running PyCharm processes found${NC}"
fi

# 10. Final cleanup and verification
echo -e "\n${BLUE}🧹 Final cleanup...${NC}"

# Update desktop database
if command_exists update-desktop-database; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    echo -e "${GREEN}✓ Desktop database updated${NC}"
fi

# Clear any cached icons
if [ -d "$HOME/.cache/thumbnails" ]; then
    find "$HOME/.cache/thumbnails" -name "*pycharm*" -delete 2>/dev/null || true
fi

echo -e "\n${GREEN}🎉 PyCharm uninstallation complete!${NC}"
echo -e "${YELLOW}💡 Summary of actions taken:${NC}"
echo -e "   • Checked and removed Snap packages"
echo -e "   • Checked and removed Flatpak packages" 
echo -e "   • Checked and removed dnf/rpm packages"
echo -e "   • Removed JetBrains Toolbox installations"
echo -e "   • Removed manual installations"
echo -e "   • Cleaned configuration and cache directories"
echo -e "   • Removed desktop entries and shortcuts"
echo -e "   • Removed executable symlinks"
echo -e "   • Terminated running processes"

echo -e "\n${BLUE}🔍 Verifying complete removal...${NC}"

# Function to run verification command and show result
verify_removal() {
    local description="$1"
    local command="$2"
    echo -e "${YELLOW}Checking: $description${NC}"
    echo -e "Running: ${MAGENTA}$command${NC}"
    
    local result
    result=$(eval "$command" 2>/dev/null || true)
    
    if [ -z "$result" ]; then
        echo -e "${GREEN}✓ CLEAN - No PyCharm found${NC}"
    else
        echo -e "${RED}⚠️ FOUND - PyCharm still present:${NC}"
        echo "$result"
    fi
    echo
}

# Run verification commands
verify_removal "PyCharm executable in PATH" "which pycharm"

if command_exists snap; then
    verify_removal "PyCharm Snap packages" "snap list | grep -i pycharm"
else
    echo -e "${YELLOW}Snap not available - skipping snap verification${NC}"
    echo
fi

if command_exists flatpak; then
    verify_removal "PyCharm Flatpak packages" "flatpak list | grep -i pycharm"
else
    echo -e "${YELLOW}Flatpak not available - skipping flatpak verification${NC}"
    echo
fi

verify_removal "PyCharm DNF/RPM packages" "dnf list installed | grep -i pycharm"

# Additional verification checks
verify_removal "PyCharm processes" "pgrep -f 'pycharm\.sh|PyCharm|jetbrains.*pycharm' | head -5"
verify_removal "PyCharm desktop entries" "find ~/.local/share/applications /usr/share/applications -name '*pycharm*' 2>/dev/null"
verify_removal "PyCharm config directories" "find ~/.config ~/.cache ~/.local/share -maxdepth 2 -name '*PyCharm*' -type d 2>/dev/null"

echo -e "${GREEN}🎯 Verification complete!${NC}"

echo -e "\n${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
