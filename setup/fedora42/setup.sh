#!/usr/bin/env zsh

# Manual Steps:
# 1. Update copy and paste commands in terminal (default) and change mission control to hyper
# 2. Symlink .zshrc from dotfiles (Fedora 42)
# 3. Copy over gitignore and gitconfig from dotfiles
# 4. Setup tmux configq
# 4. Install Cursor AppImage\
# 5. Install a browser (Brave)
# 5. Install Pycharm
# 6. Install Goland

# Zoom Issue
# gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
# gsettings set org.gnome.desktop.interface text-scaling-factor 1.75

# Warp Terminal
# Install: 
# sudo dnf install warp-terminal
# Known issues: https://github.com/warpdotdev/Warp/issues/5554
# Fix: WGPU_BACKEND=Vulkan warp-terminal

# TODO:
# - Clone rails and run it

# execute chmod +x ~/setup-fedora.sh
# ./setup-fedora.sh

# Just incase the shared folder is not mounted, run this script again.
# vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other

# 1. Create the mount point directory (if it doesn't exist)
# sudo mkdir -p /mnt/hgfs

# 2. Change ownership to your user
# sudo chown $USER:$USER /mnt/hgfs

# 3. (Optional but safer) Give full access to the directory
# sudo chmod 777 /mnt/hgfs

# 4. Enable allow_other in FUSE (edit config file)
# sudo sh -c 'echo "user_allow_other" >> /etc/fuse.conf'

# 5. Mount the shared folder manually
# vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other

# 6. Verify it's working
# ls /mnt/hgfs

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

TOTAL_STEPS=14
CURRENT_STEP=0
step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "${YELLOW}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] $1${NC}"
}

enable_vmware_shared_folder() {
    step "Enabling VMware shared folder"

    if ! command -v vmhgfs-fuse &>/dev/null; then
        echo -e "${YELLOW}📦 Installing open-vm-tools and fuse...${NC}"
        sudo dnf install -y open-vm-tools open-vm-tools-desktop fuse3
    fi

    sudo systemctl enable --now vmtoolsd.service

    sudo mkdir -p /mnt/hgfs
    sudo vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other

    echo -e "${GREEN}✓ Shared folder mounted at /mnt/hgfs${NC}"

    echo -e "${YELLOW}📁 Contents of /mnt/hgfs:${NC}"
    ls /mnt/hgfs || echo -e "${RED}❌ Nothing found. Make sure sharing is enabled in VMware.${NC}"

    # Create symlink in home directory
    if [ ! -L "$HOME/Shared" ]; then
        ln -s /mnt/hgfs "$HOME/Shared"
        echo -e "${GREEN}✓ Symlink created: ~/Shared → /mnt/hgfs${NC}"
    else
        echo -e "${YELLOW}⚠️ ~/Shared already exists${NC}"
    fi
}

check_network() {
    echo -e "${YELLOW}🔍 Checking network...${NC}"
    ping -c 1 github.com &>/dev/null || {
        echo -e "${RED}❌ No internet connection${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ Network OK${NC}"
}

check_fedora_version() {
    echo -e "${YELLOW}🔍 Checking Fedora version...${NC}"
    VERSION=$(grep -o '[0-9]\+' /etc/fedora-release)
    [[ "$VERSION" -lt 36 ]] && {
        echo -e "${RED}❌ Fedora version too old ($VERSION)${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ Fedora $VERSION detected${NC}"
}

install_base_tools() {
    step "Installing base packages + dev tools"

    sudo dnf upgrade --refresh -y

    # Use correct Fedora package names and --skip-unavailable
    sudo dnf install -y --skip-unavailable \
        git curl wget gcc make unzip tar zsh vim \
        jq zstd ffmpeg ghostscript ImageMagick vips \
        bat lsd btop fastfetch diff-so-fancy zoxide \
        tmux redis nmap speedtest-cli kubectl awscli2 python3-pip pipx golang

    # zsh-completions: warn if not available
    if ! sudo dnf install -y zsh-completions; then
        echo -e "${YELLOW}⚠️  zsh-completions not available in Fedora repos. Skipping.${NC}"
    fi

    # Starship fallback install if not found
    if ! command -v starship &>/dev/null; then
        echo -e "${YELLOW}Installing starship via script...${NC}"
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    # Terraform fallback install if not found
    if ! command -v terraform &>/dev/null; then
        echo -e "${YELLOW}Installing terraform via script...${NC}"
        TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)
        ARCH=$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')
        curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -o terraform.zip
        unzip terraform.zip
        sudo mv terraform /usr/local/bin/
        rm -f terraform.zip
    fi

    chsh -s $(which zsh)

    echo -e "${GREEN}✓ Base and dev tools installed${NC}"
}

install_docker() {
    step "Installing Docker (Engine, CLI, Compose)"

    # Remove any old versions
    sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true

    # Add Docker repository manually (Fedora 42+)
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOF

    # Install Docker Engine, CLI, and containerd
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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

    if ! grep -q "starship init zsh" ~/.zshrc 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    fi

    if ! grep -q "zoxide init" ~/.zshrc 2>/dev/null; then
        echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
    fi

    # if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    #     echo "source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
    # fi

    echo -e "${GREEN}✓ Zsh + Starship configured${NC}"
}

install_node_and_pnpm() {
    step "Installing Node.js (nvm) + pnpm"
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    nvm install --lts
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    echo -e "${GREEN}✓ Node.js and pnpm installed${NC}"
}

install_ruby_rails() {
    step "Installing Ruby + Rails"
    sudo dnf install -y ruby ruby-devel
    gem install rails
    echo -e "${GREEN}✓ Ruby and Rails installed${NC}"
}

install_rbenv() {
    step "Installing rbenv"
    if ! command -v rbenv &>/dev/null; then
        echo -e "${YELLOW}📦 Installing rbenv via Homebrew (Linuxbrew)...${NC}"
        if ! command -v brew &>/dev/null; then
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
        fi
        brew install rbenv
    fi

    # Only add rbenv init if not already present
    if ! grep -q 'eval "$(rbenv init - zsh)"' ~/.zshrc; then
        echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
    fi
    echo -e "${GREEN}✓ rbenv installed${NC}"
}

install_ruby_lsp_and_ruby_build() {
    step "Installing ruby-lsp and ruby-build"

    gem install ruby-lsp

    if [ -d "$(rbenv root)" ]; then
        RUBY_BUILD_DIR="$(rbenv root)/plugins/ruby-build"
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
    pipx ensurepath
    pipx install uv
    echo -e "${GREEN}✓ uv installed${NC}"
}

install_and_configure_redis() {
    step "Installing and configuring Redis"

    sudo dnf install -y redis
    sudo systemctl enable redis
    sudo systemctl start redis

    if systemctl is-active --quiet redis; then
        echo -e "${GREEN}✓ Redis is running${NC}"
    else
        echo -e "${RED}❌ Redis failed to start${NC}"
        systemctl status redis --no-pager
        exit 1
    fi
}

install_anycable_go() {
    step "Installing anycable-go"
    mkdir -p ~/Developer/tools/anycable
    cd ~/Developer/tools/anycable

    if [ ! -f anycable-go ]; then
        curl -sL https://github.com/anycable/anycable-go/releases/latest/download/anycable-go-linux-amd64 -o anycable-go
        chmod +x anycable-go
        echo 'export PATH="$HOME/Developer/tools/anycable:$PATH"' >> ~/.zshrc
        echo -e "${GREEN}✓ anycable-go installed${NC}"
    else
        echo -e "${YELLOW}⚠️ anycable-go already exists${NC}"
    fi
}

install_zsh_plugins() {
    step "Installing Zsh plugins"

    PLUGIN_DIR="$HOME/Developer/zsh-plugins"
    mkdir -p "$PLUGIN_DIR"

    if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
        echo "source $PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
    fi

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

link_zshrc_from_dotfiles() {
    step "Symlinking .zshrc from dotfiles"

    DOTFILE_ZSHRC="$HOME/Developer/dotfiles-hd/setup/.zshrc"

    if [ -f "$DOTFILE_ZSHRC" ]; then
        if [ -L "$HOME/.zshrc" ] && [ "$(readlink "$HOME/.zshrc")" = "$DOTFILE_ZSHRC" ]; then
            # Already correctly symlinked
            echo -e "${GREEN}✓ ~/.zshrc is already symlinked to dotfiles .zshrc${NC}"
        else
            if [ -e "$HOME/.zshrc" ]; then
                echo -e "${YELLOW}⚠️  ~/.zshrc exists and will be replaced with symlink${NC}"
                rm -f "$HOME/.zshrc"
            fi
            ln -s "$DOTFILE_ZSHRC" "$HOME/.zshrc"
            echo -e "${GREEN}✓ Linked dotfiles .zshrc to home directory${NC}"
        fi
    else
        echo -e "${RED}❌ $DOTFILE_ZSHRC not found. Skipping symlink.${NC}"
    fi
}

install_linuxbrew() {
    step "Installing Homebrew (Linuxbrew)"

    if ! command -v brew &>/dev/null; then
        echo -e "${YELLOW}📦 Downloading Homebrew installer...${NC}"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for this session and future ones
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

        echo -e "${GREEN}✓ Homebrew installed to ~/.linuxbrew${NC}"
    else
        echo -e "${YELLOW}⚠️ Homebrew already installed${NC}"
    fi
}

install_ghostty_if_missing() {
    step "Installing Ghostty (terminal) if not already installed"

    # Check if Ghostty is already installed
    if command -v ghostty &>/dev/null; then
        echo -e "${GREEN}✓ Ghostty already installed: $(command -v ghostty)${NC}"
        ghostty --version || echo -e "${YELLOW}⚠️ Ghostty version check failed${NC}"
        return
    fi

    # Install Ghostty using COPR repo and dnf
    echo -e "${YELLOW}📦 Enabling COPR repo and installing Ghostty...${NC}"
    sudo dnf -y copr enable pgdev/ghostty
    sudo dnf install -y ghostty

    if command -v ghostty &>/dev/null; then
        echo -e "${GREEN}✓ Ghostty installed: $(command -v ghostty)${NC}"
        ghostty --version || echo -e "${YELLOW}⚠️ Ghostty version check failed${NC}"
    else
        echo -e "${RED}❌ Ghostty installation failed${NC}"
        return 1
    fi
}

update_ghostty() {
    step "Updating Ghostty to latest version"

    ARCH=$(uname -m)
    case "$ARCH" in
        aarch64) BIN="ghostty-linux-aarch64" ;;
        x86_64)  BIN="ghostty-linux-x86_64" ;;
        *) echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"; return 1 ;;
    esac

    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    echo -e "${YELLOW}⬇️ Downloading Ghostty...${NC}"
    curl -sLO "https://github.com/ghostty-org/ghostty/releases/latest/download/$BIN"
    chmod +x "$BIN"

    echo -e "${YELLOW}🔁 Updating binary... (requires sudo)${NC}"
    sudo mv "$BIN" /usr/local/bin/ghostty

    echo -e "${GREEN}✓ Ghostty updated:$(ghostty --version)${NC}"

    cd ~
    rm -rf "$TMP_DIR"
}

link_dotfiles_configs() {
    step "Linking config files from dotfiles"

    DOTFILES_DIR="$HOME/Developer/dotfiles-hd/config"
    CONFIG_DIR="$HOME/.config"

    APPS=("ghostty" "btop" "fastfetch" "bat" "tmux" "wtf")

    for app in "${APPS[@]}"; do
        SRC="$DOTFILES_DIR/$app"
        DEST="$CONFIG_DIR/$app"

        if [[ -e "$DEST" || -L "$DEST" ]]; then
            echo -e "${YELLOW}⚠️  Backing up existing $DEST → $DEST.bak${NC}"
            mv "$DEST" "$DEST.bak"
        fi

        echo -e "${YELLOW}🔗 Linking $SRC → $DEST${NC}"
        ln -s "$SRC" "$DEST"
    done

    echo -e "${GREEN}✓ Dotfiles config symlinks complete${NC}"
}

# Main execution
echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
echo -e "${GREEN}🚀 Starting Fedora 42 Dev Setup...${NC}"

check_network
check_fedora_version
install_base_tools
install_docker
# install_ghostty_if_missing
install_starship_zsh_config
install_node_and_pnpm
install_linuxbrew
install_ruby_rails
install_rbenv
install_ruby_lsp_and_ruby_build
install_uv
install_and_configure_redis
install_anycable_go
# install_zsh_plugins
# clone_dotfiles
enable_vmware_shared_folder
link_dotfiles_configs
# link_zshrc_from_dotfiles

echo -e "\n${GREEN}🎉 Setup complete! Restart your shell to apply all changes.${NC}"
echo -e "${MAGENTA}🙏 Om Shree Ganeshaya Namaha 🙏${NC}"
