#!/bin/sh
set -eu

mode="${1:---preview}"
version="${CHEZMOI_VERSION:-v2.72.0}"
source_dir="${CHEZMOI_SOURCE_DIR:-/tmp/chezmoi-source}"

case "$(uname -s)" in Linux | Darwin) ;; *) echo "unsupported OS" >&2; exit 1 ;; esac
case "$mode" in --preview | --apply) ;; *) echo "usage: $0 --preview|--apply" >&2; exit 2 ;; esac

bin="$HOME/.local/bin/chezmoi"
if [ ! -x "$bin" ]; then
  mkdir -p "$HOME/.local/bin"
  sh -c "$(curl -fsLS https://get.chezmoi.io)" -- \
    -b "$HOME/.local/bin" -t "$version"
fi

"$bin" --source "$source_dir" init
"$bin" --source "$source_dir" diff --no-pager
if [ "$mode" = "--apply" ]; then
  "$bin" --source "$source_dir" apply --force --no-tty
fi
