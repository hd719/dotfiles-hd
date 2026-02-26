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

_refresh_devbox_shellenv_cache() {
  local cache_file="$1"
  local tmp_file="${cache_file}.tmp.$$"

  if devbox global shellenv --quiet > "$tmp_file" 2>/dev/null && [[ -s "$tmp_file" ]]; then
    mv "$tmp_file" "$cache_file"
  else
    rm -f "$tmp_file"
  fi
}

_is_valid_devbox_shellenv_cache() {
  local cache_file="$1"
  [[ -s "$cache_file" ]] || return 1

  local line first_nonempty=""
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    first_nonempty="$line"
    break
  done < "$cache_file"

  [[ -n "$first_nonempty" ]] || return 1
  [[ "$first_nonempty" == export\ * || "$first_nonempty" == if\ * ]]
}

_load_devbox_shellenv_cached() {
  local cache_dir="${_ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}"
  local cache_file="${cache_dir}/devbox-shellenv.zsh"
  local refresh_interval_seconds=86400

  [[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"
  command -v devbox >/dev/null 2>&1 || return 0

  if [[ ! -f "$cache_file" ]]; then
    _refresh_devbox_shellenv_cache "$cache_file"
  else
    local cache_mtime
    zstat -A cache_mtime +mtime "$cache_file" 2>/dev/null
    if (( EPOCHSECONDS - cache_mtime > refresh_interval_seconds )); then
      _refresh_devbox_shellenv_cache "$cache_file"
    fi
  fi

  # Guard against plain text status output accidentally cached as shell code.
  if ! _is_valid_devbox_shellenv_cache "$cache_file"; then
    _refresh_devbox_shellenv_cache "$cache_file"
  fi

  if _is_valid_devbox_shellenv_cache "$cache_file"; then
    source "$cache_file"
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

_now_epoch_ms() {
  zmodload zsh/datetime 2>/dev/null
  local -i now_ms=$(( EPOCHREALTIME * 1000 ))
  print -r -- "$now_ms"
}

_format_seconds() {
  local -i seconds="${1:-0}"
  (( seconds < 0 )) && seconds=0
  print -r -- "${seconds}s"
}

_format_epoch_ms_datetime() {
  local -i epoch_ms="${1:-0}"
  (( epoch_ms < 0 )) && epoch_ms=0
  local -i epoch_seconds=$(( epoch_ms / 1000 ))
  date -r "$epoch_seconds" '+%m/%d/%Y %I:%M:%S %p'
}

_get_file_mtime_epoch() {
  local file_path="$1"
  local -a mtime_arr
  zmodload zsh/stat 2>/dev/null
  zstat -A mtime_arr +mtime -- "$file_path" 2>/dev/null || return 1
  [[ -n "${mtime_arr[1]}" ]] || return 1
  print -r -- "${mtime_arr[1]}"
}

_get_marker_last_run_epoch_ms() {
  local marker_file="$1"
  [[ -f "$marker_file" ]] || return 1

  local first_line
  IFS= read -r first_line < "$marker_file" || return 1

  # Legacy format compatibility.
  if [[ "$first_line" == last_run_ms=<-> ]]; then
    print -r -- "${first_line#last_run_ms=}"
    return 0
  fi

  if [[ "$first_line" == <-> ]]; then
    print -r -- "$first_line"
    return 0
  fi

  # Backward compatibility for older marker files: fallback to file mtime.
  local mtime_seconds
  mtime_seconds=$(_get_file_mtime_epoch "$marker_file") || return 1
  print -r -- "$(( mtime_seconds * 1000 ))"
}

_write_marker_last_run_epoch_ms() {
  local marker_file="$1"
  local -i now_ms
  now_ms=$(_now_epoch_ms)
  printf "%d\nLast run: %s\n" "$now_ms" "$(date '+%m/%d/%Y %I:%M:%S %p')" > "$marker_file"
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
  emulate -L zsh
  set +x 2>/dev/null
  setopt typesetsilent

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

  # Some shellenv scripts can toggle tracing; force it back off.
  set +x 2>/dev/null

  local cache_dir="$HOME/.cache/goodmorning"
  mkdir -p "$cache_dir"
  zmodload zsh/stat 2>/dev/null

  # Cooldown: 24 hours - Nix garbage collection
  local -i cooldown_nix_gc_seconds=$(( 24 * 60 * 60 ))
  local marker_file="$cache_dir/nix_gc"
  local run_nix_gc=1
  local nix_gc_elapsed_human=""
  local nix_gc_last_run_human=""
  if [[ -f "$marker_file" ]]; then
    local nix_gc_last_run_epoch_ms
    { nix_gc_last_run_epoch_ms=$(_get_marker_last_run_epoch_ms "$marker_file"); } >/dev/null 2>&1
    if [[ "$nix_gc_last_run_epoch_ms" == <-> ]]; then
      local -i elapsed_ms=$(( $(_now_epoch_ms) - nix_gc_last_run_epoch_ms ))
      (( elapsed_ms < 0 )) && elapsed_ms=0
      local -i elapsed_seconds=$(( elapsed_ms / 1000 ))
      nix_gc_elapsed_human="$(_format_seconds "$elapsed_seconds")"
      nix_gc_last_run_human="$(_format_epoch_ms_datetime "$nix_gc_last_run_epoch_ms")"
      if (( elapsed_seconds < cooldown_nix_gc_seconds )); then
        run_nix_gc=0
      fi
    fi
  fi
  if [[ $run_nix_gc -eq 1 ]]; then
    echo "Cleaning up old Nix generations..."
    if command -v nix-collect-garbage &> /dev/null; then
      nix-collect-garbage --delete-older-than 7d
    else
      echo "nix-collect-garbage not found, skipping."
    fi
    _write_marker_last_run_epoch_ms "$marker_file"
  else
    if [[ -n "$nix_gc_elapsed_human" ]]; then
      echo "Skipping Nix GC (last run: $nix_gc_last_run_human; elapsed: $nix_gc_elapsed_human; cooldown: $(_format_seconds "$cooldown_nix_gc_seconds"))"
    else
      echo "Skipping Nix GC (ran within last 24h)"
    fi
  fi
  echo ""

  echo "Cleaning up Zoom folder..."
  rm -rf "$HOME/Documents/Zoom" &>/dev/null && echo "Deleted: $HOME/Documents/Zoom" || echo "No Zoom directory found at: $HOME/Documents/Zoom"
  echo ""

  # Cooldown: 168 hours (7 days) - Old downloads cleanup
  local -i cooldown_downloads_seconds=$(( 7 * 24 * 60 * 60 ))
  marker_file="$cache_dir/old_downloads"
  local run_downloads=1
  local downloads_elapsed_human=""
  local downloads_last_run_human=""
  if [[ -f "$marker_file" ]]; then
    local downloads_last_run_epoch_ms
    { downloads_last_run_epoch_ms=$(_get_marker_last_run_epoch_ms "$marker_file"); } >/dev/null 2>&1
    if [[ "$downloads_last_run_epoch_ms" == <-> ]]; then
      local -i elapsed_ms=$(( $(_now_epoch_ms) - downloads_last_run_epoch_ms ))
      (( elapsed_ms < 0 )) && elapsed_ms=0
      local -i elapsed_seconds=$(( elapsed_ms / 1000 ))
      downloads_elapsed_human="$(_format_seconds "$elapsed_seconds")"
      downloads_last_run_human="$(_format_epoch_ms_datetime "$downloads_last_run_epoch_ms")"
      if (( elapsed_seconds < cooldown_downloads_seconds )); then
        run_downloads=0
      fi
    fi
  fi
  if [[ $run_downloads -eq 1 ]]; then
    echo "Clearing old Downloads (30+ days)..."
    find ~/Downloads -type f -mtime +30 -delete 2>/dev/null && echo "Done!"
    _write_marker_last_run_epoch_ms "$marker_file"
  else
    if [[ -n "$downloads_elapsed_human" ]]; then
      echo "Skipping Downloads cleanup (last run: $downloads_last_run_human; elapsed: $downloads_elapsed_human; cooldown: $(_format_seconds "$cooldown_downloads_seconds"))"
    else
      echo "Skipping Downloads cleanup (ran within last 7 days)"
    fi
  fi
  echo ""

  # Cooldown: 168 hours (7 days) - .DS_Store cleanup
  local -i cooldown_dsstore_seconds=$(( 7 * 24 * 60 * 60 ))
  marker_file="$cache_dir/dsstore"
  local run_dsstore=1
  local dsstore_elapsed_human=""
  local dsstore_last_run_human=""
  if [[ -f "$marker_file" ]]; then
    local dsstore_last_run_epoch_ms
    { dsstore_last_run_epoch_ms=$(_get_marker_last_run_epoch_ms "$marker_file"); } >/dev/null 2>&1
    if [[ "$dsstore_last_run_epoch_ms" == <-> ]]; then
      local -i elapsed_ms=$(( $(_now_epoch_ms) - dsstore_last_run_epoch_ms ))
      (( elapsed_ms < 0 )) && elapsed_ms=0
      local -i elapsed_seconds=$(( elapsed_ms / 1000 ))
      dsstore_elapsed_human="$(_format_seconds "$elapsed_seconds")"
      dsstore_last_run_human="$(_format_epoch_ms_datetime "$dsstore_last_run_epoch_ms")"
      if (( elapsed_seconds < cooldown_dsstore_seconds )); then
        run_dsstore=0
      fi
    fi
  fi
  if [[ $run_dsstore -eq 1 ]]; then
    echo "Clearing .DS_Store files..."
    find ~ -name ".DS_Store" -type f -delete 2>/dev/null && echo "Done!"
    _write_marker_last_run_epoch_ms "$marker_file"
  else
    if [[ -n "$dsstore_elapsed_human" ]]; then
      echo "Skipping .DS_Store cleanup (last run: $dsstore_last_run_human; elapsed: $dsstore_elapsed_human; cooldown: $(_format_seconds "$cooldown_dsstore_seconds"))"
    else
      echo "Skipping .DS_Store cleanup (ran within last 7 days)"
    fi
  fi
  echo ""

  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
}
