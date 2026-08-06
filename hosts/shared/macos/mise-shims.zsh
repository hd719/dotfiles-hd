# Loaded by the marker-owned block in ~/.zprofile.
# Login shells and IDE-launched terminals need shims because .zshrc is
# interactive-only. Plain scripts and LaunchAgents must use `mise exec` or an
# explicit binary path.

typeset -gaU path
path=(
  "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
  "${XDG_BIN_HOME:-$HOME/.local/bin}"
  $path
)
export PATH
