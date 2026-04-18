# [Functions]
# --------------------------------------------------------------------------------------------------------

_load_homebrew_plugin() {
  local plugin_path="$1"
  [[ -r "$plugin_path" ]] || return 0
  source "$plugin_path"
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

  echo "Checking mise toolchain..."
  if command -v mise &> /dev/null; then
    mise install
    echo ""
    echo "Active mise runtimes:"
    mise ls
  else
    echo "mise not found, skipping."
  fi
  echo ""

  # Some shellenv scripts can toggle tracing; force it back off.
  set +x 2>/dev/null

  local cache_dir="$HOME/.cache/goodmorning"
  mkdir -p "$cache_dir"
  zmodload zsh/stat 2>/dev/null

  echo "Cleaning up Zoom folder..."
  rm -rf "$HOME/Documents/Zoom" &>/dev/null && echo "Deleted: $HOME/Documents/Zoom" || echo "No Zoom directory found at: $HOME/Documents/Zoom"
  echo ""

  # Cooldown: 168 hours (7 days) - Old downloads cleanup
  local -i cooldown_downloads_seconds=$(( 7 * 24 * 60 * 60 ))
  local marker_file="$cache_dir/old_downloads"
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
