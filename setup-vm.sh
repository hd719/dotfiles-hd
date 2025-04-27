#!/usr/bin/env zsh

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
SKIP_XCODE=false
SKIP_SSH=false
SKIP_NIX=false
SKIP_DOTFILES=false
SKIP_RELOAD=false
SKIP_SWITCH=false
SKIP_KEYCHAIN=false

# Function to show help
show_help() {
    echo "Usage: $0 <github_username> <github_pat> [options]"
    echo ""
    echo "Options:"
    echo "  --new-key          Force creation of a new SSH key"
    echo "  --skip=<step>      Skip specific step(s)"
    echo "                     Available steps: xcode, ssh, nix, dotfiles, reload, switch, keychain"
    echo "                     Example: --skip=xcode,ssh"
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
    if ! command -v nix &> /dev/null; then
        echo -e "${YELLOW}Installing Nix Determinate...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to install Nix${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Nix installed successfully${NC}"
    else
        echo -e "${GREEN}✓ Nix is already installed${NC}"
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
        git clone git@github.com:${github_username}/dotfiles-hd.git ~/Developer/dotfiles-hd
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to clone dotfiles${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Dotfiles cloned successfully${NC}"
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

echo -e "${GREEN}🚀 Starting setup process...${NC}"

# 1. Install Xcode Command Line Tools
install_xcode

# 2. Setup SSH and GitHub
setup_ssh "$FORCE_NEW_KEY" "$GITHUB_USERNAME" "$GITHUB_PAT"

# 3. Install Nix
install_nix

# 4. Clone dotfiles
clone_dotfiles "$GITHUB_USERNAME"

# 5. Reload shell
if [ "$SKIP_RELOAD" = true ]; then
    echo -e "${YELLOW}⚠️ Skipping shell reload${NC}"
else
    echo -e "${YELLOW}🔄 Reloading shell...${NC}"
    # Switch to Zsh and source .zshrc
    echo -e "${YELLOW}Switching to Zsh...${NC}"
    source ~/Developer/dotfiles-hd/setup/.zshrc 2>/dev/null || true
    echo -e "${GREEN}✓ Shell reloaded${NC}"
fi

# 6. Run darwin rebuild
if [ "$SKIP_SWITCH" = true ]; then
    echo -e "${YELLOW}⚠️ Skipping darwin rebuild${NC}"
else
    echo -e "${YELLOW}🔄 Running darwin rebuild...${NC}"
    if [ ! -d ~/Developer/dotfiles-hd/setup/mac/darwin/nix ]; then
        echo -e "${RED}❌ Dotfiles directory not found. Please ensure dotfiles were cloned successfully.${NC}"
        exit 1
    fi
    cd ~/Developer/dotfiles-hd/setup/mac/darwin/nix || exit 1
    if ! command -v switch &> /dev/null; then
        echo -e "${RED}❌ 'switch' command not found. Please ensure Nix is installed correctly.${NC}"
        exit 1
    fi
    switch
fi

# 7. Add SSH key to keychain
if [ "$SKIP_KEYCHAIN" = true ]; then
    echo -e "${YELLOW}⚠️ Skipping SSH key addition to keychain${NC}"
elif [ "$SKIP_SSH" = false ]; then
    echo -e "${YELLOW}🔑 Adding SSH key to keychain...${NC}"
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        echo -e "${RED}❌ SSH key not found. Please ensure SSH setup completed successfully.${NC}"
        exit 1
    fi
    /usr/bin/ssh-add --apple-use-keychain ~/.ssh/id_ed25519
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to add SSH key to keychain${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ SSH key added to keychain${NC}"
fi

echo -e "${GREEN}✅ Environment setup complete!${NC}"
