#!/usr/bin/env bash
set -euo pipefail

THIN_REPO="${DOTFILES_SYNC_THIN_REPO:-/Users/hameldesai/Developer/dotfiles-hd}"
UBUNTU_REPO="${DOTFILES_SYNC_UBUNTU_REPO:-/home/hamel/Developer/dotfiles-hd}"
MINI_REPO="${DOTFILES_SYNC_MINI_REPO:-/Users/h/Developer/dotfiles-hd}"
SSH_BIN="${DOTFILES_SYNC_SSH_BIN:-ssh}"
SSH_OPTIONS=(-o BatchMode=yes -o ConnectTimeout=8)

die() {
  printf 'sync-dotfiles: %s\n' "$*" >&2
  exit 1
}

remote_git() {
  local host="$1"
  local repo="$2"
  shift 2
  "$SSH_BIN" "${SSH_OPTIONS[@]}" "$host" git -C "$repo" "$@"
}

resolve_remote_host() {
  local label="$1"
  local repo="$2"
  shift 2

  local candidate
  for candidate in "$@"; do
    if "$SSH_BIN" "${SSH_OPTIONS[@]}" "$candidate" \
      test -d "$repo/.git" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  die "$label repo is unreachable through: $*"
}

[[ -d "$THIN_REPO/.git" ]] || die "Thin Mac repo missing: $THIN_REPO"

ubuntu_host="$(
  resolve_remote_host Ubuntu "$UBUNTU_REPO" ubuntu-vm-ts ubuntu-vm
)"
mini_host="$(
  resolve_remote_host "Mac mini" "$MINI_REPO" mac-mini-ts mac-mini-lan
)"

thin_status="$(git -C "$THIN_REPO" status --porcelain)"
[[ -z "$thin_status" ]] || {
  git -C "$THIN_REPO" status -sb >&2
  die "Thin Mac repo is dirty"
}

thin_branch="$(git -C "$THIN_REPO" branch --show-current)"
ubuntu_status="$(
  remote_git "$ubuntu_host" "$UBUNTU_REPO" status --porcelain
)" || die "Cannot inspect Ubuntu status"
[[ -z "$ubuntu_status" ]] || {
  remote_git "$ubuntu_host" "$UBUNTU_REPO" status -sb >&2 || true
  die "Ubuntu repo is dirty"
}

mini_status="$(
  remote_git "$mini_host" "$MINI_REPO" status --porcelain
)" || die "Cannot inspect Mac mini status"
[[ -z "$mini_status" ]] || {
  remote_git "$mini_host" "$MINI_REPO" status -sb >&2 || true
  die "Mac mini repo is dirty"
}

ubuntu_branch="$(
  remote_git "$ubuntu_host" "$UBUNTU_REPO" branch --show-current
)" || die "Cannot inspect Ubuntu branch"
mini_branch="$(
  remote_git "$mini_host" "$MINI_REPO" branch --show-current
)" || die "Cannot inspect Mac mini branch"

git -C "$THIN_REPO" fetch origin master
remote_git "$ubuntu_host" "$UBUNTU_REPO" fetch origin master
remote_git "$mini_host" "$MINI_REPO" fetch origin master

if [[ "$thin_branch" != master ]]; then
  git -C "$THIN_REPO" merge-base --is-ancestor HEAD origin/master \
    || die "Thin Mac branch $thin_branch is not merged into origin/master"
fi
if [[ "$ubuntu_branch" != master ]]; then
  remote_git "$ubuntu_host" "$UBUNTU_REPO" \
    merge-base --is-ancestor HEAD origin/master \
    || die "Ubuntu branch $ubuntu_branch is not merged into origin/master"
fi
if [[ "$mini_branch" != master ]]; then
  remote_git "$mini_host" "$MINI_REPO" \
    merge-base --is-ancestor HEAD origin/master \
    || die "Mac mini branch $mini_branch is not merged into origin/master"
fi

if [[ "$thin_branch" != master ]]; then
  git -C "$THIN_REPO" switch master
fi
if [[ "$ubuntu_branch" != master ]]; then
  remote_git "$ubuntu_host" "$UBUNTU_REPO" switch master
fi
if [[ "$mini_branch" != master ]]; then
  remote_git "$mini_host" "$MINI_REPO" switch master
fi

git -C "$THIN_REPO" pull --ff-only origin master
remote_git "$ubuntu_host" "$UBUNTU_REPO" pull --ff-only origin master
remote_git "$mini_host" "$MINI_REPO" pull --ff-only origin master

thin_branch="$(git -C "$THIN_REPO" branch --show-current)"
ubuntu_branch="$(remote_git "$ubuntu_host" "$UBUNTU_REPO" branch --show-current)"
mini_branch="$(remote_git "$mini_host" "$MINI_REPO" branch --show-current)"
[[ "$thin_branch" == master && "$ubuntu_branch" == master && "$mini_branch" == master ]] \
  || die "One or more repos left master after syncing"

thin_status="$(git -C "$THIN_REPO" status --porcelain)"
ubuntu_status="$(remote_git "$ubuntu_host" "$UBUNTU_REPO" status --porcelain)"
mini_status="$(remote_git "$mini_host" "$MINI_REPO" status --porcelain)"
[[ -z "$thin_status" && -z "$ubuntu_status" && -z "$mini_status" ]] \
  || die "One or more repos are dirty after syncing"

thin_head="$(git -C "$THIN_REPO" rev-parse HEAD)"
ubuntu_head="$(remote_git "$ubuntu_host" "$UBUNTU_REPO" rev-parse HEAD)"
mini_head="$(remote_git "$mini_host" "$MINI_REPO" rev-parse HEAD)"
[[ "$thin_head" == "$ubuntu_head" && "$thin_head" == "$mini_head" ]] || {
  printf 'Thin Mac: %s\nUbuntu:  %s\nMac mini: %s\n' \
    "$thin_head" "$ubuntu_head" "$mini_head" >&2
  die "Repos do not match after syncing"
}

printf 'Thin Mac: master %s\n' "$thin_head"
printf 'Ubuntu:  master %s via %s\n' "$ubuntu_head" "$ubuntu_host"
printf 'Mac mini: master %s via %s\n' "$mini_head" "$mini_host"
printf 'All dotfiles repos match.\n'
