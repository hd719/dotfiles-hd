#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CHEZMOI_DIR="$(cd "$TEST_DIR/.." && pwd -P)"
REPO_DIR="$(cd "$CHEZMOI_DIR/.." && pwd -P)"
CHEZMOI_BIN="${CHEZMOI_BIN:-}"
[[ -x "$CHEZMOI_BIN" ]] || {
  printf 'Set CHEZMOI_BIN to a chezmoi 2.72.0 binary.\n' >&2
  exit 2
}

case "$($CHEZMOI_BIN --version)" in
  *'version v2.72.0'*) ;;
  *) printf 'chezmoi 2.72.0 is required.\n' >&2; exit 1 ;;
esac

case_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-chezmoi-test.XXXXXX")"
trap 'rm -rf "$case_dir"' EXIT

for script in "$CHEZMOI_DIR"/*.sh; do
  bash -n "$script"
done
[[ "$(wc -l < "$CHEZMOI_DIR/bootstrap.sh" | tr -d ' ')" -le 25 ]]

bootstrap_home="$case_dir/bootstrap/home"
bootstrap_bin="$case_dir/bootstrap/chezmoi"
mkdir -p "$bootstrap_home"
cat > "$bootstrap_bin" <<'EOF'
#!/bin/sh
if [ "${1:-}" = --version ]; then
  printf 'chezmoi version %s, test build\n' "${FAKE_CHEZMOI_VERSION:-v2.72.0}"
fi
EOF
chmod +x "$bootstrap_bin"
HOME="$bootstrap_home" \
  DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$bootstrap_bin" \
  FAKE_CHEZMOI_VERSION=v2.72.0 \
  bash "$CHEZMOI_DIR/bootstrap.sh" mac-mini --preview \
  > "$case_dir/bootstrap-correct.log"
set +e
bootstrap_wrong_output="$({
  HOME="$bootstrap_home" \
    DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$bootstrap_bin" \
    FAKE_CHEZMOI_VERSION=v2.71.0 \
    bash "$CHEZMOI_DIR/bootstrap.sh" mac-mini --preview
} 2>&1)"
bootstrap_wrong_status=$?
set -e
((bootstrap_wrong_status != 0))
[[ "$bootstrap_wrong_output" == *"chezmoi v2.72.0 is required"* ]]

checkout_home="$case_dir/reviewed-checkout/home"
checkout_repo="$checkout_home/Developer/dotfiles-hd"
mkdir -p "$checkout_repo"
git -C "$checkout_repo" init -q -b master
git -C "$checkout_repo" config user.name test
git -C "$checkout_repo" config user.email test@example.com
printf 'reviewed\n' > "$checkout_repo/README.md"
git -C "$checkout_repo" add README.md
git -C "$checkout_repo" commit -q -m reviewed
git -C "$checkout_repo" remote add origin \
  git@github.com:hd719/dotfiles-hd.git
git -C "$checkout_repo" update-ref refs/remotes/origin/master HEAD

require_reviewed_checkout() {
  HOME="$checkout_home" DOTFILES_CHEZMOI_TEST=0 \
    bash -c '
      source "$1/lib.sh"
      REPO_DIR="$2"
      DEST_DIR="$HOME"
      BACKUP_ROOT="$HOME/.local/state/dotfiles-hd/chezmoi-backups"
      require_canonical_checkout
    ' _ "$CHEZMOI_DIR" "$checkout_repo"
}

require_reviewed_checkout
git -C "$checkout_repo" remote set-url origin \
  git@github.com:someone-else/dotfiles-hd.git
set +e
checkout_output="$(require_reviewed_checkout 2>&1)"
checkout_status=$?
set -e
((checkout_status != 0))
[[ "$checkout_output" == *"apply requires canonical origin"* ]]
git -C "$checkout_repo" remote set-url origin \
  git@github.com:hd719/dotfiles-hd.git
git -C "$checkout_repo" commit -q --allow-empty -m unreviewed
set +e
checkout_output="$(require_reviewed_checkout 2>&1)"
checkout_status=$?
set -e
((checkout_status != 0))
[[ "$checkout_output" == *"master does not match origin/master"* ]]

for profile in ubuntu mac-thin mac-mini work-mac; do
  home_dir="$case_dir/$profile/home"
  state_dir="$case_dir/$profile/state"
  mkdir -p "$home_dir" "$state_dir"
  common=(
    --source "$CHEZMOI_DIR/source"
    --config "$CHEZMOI_DIR/profiles/$profile.toml"
    --destination "$home_dir"
    --persistent-state "$state_dir/$profile.boltdb"
  )

  cut -d '|' -f 1 "$CHEZMOI_DIR/profiles/$profile.paths" | sort \
    > "$case_dir/$profile.expected"
  "$CHEZMOI_BIN" "${common[@]}" managed \
    --include=symlinks --path-style=relative | sort \
    > "$case_dir/$profile.managed"
  diff -u "$case_dir/$profile.expected" "$case_dir/$profile.managed"

  case "$profile" in
    ubuntu) printf '%s\n' 10-configure-git.sh 20-install-ubuntu-tools.sh ;;
    mac-thin) printf '%s\n' 10-configure-git.sh 30-install-thin-tools.sh ;;
    mac-mini) printf '%s\n' 10-configure-git.sh ;;
    work-mac) printf '%s\n' 10-configure-git.sh 40-install-work-tools.sh ;;
  esac > "$case_dir/$profile.expected-scripts"
  "$CHEZMOI_BIN" "${common[@]}" managed \
    --include=scripts --path-style=relative \
    > "$case_dir/$profile.managed-scripts"
  diff -u "$case_dir/$profile.expected-scripts" \
    "$case_dir/$profile.managed-scripts"

  rendered_git_script="$case_dir/$profile.configure-git.sh"
  "$CHEZMOI_BIN" "${common[@]}" execute-template \
    < "$CHEZMOI_DIR/source/run_once_after_10-configure-git.sh.tmpl" \
    > "$rendered_git_script"
  sh -n "$rendered_git_script"
  if [[ "$profile" == ubuntu ]]; then
    grep -Fq 'git config --global core.editor nvim' "$rendered_git_script"
    grep -Fq 'git config --global core.excludesfile' "$rendered_git_script"
  else
    ! grep -Fq 'git config --global core.editor' "$rendered_git_script"
  fi

  "$CHEZMOI_BIN" "${common[@]}" apply \
    --exclude=scripts --force --no-tty
  [[ -z "$("$CHEZMOI_BIN" "${common[@]}" status --exclude=scripts)" ]]
  "$CHEZMOI_BIN" "${common[@]}" verify --exclude=scripts
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$home_dir" \
    CHEZMOI_STATE_DIR="$state_dir" \
    bash "$CHEZMOI_DIR/doctor.sh" "$profile" >/dev/null
done

rollback_home="$case_dir/rollback/home"
rollback_state="$case_dir/rollback/state"
rollback_backups="$case_dir/rollback/backups"
mkdir -p "$rollback_home/.config/herdr" "$rollback_home/.config/hunk"
printf 'original herdr\n' > "$rollback_home/.config/herdr/config.toml"
printf 'original hunk\n' > "$rollback_home/original-hunk.toml"
ln -s "$rollback_home/original-hunk.toml" \
  "$rollback_home/.config/hunk/config.toml"

backup_dir="$(
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$rollback_home" \
    CHEZMOI_STATE_DIR="$rollback_state" \
    CHEZMOI_BACKUP_ROOT="$rollback_backups" \
    bash "$CHEZMOI_DIR/backup.sh" mac-mini
)"
rollback_common=(
  --source "$CHEZMOI_DIR/source"
  --config "$CHEZMOI_DIR/profiles/mac-mini.toml"
  --destination "$rollback_home"
  --persistent-state "$rollback_state/mac-mini.boltdb"
)
"$CHEZMOI_BIN" "${rollback_common[@]}" apply \
  --exclude=scripts --force --no-tty

wrong_host_backup="$rollback_backups/wrong-host-mac-mini"
cp -a "$backup_dir" "$wrong_host_backup"
awk -F $'\t' 'BEGIN { OFS = "\t" } $1 == "host" { $2 = "other-host" } { print }' \
  "$wrong_host_backup/metadata.tsv" \
  > "$wrong_host_backup/metadata.tmp"
mv "$wrong_host_backup/metadata.tmp" "$wrong_host_backup/metadata.tsv"
set +e
wrong_host_output="$({
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$rollback_home" \
    CHEZMOI_STATE_DIR="$rollback_state" \
    CHEZMOI_BACKUP_ROOT="$rollback_backups" \
    bash "$CHEZMOI_DIR/rollback.sh" mac-mini "$wrong_host_backup" --preview
} 2>&1)"
wrong_host_status=$?
set -e
((wrong_host_status != 0))
[[ "$wrong_host_output" == *"backup host mismatch"* ]]

tampered_backup="$rollback_backups/tampered-mac-mini"
cp -a "$backup_dir" "$tampered_backup"
mkdir -p "$rollback_home/.ssh"
printf 'do not move\n' > "$rollback_home/.ssh/id_ed25519"
printf '.ssh/id_ed25519|absent|||\n' \
  >> "$tampered_backup/manifest.tsv"
set +e
tampered_output="$({
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$rollback_home" \
    CHEZMOI_STATE_DIR="$rollback_state" \
    CHEZMOI_BACKUP_ROOT="$rollback_backups" \
    bash "$CHEZMOI_DIR/rollback.sh" mac-mini "$tampered_backup" --preview
} 2>&1)"
tampered_status=$?
set -e
((tampered_status != 0))
[[ "$tampered_output" == *"manifest does not match the mac-mini allowlist"* ]]
grep -Fxq 'do not move' "$rollback_home/.ssh/id_ed25519"

DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$rollback_home" \
  CHEZMOI_STATE_DIR="$rollback_state" \
  CHEZMOI_BACKUP_ROOT="$rollback_backups" \
  bash "$CHEZMOI_DIR/rollback.sh" mac-mini "$backup_dir" --preview \
  > "$case_dir/rollback-preview.log"
grep -Fq 'rollback preview passed' "$case_dir/rollback-preview.log"
[[ "$(readlink "$rollback_home/.config/herdr/config.toml")" == \
  "$REPO_DIR/config/herdr/config.toml" ]]

DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$rollback_home" \
  CHEZMOI_STATE_DIR="$rollback_state" \
  CHEZMOI_BACKUP_ROOT="$rollback_backups" \
  bash "$CHEZMOI_DIR/rollback.sh" mac-mini "$backup_dir" >/dev/null

grep -Fxq 'original herdr' "$rollback_home/.config/herdr/config.toml"
[[ "$(readlink "$rollback_home/.config/hunk/config.toml")" == \
  "$rollback_home/original-hunk.toml" ]]
[[ ! -e "$rollback_home/.zshrc" && ! -L "$rollback_home/.zshrc" ]]

legacy_home="$case_dir/legacy-rollback/home"
legacy_state="$case_dir/legacy-rollback/state"
legacy_backups="$case_dir/legacy-rollback/backups"
mkdir -p "$legacy_home/.config" "$legacy_state"
ln -s "$REPO_DIR/config/btop" "$legacy_home/.config/btop"
ln -s "$REPO_DIR/config/fastfetch" "$legacy_home/.config/fastfetch"
legacy_backup="$(
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$legacy_home" \
    CHEZMOI_STATE_DIR="$legacy_state" \
    CHEZMOI_BACKUP_ROOT="$legacy_backups" \
    bash "$CHEZMOI_DIR/backup.sh" ubuntu
)"
legacy_common=(
  --source "$CHEZMOI_DIR/source"
  --config "$CHEZMOI_DIR/profiles/ubuntu.toml"
  --destination "$legacy_home"
  --persistent-state "$legacy_state/ubuntu.boltdb"
)
"$CHEZMOI_BIN" "${legacy_common[@]}" apply \
  --exclude=scripts --force --no-tty
[[ -d "$legacy_home/.config/btop" && ! -L "$legacy_home/.config/btop" ]]
[[ -d "$legacy_home/.config/fastfetch" && ! -L "$legacy_home/.config/fastfetch" ]]
HOME="$legacy_home" \
  DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$legacy_home" \
  CHEZMOI_STATE_DIR="$legacy_state" \
  CHEZMOI_BACKUP_ROOT="$legacy_backups" \
  bash "$CHEZMOI_DIR/rollback.sh" ubuntu "$legacy_backup" \
  > "$case_dir/legacy-rollback.log"
[[ "$(readlink "$legacy_home/.config/btop")" == "$REPO_DIR/config/btop" ]]
[[ "$(readlink "$legacy_home/.config/fastfetch")" == \
  "$REPO_DIR/config/fastfetch" ]]

activation_home="$case_dir/activation/home"
activation_state="$case_dir/activation/state"
activation_backups="$case_dir/activation/backups"
mkdir -p "$activation_home" "$activation_state"
activation_backup="$({
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$activation_home" \
    CHEZMOI_STATE_DIR="$activation_state" \
    CHEZMOI_BACKUP_ROOT="$activation_backups" \
    bash "$CHEZMOI_DIR/backup.sh" ubuntu
})"
grep -Fqx $'active\tabsent' "$activation_backup/metadata.tsv"
HOME="$activation_home" \
  DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$activation_home" \
  CHEZMOI_STATE_DIR="$activation_state" \
  CHEZMOI_BACKUP_ROOT="$activation_backups" \
  bash -c 'source "$1/lib.sh"; load_profile ubuntu; activate_profile' \
  _ "$CHEZMOI_DIR"
[[ -f "$activation_state/ubuntu-active" ]]
DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$activation_home" \
  CHEZMOI_STATE_DIR="$activation_state" \
  CHEZMOI_BACKUP_ROOT="$activation_backups" \
  bash "$CHEZMOI_DIR/rollback.sh" ubuntu "$activation_backup" \
  > "$case_dir/activation-rollback.log"
[[ ! -e "$activation_state/ubuntu-active" ]]
grep -Fq 'the previous writer is active again' \
  "$case_dir/activation-rollback.log"

printf 'profile=ubuntu\ncommit=original\n' \
  > "$activation_state/ubuntu-active"
active_backup="$({
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$activation_home" \
    CHEZMOI_STATE_DIR="$activation_state" \
    CHEZMOI_BACKUP_ROOT="$activation_backups" \
    bash "$CHEZMOI_DIR/backup.sh" ubuntu
})"
grep -Fqx $'active\tpresent' "$active_backup/metadata.tsv"
printf 'profile=ubuntu\ncommit=changed\n' \
  > "$activation_state/ubuntu-active"
DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$activation_home" \
  CHEZMOI_STATE_DIR="$activation_state" \
  CHEZMOI_BACKUP_ROOT="$activation_backups" \
  bash "$CHEZMOI_DIR/rollback.sh" ubuntu "$active_backup" >/dev/null
cmp -s "$active_backup/activation-marker" \
  "$activation_state/ubuntu-active"

apply_home="$case_dir/apply/home"
mkdir -p "$apply_home"
HOME="$apply_home" \
  DOTFILES_CHEZMOI_TEST=1 \
  DOTFILES_CHEZMOI_APPROVED=1 \
  DOTFILES_MAC_MINI_CONFIG_ONLY=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$apply_home" \
  CHEZMOI_STATE_DIR="$case_dir/apply/state" \
  CHEZMOI_BACKUP_ROOT="$case_dir/apply/backups" \
  bash "$CHEZMOI_DIR/apply.sh" mac-mini \
  > "$case_dir/apply.log"
grep -Fq 'PASS  mac-mini production chezmoi profile' \
  "$case_dir/apply.log"
grep -Fq 'rollback preview passed' "$case_dir/apply.log"

printf 'chezmoi_production_tests=ok\n'
