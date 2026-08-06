#!/bin/sh
set -eu

mode="${1:---preview}"
version="${CHEZMOI_VERSION:-v2.72.0}"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source_dir="$script_dir/source"
bin="$HOME/.local/bin/chezmoi"

[ "$(uname -s)" = Darwin ] || { echo "macOS required" >&2; exit 1; }
case "$mode" in --preview | --apply) ;; *) echo "usage: $0 --preview|--apply" >&2; exit 2 ;; esac

if [ ! -x "$bin" ]; then
  mkdir -p "$HOME/.local/bin"
  sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin" -t "$version"
fi

"$bin" --source "$source_dir" init
"$bin" --source "$source_dir" diff --no-pager
[ "$mode" = --preview ] || "$bin" --source "$source_dir" apply --force --no-tty
