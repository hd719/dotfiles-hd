# [Personal Mac Development Functions]
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

_goodmorning_run_mac_mini_maintenance() {
  emulate -L zsh

  local runner="$HOME/.hermes/skills/home-lab-maintenance/scripts/mac-mini-maintenance.sh"
  local report=""

  if [[ ! -x "$runner" ]]; then
    echo "Mac mini maintenance runner is missing: $runner"
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required for Mac mini maintenance."
    return 1
  fi

  report="$("$runner" --dry-run)"
  if (( $? != 0 )); then
    echo "Mac mini maintenance preflight blocked:"
    print -r -- "$report" | jq -r '.failed[]?.message'
    return 1
  fi

  if print -r -- "$report" | jq -e '
      any(.events[];
        .status == "available"
        and (
          (.category == "homebrew" and .item == "packages")
          or (.category == "git" and (.item == "dotfiles" or .item == "cortana_services"))
        )
      )
    ' >/dev/null; then
    echo "Mac mini updates are available; applying the guarded maintenance workflow..."
    report="$("$runner" --apply)"
    if (( $? != 0 )); then
      echo "Mac mini maintenance failed:"
      print -r -- "$report" | jq -r '.failed[]?.message'
      return 1
    fi
    print -r -- "$report" | jq -r '.updated[]?.message'
  else
    echo "Mac mini packages and tracked runtime repositories are current."
  fi

  print -r -- "$report" | jq -r '.warnings[]?.message | "Note: \(.)"'
}

goodMorning() {
  emulate -L zsh
  set +x 2>/dev/null
  setopt typesetsilent

  local mode="${1:-}"
  local -i result=0
  local -i homebrew_ready=1
  local -i maintenance_checked=0
  local -i updates_only=0
  local dotfiles_head_before=""
  local dotfiles_head_after=""

  if (( $# > 1 )); then
    echo "Usage: goodMorning [--updates-only]"
    return 2
  fi
  case "$mode" in
    "") ;;
    --updates-only) updates_only=1 ;;
    *)
      echo "Usage: goodMorning [--updates-only]"
      return 2
      ;;
  esac

  echo ""
  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
  echo ""

  echo "Syncing hd719 dotfiles..."
  dotfiles_head_before="$(git -C "$HOME/Developer/dotfiles-hd" rev-parse HEAD 2>/dev/null)"
  if _goodmorning_sync_dotfiles; then
    echo "Dotfiles are current."
    dotfiles_head_after="$(git -C "$HOME/Developer/dotfiles-hd" rev-parse HEAD 2>/dev/null)"
  else
    echo "Dotfiles sync failed; continuing without resetting local changes."
    result=1
  fi
  echo ""

  # A pull can replace this function while the current shell still holds the
  # old definition. Reload once so future maintenance always runs tracked code.
  if [[ -n "$dotfiles_head_before" && -n "$dotfiles_head_after" \
    && "$dotfiles_head_before" != "$dotfiles_head_after" \
    && "${DOTFILES_GOODMORNING_RELOADED:-0}" != 1 ]]; then
    echo "Dotfiles changed; reloading goodMorning from a fresh login shell..."
    if (( updates_only == 1 )); then
      DOTFILES_GOODMORNING_RELOADED=1 /bin/zsh -lic 'goodMorning --updates-only'
    else
      DOTFILES_GOODMORNING_RELOADED=1 /bin/zsh -lic 'goodMorning'
    fi
    return $?
  fi

  echo "Refreshing Homebrew metadata..."
  if command -v brew &> /dev/null; then
    if ! brew update; then
      echo "Homebrew metadata refresh failed."
      homebrew_ready=0
      result=1
    elif [[ "${DOTFILES_MAC_PROFILE:-}" == "mac-mini" ]]; then
      if ! _goodmorning_run_mac_mini_maintenance; then
        result=1
      else
        maintenance_checked=1
      fi
    else
      echo "Broad upgrades and cleanup are paused while runtime fallbacks are retained."
    fi
  else
    echo "Homebrew not found, skipping."
    homebrew_ready=0
    result=1
  fi
  echo ""

  echo "Checking mise toolchain..."
  if [[ "${DOTFILES_MAC_PROFILE:-}" == "mac-mini" ]]; then
    if (( homebrew_ready == 0 )); then
      echo "Mac mini maintenance was skipped because Homebrew is not ready."
    elif (( maintenance_checked == 0 )); then
      echo "Mac mini maintenance did not complete; review the error above."
    else
      echo "The guarded Mac mini maintenance runner checked the pinned runtime toolchain."
    fi
  elif command -v mise &> /dev/null; then
    mise install
    echo ""
    echo "Active mise runtimes:"
    mise ls
  else
    echo "mise not found, skipping."
  fi
  echo ""

  if (( updates_only == 1 )); then
    echo "Update-only mode complete; personal cleanup was not run."
    echo ""
    echo "🙏 Om Shree Ganeshaya Namaha 🙏"
    return $result
  fi

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
  return $result
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
