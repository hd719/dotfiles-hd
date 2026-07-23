# Resilience work-Mac maintenance policy.

_resilience_update_repo() {
  emulate -L zsh

  local repo_path="$1"
  local repo_name="$2"
  local branch="${3:-dev}"
  local changes

  if [[ ! -d "$repo_path/.git" ]]; then
    echo "Skipping $repo_name: checkout not found at $repo_path"
    return 1
  fi

  changes="$(git -C "$repo_path" status --porcelain)" || {
    echo "Skipping $repo_name: cannot inspect Git status."
    return 1
  }
  if [[ -n "$changes" ]]; then
    echo "Skipping $repo_name: working tree is not clean."
    return 1
  fi

  echo "****** Pulling $repo_name ******"
  git -C "$repo_path" checkout "$branch" || return 1
  git -C "$repo_path" pull --ff-only origin "$branch"
}

gda() {
  emulate -L zsh

  local result=0
  _resilience_update_repo \
    "$HOME/Developer/Resilience/resilience-platform" \
    "Resilience Platform" || result=1
  _resilience_update_repo \
    "$HOME/Developer/Resilience/resilience-pargasite" \
    "Resilience Pargasite" || result=1
  return "$result"
}

_resilience_brew_cooldown_seconds() {
  print -r -- "$(( 72 * 60 * 60 ))"
}

_resilience_brew_marker() {
  print -r -- "${XDG_CACHE_HOME:-$HOME/.cache}/goodmorning/resilience-homebrew-upgrade"
}

_resilience_brew_cooldown_remaining_seconds() {
  emulate -L zsh

  local marker_file="$1"
  local -i cooldown_seconds="${2:-$(_resilience_brew_cooldown_seconds)}"
  local -i last_run_ms
  local -i now_ms
  local -i elapsed_seconds
  local -i remaining_seconds

  last_run_ms="$(_get_marker_last_run_epoch_ms "$marker_file")" || {
    print -r -- 0
    return 0
  }
  now_ms="$(_now_epoch_ms)"
  elapsed_seconds=$(( (now_ms - last_run_ms) / 1000 ))
  (( elapsed_seconds < 0 )) && elapsed_seconds=0
  remaining_seconds=$(( cooldown_seconds - elapsed_seconds ))
  (( remaining_seconds < 0 )) && remaining_seconds=0
  print -r -- "$remaining_seconds"
}

_resilience_host_is_virtual() {
  [[ "$(hostname)" =~ [Vv]irtual ]]
}

_resilience_run_homebrew_upgrade() {
  emulate -L zsh

  local marker_file="$1"
  local outdated

  command -v brew >/dev/null 2>&1 || {
    echo "Homebrew is unavailable; skipping upgrade."
    return 1
  }

  echo "Updating Homebrew..."
  brew update || return 1
  outdated="$(brew outdated --greedy)" || return 1
  if [[ -n "$outdated" ]]; then
    brew upgrade --greedy || return 1
    brew cleanup || return 1
    brew autoremove || return 1
  else
    echo "No Homebrew packages to upgrade."
  fi

  mkdir -p "${marker_file:h}"
  _write_marker_last_run_epoch_ms "$marker_file"
}

goodMorning() {
  emulate -L zsh

  local skip_brew=0
  local force_brew=0
  local result=0
  local argument
  local marker_file
  local -i remaining_seconds

  for argument in "$@"; do
    case "$argument" in
      --no-brew)
        skip_brew=1
        ;;
      --force-brew)
        force_brew=1
        ;;
      *)
        echo "Usage: goodMorning [--no-brew|--force-brew]"
        return 2
        ;;
    esac
  done
  if (( skip_brew && force_brew )); then
    echo "Choose either --no-brew or --force-brew, not both."
    return 2
  fi

  echo "🙏 Om Shree Ganeshaya Namaha 🙏"

  echo "Syncing hd719 dotfiles..."
  if _goodmorning_sync_dotfiles; then
    echo "Dotfiles are current."
  else
    echo "Dotfiles sync failed; continuing without resetting local changes."
    result=1
  fi

  marker_file="$(_resilience_brew_marker)"
  if _resilience_host_is_virtual; then
    echo "Skipping Homebrew update (virtual environment detected)."
  elif (( skip_brew )); then
    echo "Skipping Homebrew update (--no-brew)."
  else
    remaining_seconds="$(
      _resilience_brew_cooldown_remaining_seconds "$marker_file"
    )"
    if (( force_brew || remaining_seconds == 0 )); then
      _resilience_run_homebrew_upgrade "$marker_file" || {
        echo "Homebrew update failed; the cooldown was not advanced."
        result=1
      }
    else
      echo "Skipping Homebrew update (${remaining_seconds}s remain in the 72-hour cooldown)."
    fi
  fi

  echo "Updating Git repositories..."
  if ! gda; then
    echo "One or more Resilience repositories were not updated."
    result=1
  fi

  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
  return "$result"
}
