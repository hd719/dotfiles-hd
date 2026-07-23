# =============================================================================
# ZSH Configuration (Mac mini - Hermes)
# =============================================================================

_source_zsh_config() {
  local file="$1"
  [[ -r "$file" ]] && source "$file"
}

# -----------------------------------------------------------------------------
# Core Configuration
# -----------------------------------------------------------------------------
_source_zsh_config "$HOME/Developer/dotfiles-hd/config/zsh/mac/init.zsh"

# -----------------------------------------------------------------------------
# Plugins
# -----------------------------------------------------------------------------
if (( $+functions[_load_homebrew_plugin] )); then
  _load_homebrew_plugin "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  _load_homebrew_plugin "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# -----------------------------------------------------------------------------
# Completions
# -----------------------------------------------------------------------------
if (( $+functions[_zsh_init_completions] )); then
  _zsh_add_completion_dirs "$HOME/.docker/completions"
  _zsh_init_completions daily
fi

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
[[ -d /opt/homebrew/opt/curl/bin ]] && export PATH="/opt/homebrew/opt/curl/bin:$PATH"
[[ -d /opt/homebrew/opt/postgresql@17/bin ]] && export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
# uv tools may use XDG_BIN_HOME. Keep the default local bin too because the Mac
# mini stores machine-local helpers such as cua-driver-rs there.
typeset -gaU path
path=("${XDG_BIN_HOME:-$HOME/.local/bin}" "$HOME/.local/bin" $path)
export PATH

if [[ -f "$HOME/.local/bin/env" ]]; then
  source "$HOME/.local/bin/env"
fi

if [[ -n "$SSH_CONNECTION" ]]; then
  export GIT_EDITOR="code --wait"
  export EDITOR="code --wait"
fi

export GOG_ACCOUNT="hameldesai3@gmail.com"
[[ -f "$HOME/.gog-env" ]] && source "$HOME/.gog-env"

# -----------------------------------------------------------------------------
# Tool Init Scripts
# -----------------------------------------------------------------------------
if (( $+functions[_zsh_load_common_tool_completions] )); then
  _zsh_load_common_tool_completions
fi

if (( $+functions[_activate_mise] )); then
  _activate_mise
fi
