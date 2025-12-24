ZSH_CONFIG_DIR=~/Developer/dotfiles-hd/setup/mac-vm/zsh-config

# [ZSH/System Config]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/prompt.zsh

# [Tooling]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/tooling.zsh

# [Aliases]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/alias.zsh

# [Functions]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/functions.zsh

# [Kubernetes Config]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/k8s.zsh

 # [Autosuggestions] from Devbox/Nix store
    devbox_zsh_autosuggestions=(/nix/store/*-zsh-autosuggestions-*/share/zsh-autosuggestions/zsh-autosuggestions.zsh)
    if [[ -r "${devbox_zsh_autosuggestions[1]}" ]]; then
      source "${devbox_zsh_autosuggestions[1]}"
    fi

    # [Syntax Highlighting] from Devbox/Nix store
    devbox_zsh_syntax_highlighting=(/nix/store/*-zsh-syntax-highlighting-*/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh)
    if [[ -r "${devbox_zsh_syntax_highlighting[1]}" ]]; then
      source "${devbox_zsh_syntax_highlighting[1]}"
    fi

# # Add paths to environment variables
# PATH=~/.console-ninja/.bin:$PATH

# [Devbox]
# --------------------------------------------------------------------------------------------------------
eval "$(devbox global shellenv)"

# [Job Config]
# --------------------------------------------------------------------------------------------------------
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/hameldesai/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
