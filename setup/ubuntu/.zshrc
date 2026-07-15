# Ubuntu zsh configuration

# [Paths]
# --------------------------------------------------------------------------------------------------------
typeset -U path PATH

# `:A` resolves ~/.zshrc when this file is linked from a QA checkout, then three
# `:h` modifiers walk from setup/ubuntu/.zshrc back to the repository root.
DOTFILES_DIR="${DOTFILES_DIR:-${${(%):-%N}:A:h:h:h}}"
ZSH_CONFIG_DIR="$DOTFILES_DIR/setup/mac-vm/zsh-config"

path=(
  "$HOME/.local/bin"
  "$HOME/Developer/tools/anycable"
  $path
)

export TERM="xterm-256color"
export STARSHIP_CONFIG="$DOTFILES_DIR/config/starship/starship.toml"

# [Editor]
# --------------------------------------------------------------------------------------------------------
export GIT_EDITOR="code --wait"
export EDITOR="code --wait"

# [Shared zsh helpers]
# --------------------------------------------------------------------------------------------------------
source_if_exists() {
  [[ -r "$1" ]] && source "$1"
}

source_if_exists "$ZSH_CONFIG_DIR/functions.zsh"
source_if_exists "$ZSH_CONFIG_DIR/alias.zsh"
source_if_exists "$ZSH_CONFIG_DIR/k8s.zsh"

# [Prompt]
# --------------------------------------------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi

# [Language managers]
# --------------------------------------------------------------------------------------------------------
if [[ -d "$HOME/.rbenv" ]]; then
  path=("$HOME/.rbenv/bin" $path)
  eval "$(rbenv init - zsh)"
fi

if [[ -f "$HOME/.local/bin/env" ]]; then
  source "$HOME/.local/bin/env"
fi

# Keep mise last so its configured runtimes win over rbenv and system tools.
if typeset -f _activate_mise >/dev/null; then
  _activate_mise
fi

# [Plugins]
# --------------------------------------------------------------------------------------------------------
source_if_exists "$HOME/Developer/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source_if_exists "$HOME/Developer/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source_if_exists "$HOME/Developer/zsh-plugins/zsh-you-should-use/you-should-use.plugin.zsh"
