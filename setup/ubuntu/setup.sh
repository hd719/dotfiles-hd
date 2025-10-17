#!/usr/bin/env bash

# Manual Steps:
# 1. Symlink .zshrc from dotfiles (Ubuntu)
# 2. Copy over gitignore and gitconfig from dotfiles
# 3. Setup tmux config
# 4. Install Cursor AppImage
# 5. Install a browser (Brave/Firefox)

# execute chmod +x ~/setup-ubuntu.sh
# ./setup-ubuntu.sh

set -e

# Disable interactive aliases that might prompt for confirmation
unalias rm 2>/dev/null || true
unalias mv 2>/dev/null || true
unalias cp 2>/dev/null || true
unalias ln 2>/dev/null || true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

TOTAL_STEPS=13
CURRENT_STEP=0
step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "${YELLOW}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] $1${NC}"
}

check_network() {
    echo -e "${YELLOW}🔍 Checking network...${NC}"
    ping -c 1 github.com &>/dev/null || {
        echo -e "${RED}❌ No internet connection${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ Network OK${NC}"
}

check_ubuntu_version() {
    echo -e "${YELLOW}🔍 Checking Ubuntu version...${NC}"

    # Check if running on Ubuntu
    if [ ! -f /etc/os-release ]; then
        echo -e "${RED}❌ Cannot detect OS version${NC}"
        exit 1
    fi

    source /etc/os-release

    if [[ "$ID" != "ubuntu" ]]; then
        echo -e "${RED}❌ This script is for Ubuntu only (detected: $ID)${NC}"
        exit 1
    fi

    # Extract major version number
    VERSION_NUM=$(echo "$VERSION_ID" | cut -d'.' -f1)

    if [[ "$VERSION_NUM" -lt 20 ]]; then
        echo -e "${RED}❌ Ubuntu version too old ($VERSION_ID). Requires 20.04 or newer.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Ubuntu $VERSION_ID detected${NC}"
}

install_base_tools() {
    step "Installing base packages + dev tools"

    # Update package lists
    sudo apt update

    # Install base tools
    sudo apt install -y \
        git curl wget gcc make unzip tar zsh vim \
        build-essential libssl-dev libreadline-dev zlib1g-dev \
        jq zstd ffmpeg ghostscript imagemagick libvips-dev \
        tmux redis-server nmap speedtest-cli python3-pip python3-venv pipx golang

    # Install bat (might be named batcat on Ubuntu)
    if ! command -v bat &>/dev/null; then
        sudo apt install -y bat
        # Create symlink if installed as batcat
        if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
            mkdir -p ~/.local/bin
            ln -s /usr/bin/batcat ~/.local/bin/bat
            echo -e "${YELLOW}⚠️  Created bat symlink from batcat${NC}"
        fi
    fi

    # Install lsd (modern ls replacement)
    if ! command -v lsd &>/dev/null; then
        echo -e "${YELLOW}Installing lsd...${NC}"
        LSD_VERSION=$(curl -s https://api.github.com/repos/lsd-rs/lsd/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
        ARCH=$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')
        curl -sL "https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd_${LSD_VERSION}_${ARCH}.deb" -o /tmp/lsd.deb
        sudo dpkg -i /tmp/lsd.deb
        rm /tmp/lsd.deb
    fi

    # Install btop (system monitor)
    if ! command -v btop &>/dev/null; then
        echo -e "${YELLOW}Installing btop...${NC}"
        sudo apt install -y btop || {
            echo -e "${YELLOW}⚠️  btop not in default repos, trying snap...${NC}"
            sudo snap install btop
        }
    fi

    # Install fastfetch (system info)
    if ! command -v fastfetch &>/dev/null; then
        echo -e "${YELLOW}Installing fastfetch...${NC}"
        sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y || true
        sudo apt update
        sudo apt install -y fastfetch || {
            echo -e "${YELLOW}⚠️  fastfetch not available, skipping...${NC}"
        }
    fi

    # Install diff-so-fancy (better git diffs) from GitHub
    if ! command -v diff-so-fancy &>/dev/null; then
        echo -e "${YELLOW}Installing diff-so-fancy from GitHub...${NC}"
        DIFF_SO_FANCY_DIR="$HOME/.local/share/diff-so-fancy"
        
        # Clone the repository if not already present
        if [ ! -d "$DIFF_SO_FANCY_DIR" ]; then
            git clone https://github.com/so-fancy/diff-so-fancy.git "$DIFF_SO_FANCY_DIR"
        fi
        
        # Create symlink in .local/bin
        mkdir -p "$HOME/.local/bin"
        ln -sf "$DIFF_SO_FANCY_DIR/diff-so-fancy" "$HOME/.local/bin/diff-so-fancy"
        
        echo -e "${GREEN}✓ diff-so-fancy installed${NC}"
    fi

    # Install zoxide (smarter cd)
    if ! command -v zoxide &>/dev/null; then
        echo -e "${YELLOW}Installing zoxide...${NC}"
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    fi

    # Install starship prompt
    if ! command -v starship &>/dev/null; then
        echo -e "${YELLOW}Installing starship via script...${NC}"
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    # Install kubectl
    if ! command -v kubectl &>/dev/null; then
        echo -e "${YELLOW}Installing kubectl...${NC}"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    fi

    # Install AWS CLI v2
    if ! command -v aws &>/dev/null; then
        echo -e "${YELLOW}Installing AWS CLI v2...${NC}"
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64) AWS_ARCH="x86_64" ;;
            aarch64) AWS_ARCH="aarch64" ;;
            *) echo -e "${YELLOW}⚠️  Unsupported architecture for AWS CLI: $ARCH${NC}"; AWS_ARCH="" ;;
        esac

        if [[ -n "$AWS_ARCH" ]]; then
            curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "awscliv2.zip"
            unzip -q awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
        fi
    fi

    # Install Terraform
    if ! command -v terraform &>/dev/null; then
        echo -e "${YELLOW}Installing terraform...${NC}"
        TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)
        ARCH=$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')
        curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -o terraform.zip
        unzip -q terraform.zip
        sudo mv terraform /usr/local/bin/
        rm -f terraform.zip
    fi

    # Change default shell to zsh
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        echo -e "${YELLOW}Changing default shell to zsh...${NC}"
        chsh -s $(which zsh)
    fi

    echo -e "${GREEN}✓ Base and dev tools installed${NC}"
}

install_docker() {
    step "Installing Docker (Engine, CLI, Compose)"

    # Check if Docker is already installed
    if command -v docker &>/dev/null; then
        echo -e "${YELLOW}⚠️  Docker already installed${NC}"
        return
    fi

    # Remove any old versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Install prerequisites
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key (remove old one first to avoid prompts)
    sudo mkdir -p /etc/apt/keyrings
    sudo rm -f /etc/apt/keyrings/docker.gpg
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Enable and start Docker
    sudo systemctl enable --now docker

    # Add current user to docker group (for non-root usage)
    sudo usermod -aG docker $USER

    # Test Docker installation
    if sudo systemctl is-active --quiet docker; then
        echo -e "${GREEN}✓ Docker installed and running${NC}"
        echo -e "${YELLOW}⚠️  You may need to log out and back in for group changes to take effect.${NC}"
    else
        echo -e "${RED}❌ Docker failed to start${NC}"
        sudo systemctl status docker --no-pager
        exit 1
    fi
}

install_starship_zsh_config() {
    step "Configuring Zsh + Starship"

    # Create .zshrc if it doesn't exist
    touch ~/.zshrc

    # Add starship initialization
    if ! grep -q "starship init zsh" ~/.zshrc 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    fi

    # Add zoxide initialization
    if ! grep -q "zoxide init" ~/.zshrc 2>/dev/null; then
        echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
    fi

    echo -e "${GREEN}✓ Zsh + Starship configured${NC}"
}

install_node_and_pnpm() {
    step "Installing Node.js (fnm) + pnpm"

    # Install fnm if not already installed
    if ! command -v fnm &>/dev/null; then
        echo -e "${YELLOW}Installing fnm...${NC}"
        curl -fsSL https://fnm.vercel.app/install | bash
    fi

    # Load fnm for this session
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --use-on-cd)"

    # Install LTS version of Node.js
    fnm install --lts
    fnm use lts-latest

    # Add fnm initialization to .zshrc if not already present
    if ! grep -q "fnm env" ~/.zshrc 2>/dev/null; then
        echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
    fi

    # Install pnpm
    if ! command -v pnpm &>/dev/null; then
        curl -fsSL https://get.pnpm.io/install.sh | sh -
    fi

    echo -e "${GREEN}✓ Node.js (via fnm) and pnpm installed${NC}"
}

install_rbenv() {
    step "Installing rbenv + Ruby LTS"

    # Check if rbenv directory exists
    if [ ! -d "$HOME/.rbenv" ]; then
        echo -e "${YELLOW}📦 Installing rbenv via git clone...${NC}"

        # Clone rbenv
        git clone https://github.com/rbenv/rbenv.git ~/.rbenv

        # Add rbenv to PATH and initialize in .zshrc if not already present
        if ! grep -q 'rbenv init' ~/.zshrc; then
            echo '' >> ~/.zshrc
            echo '# Initialize rbenv if it exists' >> ~/.zshrc
            echo 'if [ -d "$HOME/.rbenv" ]; then' >> ~/.zshrc
            echo '  export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
            echo '  eval "$(rbenv init - zsh)"' >> ~/.zshrc
            echo 'fi' >> ~/.zshrc
        fi

        # Make rbenv available in current session
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(~/.rbenv/bin/rbenv init - zsh)"

        echo -e "${GREEN}✓ rbenv installed${NC}"
    else
        echo -e "${YELLOW}⚠️ rbenv already installed${NC}"
        
        # Ensure it's in PATH for current session
        if [ -d "$HOME/.rbenv/bin" ]; then
            export PATH="$HOME/.rbenv/bin:$PATH"
            eval "$(rbenv init - zsh)" 2>/dev/null || true
        fi
    fi

    # Install ruby-build plugin if not already installed
    RUBY_BUILD_DIR="$HOME/.rbenv/plugins/ruby-build"
    if [ ! -d "$RUBY_BUILD_DIR" ]; then
        echo -e "${YELLOW}📦 Installing ruby-build plugin...${NC}"
        git clone https://github.com/rbenv/ruby-build.git "$RUBY_BUILD_DIR"
        echo -e "${GREEN}✓ ruby-build installed${NC}"
    fi

    # Install latest stable Ruby if no Ruby version is installed
    if ! rbenv versions | grep -q '[0-9]'; then
        echo -e "${YELLOW}📦 Installing latest stable Ruby...${NC}"
        
        # Get the latest stable Ruby version (3.x series)
        LATEST_RUBY=$(rbenv install -l | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
        
        if [ -n "$LATEST_RUBY" ]; then
            echo -e "${YELLOW}Installing Ruby ${LATEST_RUBY}...${NC}"
            rbenv install "$LATEST_RUBY"
            rbenv global "$LATEST_RUBY"
            echo -e "${GREEN}✓ Ruby ${LATEST_RUBY} installed and set as global${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not determine latest Ruby version${NC}"
        fi
    else
        echo -e "${GREEN}✓ Ruby already installed: $(rbenv version)${NC}"
    fi
}

install_ruby_lsp_and_ruby_build() {
    step "Installing ruby-lsp and ruby-build"

    # Install ruby-lsp gem (requires Ruby to be installed first)
    if command -v gem &>/dev/null; then
        gem install ruby-lsp
    else
        echo -e "${YELLOW}⚠️ Ruby not installed yet, skipping ruby-lsp. Install Ruby first via rbenv.${NC}"
    fi

    # Install ruby-build plugin for rbenv
    if [ -d "$HOME/.rbenv" ]; then
        RUBY_BUILD_DIR="$HOME/.rbenv/plugins/ruby-build"
        if [ -d "$RUBY_BUILD_DIR" ]; then
            echo -e "${YELLOW}⚠️ ruby-build already exists at $RUBY_BUILD_DIR. Skipping clone.${NC}"
        else
            git clone https://github.com/rbenv/ruby-build.git "$RUBY_BUILD_DIR"
            echo -e "${GREEN}✓ ruby-build installed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ rbenv not found — skipping ruby-build${NC}"
    fi
}

install_uv() {
    step "Installing uv for Python"

    # Ensure pipx is available and in PATH
    pipx ensurepath

    # Install uv via pipx
    pipx install uv

    echo -e "${GREEN}✓ uv installed${NC}"
}

install_and_configure_redis() {
    step "Installing and configuring Redis"

    sudo apt install -y redis-server

    # Enable and start Redis
    sudo systemctl enable redis-server
    sudo systemctl start redis-server

    # Check if Redis is running
    if systemctl is-active --quiet redis-server; then
        echo -e "${GREEN}✓ Redis is running${NC}"
    else
        echo -e "${RED}❌ Redis failed to start${NC}"
        systemctl status redis-server --no-pager
        exit 1
    fi
}

install_zsh_plugins() {
    step "Installing Zsh plugins"

    PLUGIN_DIR="$HOME/Developer/zsh-plugins"
    mkdir -p "$PLUGIN_DIR"

    # Install zsh-autosuggestions (gray suggestions as you type)
    if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
        echo "source $PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
    fi

    # Install zsh-syntax-highlighting (green/red command highlighting)
    if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting"
        echo "source $PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
    fi

    # Install zsh-you-should-use (suggests aliases)
    if [ ! -d "$PLUGIN_DIR/zsh-you-should-use" ]; then
        git clone https://github.com/MichaelAquilina/zsh-you-should-use "$PLUGIN_DIR/zsh-you-should-use"
        echo "source $PLUGIN_DIR/zsh-you-should-use/you-should-use.plugin.zsh" >> ~/.zshrc
    fi

    echo -e "${GREEN}✓ Zsh plugins installed${NC}"
}

clone_dotfiles() {
    step "Cloning dotfiles"

    mkdir -p ~/Developer

    if [ ! -d ~/Developer/dotfiles-hd ]; then
        git clone https://github.com/hameldesai/dotfiles-hd.git ~/Developer/dotfiles-hd
        echo -e "${GREEN}✓ Dotfiles cloned${NC}"
    else
        echo -e "${YELLOW}⚠️ dotfiles-hd already exists${NC}"
    fi
}

link_dotfiles_configs() {
    step "Linking config files from dotfiles"

    DOTFILES_DIR="$HOME/Developer/dotfiles-hd/config"
    CONFIG_DIR="$HOME/.config"

    # Create .config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"

    # List of applications to symlink
    APPS=("btop" "fastfetch" "bat" "tmux" "wtf" "ghostty")

    for app in "${APPS[@]}"; do
        SRC="$DOTFILES_DIR/$app"
        DEST="$CONFIG_DIR/$app"

        # Check if source exists
        if [ ! -e "$SRC" ]; then
            echo -e "${YELLOW}⚠️  $SRC doesn't exist, skipping...${NC}"
            continue
        fi

        # Remove existing destination (backup already exists or first run)
        if [[ -e "$DEST" || -L "$DEST" ]]; then
            # Only backup if no backup exists yet
            if [[ ! -e "$DEST.bak" ]]; then
                echo -e "${YELLOW}⚠️  Backing up existing $DEST → $DEST.bak${NC}"
                /bin/mv -f "$DEST" "$DEST.bak"
            else
                echo -e "${YELLOW}⚠️  Removing existing $DEST (backup already exists)${NC}"
                /bin/rm -rf "$DEST"
            fi
        fi

        # Create symlink
        echo -e "${YELLOW}🔗 Linking $SRC → $DEST${NC}"
        /bin/ln -s "$SRC" "$DEST"
    done

    echo -e "${GREEN}✓ Dotfiles config symlinks complete${NC}"
}

install_vscode() {
    step "Installing Visual Studio Code (code)"

    # Check if VS Code is already installed
    if command -v code &>/dev/null; then
        echo -e "${YELLOW}⚠️  VS Code already installed${NC}"
        return
    fi

    # Remove any existing VS Code repository configurations to avoid conflicts
    sudo rm -f /etc/apt/sources.list.d/vscode.list
    sudo rm -f /usr/share/keyrings/microsoft.gpg
    sudo rm -f /etc/apt/keyrings/packages.microsoft.gpg

    # Import Microsoft GPG key
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    rm -f packages.microsoft.gpg

    # Add VS Code repository
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

    # Update and install
    sudo apt update
    sudo apt install -y code

    echo -e "${GREEN}✓ Visual Studio Code installed${NC}"
}

install_ghostty() {
    step "Installing Ghostty terminal"

    # Check if snap is available
    if ! command -v snap &>/dev/null; then
        echo -e "${YELLOW}⚠️  snap not found, skipping Ghostty installation${NC}"
        return
    fi

    # Install Ghostty terminal via snap
    if ! snap list ghostty &>/dev/null 2>&1; then
        echo -e "${YELLOW}Installing Ghostty terminal...${NC}"
        sudo snap install ghostty --edge --classic
        echo -e "${GREEN}✓ Ghostty terminal installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Ghostty already installed${NC}"
    fi
}

# Main execution
echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
echo -e "${GREEN}🚀 Starting Ubuntu Dev Setup...${NC}"

# Fix any existing apt configuration conflicts before starting
echo -e "${YELLOW}🔧 Checking for apt configuration conflicts...${NC}"
if [ -f /etc/apt/sources.list.d/vscode.list ] && [ -f /usr/share/keyrings/microsoft.gpg ]; then
    echo -e "${YELLOW}⚠️  Found conflicting VS Code repository configuration, cleaning up...${NC}"
    sudo rm -f /usr/share/keyrings/microsoft.gpg
fi

check_network
check_ubuntu_version
install_base_tools
install_docker
install_starship_zsh_config
install_node_and_pnpm
install_rbenv
install_ruby_lsp_and_ruby_build
install_uv
install_and_configure_redis
install_zsh_plugins
link_dotfiles_configs
install_vscode
install_ghostty

echo -e "\n${GREEN}🎉 Setup complete! Restart your shell to apply all changes.${NC}"
echo -e "${YELLOW}📝 Don't forget to complete the manual steps at the top of this script!${NC}"
echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
