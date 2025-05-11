#!/usr/bin/env zsh

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check network connectivity
check_network() {
    echo -e "${YELLOW}🔍 Checking network connectivity...${NC}"
    if ! ping -c 1 github.com &> /dev/null; then
        echo -e "${RED}❌ No internet connection. Please check your network.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Network connection verified${NC}"
}

# Check directory permissions
check_permissions() {
    echo -e "${YELLOW}🔍 Checking directory permissions...${NC}"

    # Check home directory
    if [ ! -w "$HOME" ]; then
        echo -e "${RED}❌ No write permission in home directory${NC}"
        exit 1
    fi

    # Check Developer directory
    if [ -d "$HOME/Developer" ] && [ ! -w "$HOME/Developer" ]; then
        echo -e "${RED}❌ No write permission in Developer directory${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Directory permissions verified${NC}"
}

# Check system requirements
check_system_requirements() {
    echo -e "${YELLOW}🔍 Checking system requirements...${NC}"

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}❌ Please do not run this script as root${NC}"
        exit 1
    fi

    # Check macOS version
    MACOS_VERSION=$(sw_vers -productVersion)
    if [[ $(echo "$MACOS_VERSION" | cut -d. -f1) -lt 12 ]]; then
        echo -e "${RED}❌ This script requires macOS 12 or later${NC}"
        exit 1
    fi

    # Check available disk space (need at least 10GB)
    AVAILABLE_SPACE=$(df -g / | awk 'NR==2 {print $4}')
    if [ "$AVAILABLE_SPACE" -lt 10 ]; then
        echo -e "${RED}❌ Insufficient disk space. Please ensure at least 10GB is available${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ System requirements met${NC}"
}

# Progress tracking
TOTAL_STEPS=9
CURRENT_STEP=0
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "${YELLOW}[Step $CURRENT_STEP/$TOTAL_STEPS] $1${NC}"
}

# Default values
SKIP_XCODE=false
SKIP_SSH=false
SKIP_NIX=false
SKIP_DOTFILES=false
SKIP_RELOAD=false
SKIP_SWITCH=false
SKIP_KEYCHAIN=false
SKIP_VERSIONS=false

# Function to show help
show_help() {
    echo "Usage: $0 <github_username> <github_pat> [options]"
    echo ""
    echo "Options:"
    echo "  --new-key          Force creation of a new SSH key"
    echo "  --skip=<step>      Skip specific step(s)"
    echo "                     Available steps: xcode, ssh, nix, dotfiles, reload, switch, keychain, versions"
    echo "                     Example: --skip=xcode,ssh"
    echo "  --resume=<step>    Resume from a specific step"
    echo "                     Available steps: xcode, ssh, nix, dotfiles, reload, switch, keychain"
    echo ""
    echo "Example:"
    echo "  $0 username pat --new-key --skip=xcode,dotfiles"
    exit 0
}

# Parse skip arguments
parse_skip_args() {
    for arg in "$@"; do
        if [[ $arg == --skip=* ]]; then
            IFS=',' read -ra SKIPS <<< "${arg#*=}"
            for skip in "${SKIPS[@]}"; do
                case $skip in
                    xcode) SKIP_XCODE=true ;;
                    ssh) SKIP_SSH=true ;;
                    nix) SKIP_NIX=true ;;
                    dotfiles) SKIP_DOTFILES=true ;;
                    reload) SKIP_RELOAD=true ;;
                    switch) SKIP_SWITCH=true ;;
                    keychain) SKIP_KEYCHAIN=true ;;
                    versions) SKIP_VERSIONS=true ;;
                    *) echo -e "${RED}❌ Unknown skip option: $skip${NC}"; show_help ;;
                esac
            done
        elif [[ $arg == --help ]] || [[ $arg == -h ]]; then
            show_help
        fi
    done
}

# Install Xcode Command Line Tools
install_xcode() {
    if [ "$SKIP_XCODE" = true ]; then
        echo -e "${YELLOW}⚠️ Skipping Xcode installation${NC}"
        return
    fi

    echo -e "${YELLOW}🛠️ Checking Xcode Command Line Tools installation...${NC}"
    if ! xcode-select -p &> /dev/null; then
        echo -e "${YELLOW}Xcode Command Line Tools not found. Installing...${NC}"
        xcode-select --install
        echo -e "${YELLOW}⚠️ Please complete the Xcode Command Line Tools installation in the popup window${NC}"
        # Wait for Xcode installation to complete
        while ! xcode-select -p &> /dev/null; do
            echo -e "${YELLOW}Waiting for Xcode Command Line Tools installation to complete...${NC}"
            sleep 10
        done
        echo -e "${GREEN}✓ Xcode Command Line Tools installed successfully${NC}"
    else
        echo -e "${GREEN}✓ Xcode Command Line Tools are already installed at: $(xcode-select -p)${NC}"
    fi
}

# Setup SSH and GitHub
setup_ssh() {
    if [ "$SKIP_SSH" = true ]; then
        echo -e "${YELLOW}⚠️ Skipping SSH setup${NC}"
        return
    fi

    local force_new_key=$1
    local github_username=$2
    local github_pat=$3

    echo -e "${YELLOW}🔑 Setting up SSH and GitHub...${NC}"

    # Create .ssh directory if it doesn't exist
    if [ ! -d ~/.ssh ]; then
        echo -e "${YELLOW}Creating .ssh directory...${NC}"
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to create .ssh directory${NC}"
            exit 1
        fi
    fi

    # Create SSH key if it doesn't exist or if force_new_key is true
    if [ "$force_new_key" = true ] || [ ! -f ~/.ssh/id_ed25519 ]; then
        echo -e "${YELLOW}Generating new SSH key...${NC}"
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "${github_username}@github"
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to generate SSH key${NC}"
            exit 1
        fi
        chmod 600 ~/.ssh/id_ed25519
        chmod 644 ~/.ssh/id_ed25519.pub
        echo -e "${GREEN}✓ SSH key generated successfully${NC}"

        # Add SSH key to GitHub
        echo -e "${YELLOW}Adding SSH key to GitHub...${NC}"
        if [ ! -f ~/.ssh/id_ed25519.pub ]; then
            echo -e "${RED}❌ SSH public key not found${NC}"
            exit 1
        fi
        PUBLIC_KEY=$(cat ~/.ssh/id_ed25519.pub)
        TITLE="VM-Setup-$(date +%Y%m%d%H%M%S)"

        # Create the SSH key on GitHub
        echo -e "${YELLOW}Uploading key to GitHub...${NC}"
        RESPONSE=$(curl -s -X POST \
            -H "Authorization: token ${github_pat}" \
            -H "Accept: application/vnd.github.v3+json" \
            https://api.github.com/user/keys \
            -d "{\"title\":\"${TITLE}\",\"key\":\"${PUBLIC_KEY}\"}")

        # Check if the key was added successfully
        if echo "$RESPONSE" | grep -q "id"; then
            echo -e "${GREEN}✓ SSH key added to GitHub successfully${NC}"
            # Start SSH agent
            echo -e "${YELLOW}Starting SSH agent...${NC}"
            eval "$(ssh-agent -s)"
            if [ $? -ne 0 ]; then
                echo -e "${RED}❌ Failed to start SSH agent${NC}"
                exit 1
            fi
            echo -e "${GREEN}✓ SSH agent started${NC}"

            # Create or update SSH config
            echo -e "${YELLOW}Configuring SSH config...${NC}"
            if [ ! -f ~/.ssh/config ]; then
                touch ~/.ssh/config
                chmod 600 ~/.ssh/config
            fi

            # Get hostname
            local hostname=$(hostname)
            if [ -z "$hostname" ]; then
                echo -e "${RED}❌ Failed to get hostname${NC}"
                exit 1
            fi

            # Check if config already exists for this host
            if ! grep -q "Host $hostname" ~/.ssh/config; then
                cat >> ~/.ssh/config << EOF

Host $hostname
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
EOF
                if [ $? -ne 0 ]; then
                    echo -e "${RED}❌ Failed to update SSH config${NC}"
                    exit 1
                fi
                echo -e "${GREEN}✓ SSH config updated successfully${NC}"
            else
                echo -e "${GREEN}✓ SSH config already exists for $hostname${NC}"
            fi
        else
            echo -e "${RED}❌ Failed to add SSH key to GitHub${NC}"
            echo -e "${YELLOW}Response:${NC}"
            echo "$RESPONSE"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ SSH key already exists, skipping creation${NC}"
    fi
}

# Install Nix Determinate
install_nix() {
    if [ "$SKIP_NIX" = true ]; then
        echo -e "${YELLOW}⚠️ Skipping Nix installation${NC}"
        return
    fi

    echo -e "${YELLOW}📦 Checking Nix installation...${NC}"
    if nix --version &> /dev/null; then
        echo -e "${GREEN}✓ Nix is already installed${NC}"
    else
        echo -e "${YELLOW}Installing Nix Determinate...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to install Nix${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Nix installed successfully${NC}"

        # Source Nix environment variables
        echo -e "${YELLOW}Sourcing Nix environment variables...${NC}"
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to source Nix environment variables${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Nix environment variables sourced${NC}"
    fi

    # Verify installation and show version
    NIX_VERSION=$(nix --version)
    echo -e "${GREEN}✓ Nix version: ${NIX_VERSION}${NC}"

    # Run nix doctor to verify installation
    echo -e "${YELLOW}Running Nix doctor to verify installation...${NC}"
    nix doctor
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Nix installation verified successfully${NC}"
    else
        echo -e "${YELLOW}⚠️ Nix doctor reported some issues. Please review the output above.${NC}"
    fi
}

# Add GitHub to known hosts
configure_known_hosts() {
    echo -e "${YELLOW}🔑 Configuring SSH known hosts...${NC}"
    if [ ! -f ~/.ssh/known_hosts ] || ! grep -q "github.com" ~/.ssh/known_hosts; then
        mkdir -p ~/.ssh
        ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Added GitHub to known hosts${NC}"
        else
            echo -e "${YELLOW}⚠️ Failed to add GitHub to known hosts${NC}"
        fi
    else
        echo -e "${GREEN}✓ GitHub already in known hosts${NC}"
    fi
}

# Clone dotfiles
clone_dotfiles() {
    if [ "$SKIP_DOTFILES" = true ]; then
        echo -e "${YELLOW}⚠️ Skipping dotfiles clone${NC}"
        return
    fi

    local github_username=$1
    echo -e "${YELLOW}📂 Setting up dotfiles...${NC}"

    # Configure known hosts before git operations
    configure_known_hosts

    # Create Developer directory if it doesn't exist
    if [ ! -d ~/Developer ]; then
        echo -e "${YELLOW}Creating Developer directory...${NC}"
        mkdir -p ~/Developer
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to create Developer directory${NC}"
            exit 1
        fi
    fi

    # Handle dotfiles repository
    if [ ! -d ~/Developer/dotfiles-hd ]; then
        echo -e "${YELLOW}Cloning dotfiles repository...${NC}"
        # Use HTTPS instead of SSH for initial clone
        git clone https://github.com/${github_username}/dotfiles-hd.git ~/Developer/dotfiles-hd
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to clone dotfiles${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Dotfiles cloned successfully${NC}"

        # After successful clone, update remote to use SSH
        cd ~/Developer/dotfiles-hd || exit 1
        git remote set-url origin git@github.com:${github_username}/dotfiles-hd.git
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}⚠️ Warning: Failed to update remote URL to SSH${NC}"
        fi
    else
        echo -e "${YELLOW}Updating existing dotfiles repository...${NC}"
        cd ~/Developer/dotfiles-hd || exit 1

        # Get the default branch name
        DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
        if [ -z "$DEFAULT_BRANCH" ]; then
            DEFAULT_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
        fi

        if [ -z "$DEFAULT_BRANCH" ]; then
            echo -e "${RED}❌ Could not determine default branch${NC}"
            exit 1
        fi

        git pull origin "$DEFAULT_BRANCH"
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to update dotfiles${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Dotfiles updated successfully${NC}"
    fi

    # Handle zsh-you-should-use plugin
    if [ ! -d ~/Developer/zsh-you-should-use ]; then
        echo -e "${YELLOW}📂 Cloning zsh-you-should-use plugin...${NC}"
        git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ~/Developer/zsh-you-should-use
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to clone zsh-you-should-use plugin${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ zsh-you-should-use plugin cloned successfully${NC}"
    else
        echo -e "${YELLOW}Updating zsh-you-should-use plugin...${NC}"
        cd ~/Developer/zsh-you-should-use || exit 1
        git pull origin master
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to update zsh-you-should-use plugin${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ zsh-you-should-use plugin updated successfully${NC}"
    fi
}

# Install specific Node.js and Ruby versions
install_versions() {
    if [ "$SKIP_VERSIONS" = true ]; then
        echo -e "${YELLOW}⚠️ Skipping version installations${NC}"
        return
    fi

    update_progress "Installing specific Node.js and Ruby versions"

    # Install Node.js versions
    echo -e "${YELLOW}📦 Installing Node.js versions...${NC}"

    # Install nvm
    echo -e "${YELLOW}Installing nvm...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install Node.js versions
    echo -e "${YELLOW}Installing Node.js LTS...${NC}"
    nvm install --lts
    echo -e "${YELLOW}Installing Node.js 18.7.1...${NC}"
    nvm install node 18.7.1
    echo -e "${YELLOW}Installing Node.js 16.5.0...${NC}"
    nvm install node 16.5.0

    # Set default Node.js version (lts is the default)
    nvm use default
    nvm use global default
    echo -e "${GREEN}✓ Node.js versions installed successfully${NC}"

    # Install Ruby version
    echo -e "${YELLOW}📦 Installing Ruby version...${NC}"

    # Initialize rbenv (already installed through Nix)
    eval "$(rbenv init -)"

    # Function to check if Ruby version exists
    ruby_version_exists() {
        rbenv versions | grep -q "$1"
    }

    # Install Ruby 3.1.3 if it doesn't exist
    if ! ruby_version_exists "3.1.3"; then
        echo -e "${YELLOW}Installing Ruby 3.1.3...${NC}"
        rbenv install 3.1.3
    else
        echo -e "${GREEN}✓ Ruby 3.1.3 is already installed${NC}"
    fi

    # Get latest stable version (e.g., 3.x, filters out preview/dev)
    LATEST_RUBY_VERSION=$(rbenv install -l | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d '[:space:]')

    # Install latest Ruby version if it doesn't exist
    if ! ruby_version_exists "$LATEST_RUBY_VERSION"; then
        echo -e "${YELLOW}Installing Ruby ${LATEST_RUBY_VERSION}...${NC}"
        rbenv install -s "$LATEST_RUBY_VERSION"
    else
        echo -e "${GREEN}✓ Ruby ${LATEST_RUBY_VERSION} is already installed${NC}"
    fi

    echo -e "${YELLOW}Setting Ruby ${LATEST_RUBY_VERSION} as global...${NC}"
    rbenv global "$LATEST_RUBY_VERSION"

    # Ensure shims are updated
    rbenv rehash

    # Install bundler if not already installed
    if ! gem list bundler -i &>/dev/null; then
        echo -e "${YELLOW}Installing bundler...${NC}"
        gem install bundler
    else
        echo -e "${GREEN}✓ Bundler is already installed${NC}"
    fi

    echo -e "${GREEN}✓ Ruby version setup completed successfully${NC}"
}

setup_tmux() {
    echo -e "${YELLOW}🎭 Setting up tmux configuration...${NC}"

    # Create .config directory if it doesn't exist
    mkdir -p ~/.config

    # Copy tmux configuration
    cp -r /Users/hameldesai/Developer/dotfiles-hd/config/tmux ~/.config/

    # Create plugins directory
    mkdir -p ~/.config/tmux/plugins

    # Clone catppuccin theme
    echo -e "${YELLOW}Cloning catppuccin theme...${NC}"
    git clone git@github.com:hd719/hd-tmux.git ~/.config/tmux/plugins/catppuccin/hd-tmux

    # Clone tpm
    echo -e "${YELLOW}Cloning tpm...${NC}"
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

    echo -e "${GREEN}✓ Tmux setup complete!${NC}"
    echo -e "${YELLOW}To install plugins, start tmux and press Escape + Shift + i${NC}"
}

# Main execution
if [ $# -lt 2 ]; then
    show_help
fi

# Parse arguments
GITHUB_USERNAME=$1
GITHUB_PAT=$2
FORCE_NEW_KEY=false

# Shift to get to optional arguments
shift 2

# Parse skip arguments
parse_skip_args "$@"

# Check for --new-key
for arg in "$@"; do
    if [ "$arg" = "--new-key" ]; then
        FORCE_NEW_KEY=true
    fi
done

echo -e "🙏 Om Shree Ganeshaya Namaha 🙏"
echo -e "${GREEN}🚀 Starting setup process...${NC}"

# Run all checks
check_network
check_permissions
check_system_requirements

# 1. Install Xcode Command Line Tools
update_progress "Installing Xcode Command Line Tools"
install_xcode

# 2. Setup SSH and GitHub
update_progress "Setting up SSH and GitHub"
setup_ssh "$FORCE_NEW_KEY" "$GITHUB_USERNAME" "$GITHUB_PAT"

# 3. Install Nix
update_progress "Installing Nix"
install_nix

# 4. Clone dotfiles
update_progress "Cloning dotfiles"
clone_dotfiles "$GITHUB_USERNAME"

# 5. Reload shell
update_progress "Reloading shell"
if [ "$SKIP_RELOAD" = true ]; then
    echo -e "${YELLOW}⚠️ Skipping shell reload${NC}"
else
    echo -e "${YELLOW}🔄 Reloading shell...${NC}"
    # Switch to Zsh and source .zshrc
    echo -e "${YELLOW}Switching to Zsh...${NC}"
    source ~/Developer/dotfiles-hd/setup/.zshrc 2>/dev/null || true

    # Wait for shell reload to complete with timeout
    echo -e "${YELLOW}Waiting for shell reload to complete...${NC}"
    TIMEOUT=15  # 30 seconds timeout
    START_TIME=$(date +%s)

    while true; do
        if [ -n "$ZSH_VERSION" ]; then
            echo -e "${GREEN}✓ Successfully reloaded into Zsh (version: $ZSH_VERSION)${NC}"
            break
        fi

        CURRENT_TIME=$(date +%s)
        ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

        if [ $ELAPSED_TIME -ge $TIMEOUT ]; then
            echo -e "${RED}❌ Shell reload timed out after ${TIMEOUT} seconds${NC}"
            echo -e "${YELLOW}Attempting to force Zsh...${NC}"
            exec /bin/zsh -l
            break
        fi

        echo -e "${YELLOW}Waiting for shell reload... (${ELAPSED_TIME}s)${NC}"
        sleep 2
    done

    # Verify dotfiles are loaded
    if [ -d "$HOME/Developer/dotfiles-hd" ] && [ -f "$HOME/Developer/dotfiles-hd/setup/.zshrc" ]; then
        echo -e "${GREEN}✓ Dotfiles directory and .zshrc found${NC}"
    else
        echo -e "${RED}❌ Dotfiles not properly loaded${NC}"
        exit 1
    fi
fi

# Add a small pause before proceeding to next step
echo -e "${YELLOW}Waiting before proceeding to next step...${NC}"
sleep 3

# 6. Run nix-darwin switch
update_progress "Running nix-darwin switch"
echo -e "${YELLOW}🔄 Running nix-darwin ${NC}"
if [ ! -d ~/Developer/dotfiles-hd/setup/mac-vm/darwin/nix ]; then
    echo -e "${RED}❌ Dotfiles directory not found. Please ensure dotfiles were cloned successfully.${NC}"
    exit 1
fi

# Check for flake.nix
if [ ! -f ~/Developer/dotfiles-hd/setup/mac-vm/darwin/nix/flake.nix ]; then
    echo -e "${RED}❌ flake.nix not found in nix directory${NC}"
    exit 1
fi

# Change to nix directory with error handling
if ! cd ~/Developer/dotfiles-hd/setup/mac-vm/darwin/nix; then
    echo -e "${RED}❌ Failed to change to nix directory${NC}"
    exit 1
fi

# Check if nix-darwin is available
if ! command -v nix &> /dev/null; then
    echo -e "${RED}❌ nix command not found. Please ensure Nix is installed correctly.${NC}"
    exit 1
fi

nix run nix-darwin -- switch --flake .#hameldesai
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to run nix-darwin switch${NC}"
    exit 1
fi
echo -e "${GREEN}✓ nix-darwin switch completed successfully${NC}"

# 7. Run darwin rebuild
update_progress "Running darwin rebuild"
if [ "$SKIP_SWITCH" = true ]; then
    echo -e "${YELLOW}⚠️ Skipping darwin rebuild${NC}"
else
    echo -e "${YELLOW}🔄 Running darwin rebuild...${NC}"
    if [ ! -d ~/Developer/dotfiles-hd/setup/mac-vm/darwin/nix ]; then
        echo -e "${RED}❌ Dotfiles directory not found. Please ensure dotfiles were cloned successfully.${NC}"
        exit 1
    fi

    # Change to nix directory with error handling
    if ! cd ~/Developer/dotfiles-hd/setup/mac-vm/darwin/nix; then
        echo -e "${RED}❌ Failed to change to nix directory${NC}"
        exit 1
    fi

    # Use nix-darwin command directly
    echo -e "${YELLOW}Running nix-darwin switch...${NC}"
    nix run nix-darwin -- switch --flake .#hameldesai
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to run nix-darwin switch${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ nix-darwin switch completed successfully${NC}"
fi

# 8. Add SSH key to keychain
update_progress "Adding SSH key to keychain"
if [ "$SKIP_KEYCHAIN" = true ]; then
    echo -e "${YELLOW}⚠️ Skipping SSH key addition to keychain${NC}"
elif [ "$SKIP_SSH" = false ]; then
    echo -e "${YELLOW}🔑 Adding SSH key to keychain...${NC}"
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        echo -e "${RED}❌ SSH key not found. Please ensure SSH setup completed successfully.${NC}"
        exit 1
    fi

    # Check if ssh-add is available
    if ! command -v ssh-add &> /dev/null; then
        echo -e "${RED}❌ ssh-add command not found${NC}"
        exit 1
    fi

    /usr/bin/ssh-add --apple-use-keychain ~/.ssh/id_ed25519
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to add SSH key to keychain${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ SSH key added to keychain${NC}"
fi

# 9. Install specific Node.js and Ruby versions
update_progress "Installing specific Node.js and Ruby versions"
install_versions

# 10. Setup tmux
update_progress "Setting up tmux"
setup_tmux

# Print summary
echo -e "\n${GREEN}✅ Environment setup complete!${NC}"
echo -e "${YELLOW}Summary of steps:${NC}"
echo "1. Xcode Command Line Tools: ${SKIP_XCODE:+Skipped}${SKIP_XCODE:-Completed}"
echo "2. SSH Setup: ${SKIP_SSH:+Skipped}${SKIP_SSH:-Completed}"
echo "3. Nix Installation: ${SKIP_NIX:+Skipped}${SKIP_NIX:-Completed}"
echo "4. Dotfiles Setup: ${SKIP_DOTFILES:+Skipped}${SKIP_DOTFILES:-Completed}"
echo "5. Shell Reload: ${SKIP_RELOAD:+Skipped}${SKIP_RELOAD:-Completed}"
echo "6. Nix-Darwin Switch: Completed"
echo "7. Darwin Rebuild: ${SKIP_SWITCH:+Skipped}${SKIP_SWITCH:-Completed}"
echo "8. Keychain Setup: ${SKIP_KEYCHAIN:+Skipped}${SKIP_KEYCHAIN:-Completed}"
echo "9. Node.js and Ruby Versions: ${SKIP_VERSIONS:+Skipped}${SKIP_VERSIONS:-Completed}"
echo "10. Tmux Setup: ${SKIP_TMUX:+Skipped}${SKIP_TMUX:-Completed}"
echo -e "🎉${GREEN}🎉 Setup completed successfully!${NC}"
echo -e "${MAGENTA}Please restart your shell to apply all changes.${NC}"
echo -e "🙏 Om Shree Ganeshaya Namaha 🙏"
