# [Personal Mac Functions]
# --------------------------------------------------------------------------------------------------------

carchive() {
  emulate -L zsh

  local state_db="$HOME/.codex/state_5.sqlite"
  local session_index="$HOME/.codex/session_index.jsonl"
  local jq_bin
  local selected session_id updated_at title cwd confirmation

  if ! command -v codex >/dev/null 2>&1; then
    echo "Codex CLI is not installed."
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is not installed."
    return 1
  fi

  jq_bin="$(command -v jq 2>/dev/null)" || {
    echo "jq is not installed."
    return 1
  }

  if [[ ! -f "$state_db" ]]; then
    echo "Codex session database not found: $state_db"
    return 1
  fi

  if [[ ! -f "$session_index" ]]; then
    echo "Codex session name index not found: $session_index"
    return 1
  fi

  selected=$(
    /usr/bin/awk -F $'\t' -v OFS=$'\t' '
      FNR == NR {
        names[$1] = $2
        next
      }
      {
        title = (($1 in names) ? names[$1] : $3)
        gsub(/[\r\n\t]/, " ", title)
        if (length(title) > 100) {
          title = substr(title, 1, 97) "..."
        }
        print $1, $2, title, $4
      }
    ' \
      <("$jq_bin" -rs '
        reduce .[] as $row ({};
          if ($row.id? and $row.thread_name?) then
            .[$row.id] = ($row.thread_name | gsub("[\\t\\r\\n]"; " "))
          else
            .
          end
        )
        | to_entries[]
        | [.key, .value]
        | @tsv
      ' "$session_index") \
      <(/usr/bin/sqlite3 -readonly -separator $'\t' "$state_db" "
        SELECT
          id,
          datetime(recency_at, 'unixepoch', 'localtime'),
          replace(replace(replace(title, char(9), ' '), char(10), ' '), char(13), ' '),
          cwd
        FROM threads
        WHERE archived = 0
          AND source = 'vscode'
          AND preview <> ''
        ORDER BY recency_at_ms DESC;
      ") | fzf \
      --delimiter=$'\t' \
      --with-nth=2,3,4 \
      --prompt='Archive Codex chat > ' \
      --header='Updated | Title | Folder' \
      --height=80% \
      --layout=reverse \
      --border
  ) || return 0

  [[ -n "$selected" ]] || return 0
  IFS=$'\t' read -r session_id updated_at title cwd <<< "$selected"

  printf "Archive '%s'? [y/N] " "$title"
  read -r confirmation
  [[ "$confirmation" == [yY] ]] || {
    echo "Cancelled."
    return 0
  }

  codex archive "$session_id"
}

goodMorning() {
  emulate -L zsh
  set +x 2>/dev/null
  setopt typesetsilent

  echo ""
  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
  echo ""

  echo "Syncing hd719 dotfiles..."
  if _goodmorning_sync_dotfiles; then
    echo "Dotfiles are current."
  else
    echo "Dotfiles sync failed; continuing without resetting local changes."
  fi
  echo ""

  echo "Refreshing Homebrew metadata..."
  if command -v brew &> /dev/null; then
    brew update
    echo "Broad upgrades and cleanup are paused while runtime fallbacks are retained."
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
  local -i cleanup_timeout_seconds=30
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
    if _run_with_timeout "$cleanup_timeout_seconds" /usr/bin/find -x "$HOME/Downloads" -type f -mtime +30 -delete 2>/dev/null; then
      echo "Done!"
      _write_marker_last_run_epoch_ms "$marker_file"
    else
      echo "Downloads cleanup failed or timed out after ${cleanup_timeout_seconds}s; it will retry next run."
    fi
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
    if _run_with_timeout "$cleanup_timeout_seconds" /usr/bin/find -x "$HOME" -name ".DS_Store" -type f -delete 2>/dev/null; then
      echo "Done!"
      _write_marker_last_run_epoch_ms "$marker_file"
    else
      echo ".DS_Store cleanup failed or timed out after ${cleanup_timeout_seconds}s; it will retry next run."
    fi
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

unalias opmission opmissiondev 2>/dev/null

opmission() {
  local pids
  pids=$(lsof -tiTCP:3000 -sTCP:LISTEN -c ssh 2>/dev/null)
  [[ -n "$pids" ]] && kill $pids
  ssh -fN -o ExitOnForwardFailure=yes -L '[::1]:3000:127.0.0.1:3000' hd@100.120.198.12
  open 'http://localhost:3000'
}

opmissiondev() {
  local pids
  pids=$(lsof -tiTCP:3001 -sTCP:LISTEN -c ssh 2>/dev/null)
  [[ -n "$pids" ]] && kill $pids
  ssh -fN -o ExitOnForwardFailure=yes -L '[::1]:3001:127.0.0.1:3001' hd@100.120.198.12
  open 'http://localhost:3001'
}
