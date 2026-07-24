# Portable functions shared by Mac and Linux profiles.

reload() {
  emulate -L zsh

  zmodload zsh/datetime 2>/dev/null
  local start_time="$EPOCHREALTIME"
  source "$HOME/.zshrc"
  local end_time="$EPOCHREALTIME"
  local duration=$(( (end_time - start_time) * 1000 ))

  printf "Zsh configuration reloaded in %.0fms\n" "$duration"
}
