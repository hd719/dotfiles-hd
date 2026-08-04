# Personal Mac Codex workflows.

carchive() {
  emulate -L zsh

  local state_db="$HOME/.codex/state_5.sqlite"
  local session_index="$HOME/.codex/session_index.jsonl"
  local jq_bin
  local rows selected session_id updated_at title cwd confirmation selection
  local -a session_rows
  local -i index

  if ! command -v codex >/dev/null 2>&1; then
    echo "Codex CLI is not installed."
    return 1
  fi

  if (( $# > 0 )); then
    codex archive "$@"
    return
  fi

  if [[ ! -f "$state_db" ]]; then
    echo "Codex session database not found: $state_db"
    return 1
  fi

  rows=$(
    /usr/bin/sqlite3 -readonly -separator $'\t' "$state_db" "
      SELECT
        id,
        datetime(recency_at, 'unixepoch', 'localtime'),
        CASE
          WHEN length(title) > 100 THEN
            substr(
              replace(replace(replace(title, char(9), ' '), char(10), ' '), char(13), ' '),
              1,
              97
            ) || '...'
          ELSE
            replace(replace(replace(title, char(9), ' '), char(10), ' '), char(13), ' ')
        END,
        cwd
      FROM threads
      WHERE archived = 0
        AND source = 'vscode'
        AND preview <> ''
      ORDER BY recency_at_ms DESC;
    "
  ) || return 1

  if [[ -f "$session_index" ]] \
    && jq_bin="$(command -v jq 2>/dev/null)"; then
    rows=$(
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
        <(print -r -- "$rows")
    ) || return 1
  fi

  if [[ -z "$rows" ]]; then
    echo "No active Codex chats found."
    return 0
  fi

  if command -v fzf >/dev/null 2>&1; then
    selected=$(print -r -- "$rows" | fzf \
      --delimiter=$'\t' \
      --with-nth=2,3,4 \
      --prompt='Archive Codex chat > ' \
      --header='Updated | Title | Folder' \
      --height=80% \
      --layout=reverse \
      --border) || return 0
  else
    session_rows=("${(@f)rows}")
    echo "Active Codex chats:"
    for index in {1..${#session_rows}}; do
      IFS=$'\t' read -r session_id updated_at title cwd <<< "${session_rows[$index]}"
      printf '%2d) %s | %s | %s\n' "$index" "$updated_at" "$title" "$cwd"
    done

    while true; do
      printf "Select a chat number, or q to cancel: "
      if ! read -r selection; then
        printf '\nCancelled.\n'
        return 0
      fi
      [[ "$selection" == [qQ] ]] && return 0
      if [[ "$selection" == <-> ]] \
        && (( selection >= 1 && selection <= ${#session_rows} )); then
        selected="${session_rows[$selection]}"
        break
      fi
      echo "Invalid selection."
    done
  fi

  IFS=$'\t' read -r session_id updated_at title cwd <<< "$selected"
  printf "Archive '%s'? [y/N] " "$title"
  read -r confirmation
  [[ "$confirmation" == [yY] ]] || {
    echo "Cancelled."
    return 0
  }

  codex archive "$session_id"
}

unalias coda 2>/dev/null
coda() {
  carchive "$@"
}
