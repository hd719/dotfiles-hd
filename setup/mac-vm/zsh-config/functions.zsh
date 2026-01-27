# [Functions]
# --------------------------------------------------------------------------------------------------------

# Nix plugin loader with simple path cache (cache dir created in prompt.zsh)
_get_cached_nix_plugin() {
  local plugin_name="$1"
  local cache_file="$_ZSH_CACHE_DIR/nix-$plugin_name-path"

  if [[ -f "$cache_file" ]]; then
    local cached_path
    read -r cached_path < "$cache_file" 2>/dev/null
    if [[ -r "$cached_path" ]]; then
      echo "$cached_path"
      return 0
    fi
  fi

  return 1
}

_load_nix_plugin() {
  local plugin_name="$1"
  local cached_path="$(_get_cached_nix_plugin "$plugin_name")"

  if [[ -n "$cached_path" && -r "$cached_path" ]]; then
    source "$cached_path"
  else
    local glob_pattern="/nix/store/*-$plugin_name-*/share/$plugin_name/$plugin_name.zsh"
    local found=($~glob_pattern(N[1]))
    if [[ -n "$found" && -r "$found" ]]; then
      source "$found"
      echo "$found" > "$_ZSH_CACHE_DIR/nix-$plugin_name-path"
    fi
  fi
}

reload() {
  # Use zsh's EPOCHREALTIME for millisecond precision (macOS compatible)
  zmodload zsh/datetime 2>/dev/null
  local start_time=$EPOCHREALTIME
  source ~/.zshrc
  local end_time=$EPOCHREALTIME
  local duration=$(( (end_time - start_time) * 1000 ))
  printf "Zsh configuration reloaded in %.0fms\n" $duration
}

killport() {
    if [[ $# -ne 1 ]]; then
        echo "Add a port number to kill the process on that port. Example: killport 3000"
        return 1
    fi

    local port="$1"
    local pid=$(lsof -ti tcp:"$port")

    if [[ -z $pid ]]; then
        echo "No process found on port $port"
        return 1
    else
        echo "Killing process on port $port"
        echo "$pid" | xargs kill -9
    fi
}

show_ports() {
    # Check if lsof is installed
    if ! command -v lsof &> /dev/null; then
        echo "Error: lsof is not installed. Please install it and try again."
        return 1
    fi

    # Fetch port usage data
    PORTS=$(lsof -i -P -n | awk 'NR>1 {print $9, $1}' | awk -F: '{if (NF>1) print $2, $1}' | sort -n | uniq -c | sort -nr)

    # Check if any ports are in use
    if [[ -z "$PORTS" ]]; then
        echo "No active ports found."
        return 0
    fi

    # Format and display as a chart
    echo "\nActive Ports and Associated Processes:\n"
    echo "Count   Port   Process"
    echo "--------------------------------"
    echo "$PORTS" | column -t
}

check_ports() {
  local suspicious_ports=("22" "3283" "5900" "5000" "7000" "63743")
  local open_ports=$(netstat -an | grep LISTEN | awk '{print $4}' | awk -F. '{print $NF}' | sort -u)
  local found=()

  for port in "${suspicious_ports[@]}"; do
    if echo "$open_ports" | grep -q "^$port$"; then
      found+=("$port")
    fi
  done

  if [[ ${#found[@]} -eq 0 ]]; then
    echo "No suspicious ports open."
  else
    echo "Suspicious ports open: ${found[*]}"
  fi
}

nix-gen-map() {
  echo "Generation -> Nix Store Path + Size:"
  printf "%-12s %-70s %10s\n" "Generation" "Store Path" "Size"
  echo "-----------------------------------------------------------------------------------------------"
  sudo -H nix-env --list-generations --profile /nix/var/nix/profiles/system | while read gen rest; do
    link="/nix/var/nix/profiles/system-${gen}-link"
    if [[ -L "$link" ]]; then
      target=$(readlink "$link")
      if [[ -n "$target" && -e "$target" ]]; then
        size_kb=$(du -sk "$target" | awk '{print $1}')
        printf "%-12s %-70s %10sK\n" "$gen" "$target" "$size_kb"
      fi
    fi
  done
}

nix-gen-map-devbox() {
  local profile="$HOME/.local/share/devbox/global/default/.devbox/nix/profile/default"
  if [[ ! -e "$profile" ]]; then
    echo "Devbox global profile not found at: $profile"
    return 1
  fi

  local profile_dir="${profile%/*}"
  local base="${profile##*/}"

  echo "Generation -> Nix Store Path + Size (Devbox Global):"
  printf "%-12s %-70s %10s\n" "Generation" "Store Path" "Size"
  echo "-----------------------------------------------------------------------------------------------"
  nix-env --list-generations --profile "$profile" | while read gen rest; do
    link="$profile_dir/${base}-${gen}-link"
    if [[ -L "$link" ]]; then
      target=$(readlink "$link")
      if [[ -n "$target" && -e "$target" ]]; then
        size_kb=$(du -sk "$target" | awk '{print $1}')
        size_gb=$(awk -v kb="$size_kb" 'BEGIN { printf "%.2fGB", kb/1024/1024 }')
        printf "%-12s %-70s %10s\n" "$gen" "$target" "$size_gb"
      fi
    fi
  done
}

nix-gen-size() {
  for link in /nix/var/nix/profiles/system-*-link; do
    target=$(readlink "$link")
    if [[ -n "$target" && -e "$target" ]]; then
      du -sh "$target"
    fi
  done
}

goodMorning() {
  echo ""
  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
  echo ""

  echo "Updating Homebrew..."
  if command -v brew &> /dev/null; then
    brew update && brew upgrade
    echo ""
    echo "Cleaning up Homebrew..."
    brew cleanup && brew autoremove
  else
    echo "Homebrew not found, skipping."
  fi
  echo ""

  echo "Upgrading Devbox"
  if command -v devbox &> /dev/null; then
    devbox version update
    echo ""
    echo "Updating Devbox global nix packages"
    devbox global update
    echo "Refreshing Packages"
    eval "$(devbox global shellenv --preserve-path-stack -r)" && hash -r
  else
    echo "Devbox not found, skipping."
  fi
  echo ""

  echo "Checking for Nix updates..."
  if command -v determinate-nixd &> /dev/null; then
    determinate-nixd version
  else
    echo "determinate-nixd not found, skipping."
  fi
  echo ""

  local cache_dir="$HOME/.cache/goodmorning"
  mkdir -p "$cache_dir"
  zmodload zsh/stat 2>/dev/null

  # Cooldown: 24 hours - Nix garbage collection
  local marker_file="$cache_dir/nix_gc"
  local run_nix_gc=1
  if [[ -f "$marker_file" ]]; then
    local last_run
    zstat -A last_run +mtime "$marker_file" 2>/dev/null
    local hours_since=$(( (EPOCHSECONDS - last_run) / 3600 ))
    if [[ $hours_since -lt 24 ]]; then
      run_nix_gc=0
    fi
  fi
  if [[ $run_nix_gc -eq 1 ]]; then
    echo "Cleaning up old Nix generations..."
    if command -v nix-collect-garbage &> /dev/null; then
      nix-collect-garbage --delete-older-than 7d
    else
      echo "nix-collect-garbage not found, skipping."
    fi
    echo "Last run: $(date '+%Y-%m-%d %H:%M:%S')" > "$marker_file"
  else
    echo "Skipping Nix GC (ran within last 24h)"
  fi
  echo ""

  echo "Cleaning up Zoom folder..."
  rm -rf "$HOME/Documents/Zoom" &>/dev/null && echo "Deleted: $HOME/Documents/Zoom" || echo "No Zoom directory found at: $HOME/Documents/Zoom"
  echo ""

  # Cooldown: 168 hours (7 days) - Old downloads cleanup
  marker_file="$cache_dir/old_downloads"
  local run_downloads=1
  if [[ -f "$marker_file" ]]; then
    local last_run
    zstat -A last_run +mtime "$marker_file" 2>/dev/null
    local hours_since=$(( (EPOCHSECONDS - last_run) / 3600 ))
    if [[ $hours_since -lt 168 ]]; then
      run_downloads=0
    fi
  fi
  if [[ $run_downloads -eq 1 ]]; then
    echo "Clearing old Downloads (30+ days)..."
    find ~/Downloads -type f -mtime +30 -delete 2>/dev/null && echo "Done!"
    echo "Last run: $(date '+%Y-%m-%d %H:%M:%S')" > "$marker_file"
  else
    echo "Skipping Downloads cleanup (ran within last 7 days)"
  fi
  echo ""

  # Cooldown: 168 hours (7 days) - .DS_Store cleanup
  marker_file="$cache_dir/dsstore"
  local run_dsstore=1
  if [[ -f "$marker_file" ]]; then
    local last_run
    zstat -A last_run +mtime "$marker_file" 2>/dev/null
    local hours_since=$(( (EPOCHSECONDS - last_run) / 3600 ))
    if [[ $hours_since -lt 168 ]]; then
      run_dsstore=0
    fi
  fi
  if [[ $run_dsstore -eq 1 ]]; then
    echo "Clearing .DS_Store files..."
    find ~ -name ".DS_Store" -type f -delete 2>/dev/null && echo "Done!"
    echo "Last run: $(date '+%Y-%m-%d %H:%M:%S')" > "$marker_file"
  else
    echo "Skipping .DS_Store cleanup (ran within last 7 days)"
  fi
  echo ""

  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
}
