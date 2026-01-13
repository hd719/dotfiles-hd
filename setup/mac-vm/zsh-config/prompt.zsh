# [Prompt]
# --------------------------------------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"
export TERM=xterm-256color

# Cache directory for init scripts
_ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$_ZSH_CACHE_DIR" 2>/dev/null

# Helper: Cache and source init scripts (avoids slow eval on every shell)
_cache_init() {
  local name="$1"
  local cmd="$2"
  local cache_file="$_ZSH_CACHE_DIR/${name}-init.zsh"

  # Regenerate if missing or older than 1 day
  if [[ ! -f "$cache_file" || $(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0) )) -gt 86400 ]]; then
    eval "$cmd" > "$cache_file" 2>/dev/null
  fi

  source "$cache_file"
}

# Check if Nix/Devbox is installed (native zsh check - faster than command -v)
if (( $+commands[nix] )); then
    # With Devbox: Use Nix-managed binaries
    _cache_init "zoxide" "/Users/hameldesai/.local/share/devbox/global/default/.devbox/nix/profile/default/bin/zoxide init --cmd cd zsh"
    _cache_init "starship" "/Users/hameldesai/.local/share/devbox/global/default/.devbox/nix/profile/default/bin/starship init zsh"
else
    # Without Devbox: Use system binaries
    _cache_init "zoxide" "zoxide init --cmd cd zsh"
    _cache_init "starship" "starship init zsh"
fi

export STARSHIP_CONFIG=~/Developer/dotfiles-hd/config/starship/starship.toml

source ~/Developer/zsh-you-should-use/you-should-use.plugin.zsh
