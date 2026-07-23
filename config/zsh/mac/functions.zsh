# [Shared Mac Functions]
# --------------------------------------------------------------------------------------------------------

_load_homebrew_plugin() {
  local plugin_path="$1"
  [[ -r "$plugin_path" ]] || return 0
  source "$plugin_path"
}

_activate_mise() {
  local mise_bin
  mise_bin="$(command -v mise 2>/dev/null)" || return 0
  eval "$("$mise_bin" activate zsh)"
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

_run_with_timeout() {
  emulate -L zsh
  unsetopt monitor notify
  local -i timeout_seconds="$1"
  shift

  (( timeout_seconds > 0 && $# > 0 )) || return 2
  zmodload zsh/zselect 2>/dev/null || return 125

  "$@" &
  local -i command_pid=$!
  (
    zselect -t $(( timeout_seconds * 100 ))
    kill -TERM "$command_pid" 2>/dev/null
    zselect -t 200
    kill -KILL "$command_pid" 2>/dev/null
  ) &
  local -i timer_pid=$!

  wait "$command_pid"
  local -i exit_status=$?
  kill -TERM "$timer_pid" 2>/dev/null
  wait "$timer_pid" 2>/dev/null
  return "$exit_status"
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

_goodmorning_sync_dotfiles() {
  emulate -L zsh

  local dotfiles_dir="$HOME/Developer/dotfiles-hd"
  local expected_origin="git@github.com:hd719/dotfiles-hd.git"
  local origin_url

  if ! command -v git &>/dev/null; then
    echo "Git not found; skipping dotfiles sync."
    return 1
  fi

  if [[ ! -d "$dotfiles_dir/.git" ]]; then
    echo "Dotfiles checkout not found at: $dotfiles_dir"
    return 1
  fi

  origin_url="$(git -C "$dotfiles_dir" remote get-url origin 2>/dev/null)" || {
    echo "Dotfiles origin is unavailable; skipping sync."
    return 1
  }

  if [[ "$origin_url" != "$expected_origin" ]]; then
    echo "Dotfiles origin is not hd719/dotfiles-hd; skipping sync: $origin_url"
    return 1
  fi

  git -C "$dotfiles_dir" pull --ff-only origin master
}
