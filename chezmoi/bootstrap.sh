#!/bin/sh
set -eu

profile="${1:-}"; mode="${2:---preview}"
version="v2.72.0"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
bin="${CHEZMOI_BIN:-$HOME/.local/bin/chezmoi}"

case "$profile:$mode" in
  ubuntu:--preview|ubuntu:--apply|mac-thin:--preview|mac-thin:--apply|mac-mini:--preview|mac-mini:--apply|work-mac:--preview|work-mac:--apply) ;;
  *) echo "usage: $0 ubuntu|mac-thin|mac-mini|work-mac --preview|--apply" >&2; exit 2 ;;
esac
case "$profile:$(uname -s)" in
  ubuntu:Linux|mac-thin:Darwin|mac-mini:Darwin|work-mac:Darwin) ;;
  *) [ "${DOTFILES_CHEZMOI_TEST:-0}" = 1 ] || { echo "profile/OS mismatch" >&2; exit 1; } ;;
esac
if [ ! -x "$bin" ]; then
  mkdir -p "$(dirname "$bin")"
  sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$(dirname "$bin")" -t "$version"
fi
installed_version="$("$bin" --version 2>/dev/null || true)"
case "$installed_version" in
  *"version $version,"*) ;; *) echo "chezmoi $version is required: $bin" >&2; exit 1 ;;
esac
CHEZMOI_BIN="$bin" exec "$script_dir/${mode#--}.sh" "$profile"
