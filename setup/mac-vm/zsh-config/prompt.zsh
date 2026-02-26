# [Prompt]
# --------------------------------------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"
export TERM=xterm-256color

# Cache directory for init scripts (created once in functions.zsh)
_ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$_ZSH_CACHE_DIR" ]] || mkdir -p "$_ZSH_CACHE_DIR"

# Load zsh modules for fast datetime/stat (avoids external commands)
zmodload zsh/datetime 2>/dev/null
zmodload zsh/stat 2>/dev/null

# Helper: Cache and source init scripts (avoids slow eval on every shell)
# Uses zsh native stat instead of external stat command
_cache_init() {
  local name="$1"
  local cmd="$2"
  local cache_file="$_ZSH_CACHE_DIR/${name}-init.zsh"
  local refresh_cache=0

  # Regenerate if missing or older than 1 day (86400 seconds)
  # Uses zsh native $EPOCHSECONDS and zstat instead of external commands
  if [[ ! -s "$cache_file" ]]; then
    refresh_cache=1
  else
    local file_mtime
    zstat -A file_mtime +mtime "$cache_file" 2>/dev/null || refresh_cache=1
    if (( EPOCHSECONDS - file_mtime > 86400 )); then
      refresh_cache=1
    fi
  fi

  if (( refresh_cache )); then
    local tmp_file="${cache_file}.tmp.$$"
    if eval "$cmd" > "$tmp_file" 2>/dev/null && [[ -s "$tmp_file" ]]; then
      mv "$tmp_file" "$cache_file"
    else
      rm -f "$tmp_file"
    fi
  fi

  [[ -s "$cache_file" ]] || return 1
  source "$cache_file"
}

# Check if Nix/Devbox is installed (native zsh check - faster than command -v)
if (( $+commands[nix] )); then
    # With Devbox: Use Nix-managed binaries
    _cache_init "zoxide" "/Users/hameldesai/.local/share/devbox/global/default/.devbox/nix/profile/default/bin/zoxide init --cmd cd zsh" || _cache_init "zoxide" "zoxide init --cmd cd zsh"
    _cache_init "starship" "/Users/hameldesai/.local/share/devbox/global/default/.devbox/nix/profile/default/bin/starship init zsh" || _cache_init "starship" "starship init zsh"
else
    # Without Devbox: Use system binaries
    _cache_init "zoxide" "zoxide init --cmd cd zsh"
    _cache_init "starship" "starship init zsh"
fi

export STARSHIP_CONFIG=~/Developer/dotfiles-hd/config/starship/starship.toml

# Defer you-should-use plugin load until after first prompt (saves ~10ms startup)
_load_ysu() {
  unset -f _load_ysu
  source ~/Developer/zsh-you-should-use/you-should-use.plugin.zsh
}
precmd_functions+=(_load_ysu)
