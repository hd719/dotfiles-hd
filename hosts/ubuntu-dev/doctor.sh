#!/usr/bin/env bash
set -uo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)"
REPO_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
OS_RELEASE_FILE="${DOTFILES_OS_RELEASE_FILE:-/etc/os-release}"
NEOVIM_SETUP_SCRIPT="${DOTFILES_NEOVIM_SETUP_SCRIPT:-$SCRIPT_DIR/setup-neovim.sh}"
MISE_BIN="${DOTFILES_MISE_BIN:-$HOME/.local/bin/mise}"
CHEZMOI_DOCTOR="${DOTFILES_CHEZMOI_DOCTOR:-$REPO_DIR/chezmoi/doctor.sh}"
EXPECTED_DOTFILES_ORIGIN="git@github.com:hd719/dotfiles-hd.git"
EXPECTED_DOTFILES_HTTPS_ORIGIN="https://github.com/hd719/dotfiles-hd.git"
EXPECTED_DOTFILES_BRANCH="${DOTFILES_EXPECTED_BRANCH:-master}"
OFFLINE=0
FAILURES=0

usage() {
  cat <<'EOF'
Usage: doctor.sh [--offline]

Verify the live Ubuntu workstation without changing it.

Options:
  --offline  Skip checks that require external authentication.
  -h, --help
             Show this help.
EOF
}

pass() {
  printf 'PASS  %s\n' "$*"
}

fail() {
  printf 'FAIL  %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

skip() {
  printf 'SKIP  %s\n' "$*"
}

check_identity() {
  local host="$1"
  local expected="$2"
  local output

  output="$(ssh -n -o BatchMode=yes -o ConnectTimeout=10 -T "$host" 2>&1 || true)"
  if [[ "$output" == *"$expected"* ]]; then
    pass "$host authenticates as $expected"
  else
    fail "$host authentication failed"
  fi
}

file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null
}

check_local_identity_route() {
  local host="$1"
  local key_name="$2"
  local private_key="$HOME/.ssh/$key_name"
  local effective

  if [[ -f "$private_key" \
    && -f "$private_key.pub" \
    && "$(file_mode "$private_key")" == "600" ]]; then
    pass "$key_name is VM-local with mode 600"
  else
    fail "$key_name or its public key is missing, or the private key is not mode 600"
  fi

  effective="$(ssh -G "$host" 2>/dev/null || true)"
  if printf '%s\n' "$effective" \
    | grep -Eq "^identityfile .*${key_name}$" \
    && printf '%s\n' "$effective" | grep -Fxq "identitiesonly yes" \
    && printf '%s\n' "$effective" | grep -Fxq "identityagent none"; then
    pass "$host selects only $key_name"
  else
    fail "$host must select $key_name without an agent"
  fi
}

while (($# > 0)); do
  case "$1" in
    --offline)
      OFFLINE=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -r "$OS_RELEASE_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$OS_RELEASE_FILE"
  if [[ "${ID:-}" == "ubuntu" ]]; then
    pass "Ubuntu ${VERSION_ID:-unknown} ($(uname -m))"
  else
    fail "Ubuntu required (detected: ${ID:-unknown})"
  fi
else
  fail "cannot read $OS_RELEASE_FILE"
fi

if [[ "$REPO_DIR" == "$HOME/Developer/dotfiles-hd" ]]; then
  pass "canonical dotfiles path"
else
  fail "dotfiles must be at $HOME/Developer/dotfiles-hd"
fi

dotfiles_origin="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)"
dotfiles_origin_ready=0
if [[ "$dotfiles_origin" == "$EXPECTED_DOTFILES_ORIGIN" ]] \
  || { ((OFFLINE == 1)) \
    && [[ "$dotfiles_origin" == "$EXPECTED_DOTFILES_HTTPS_ORIGIN" ]]; }; then
  dotfiles_origin_ready=1
fi

if [[ -d "$REPO_DIR/.git" ]] \
  && ((dotfiles_origin_ready == 1)) \
  && [[ "$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || true)" == "$EXPECTED_DOTFILES_BRANCH" ]] \
  && [[ "$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || true)" == \
    "$(git -C "$REPO_DIR" rev-parse "refs/remotes/origin/$EXPECTED_DOTFILES_BRANCH" 2>/dev/null || true)" ]] \
  && [[ -z "$(git -C "$REPO_DIR" status --porcelain 2>/dev/null)" ]]; then
  pass "clean canonical $EXPECTED_DOTFILES_BRANCH checkout at origin"
else
  fail "dotfiles checkout, origin, branch, parity, or worktree is not ready"
fi

if [[ "$(git config --global core.editor 2>/dev/null || true)" == "nvim" ]] \
  && [[ "$(git config --global core.excludesfile 2>/dev/null || true)" == "$HOME/.gitignore_global" ]]; then
  pass "Git editor and global excludes"
else
  fail "Git editor or global excludes is not configured"
fi

if "$REPO_DIR/config/git/configure-aliases.sh" --check >/dev/null 2>&1; then
  pass "portable Git aliases"
else
  fail "portable Git aliases are not configured"
fi

if [[ "$(getent passwd "$(id -un)" | cut -d: -f7)" == */zsh ]]; then
  pass "Zsh is the login shell"
else
  fail "Zsh is not the login shell"
fi

if id -nG | tr ' ' '\n' | grep -Fxq docker; then
  pass "current user is in the Docker group"
else
  fail "current user is not in the Docker group"
fi

if [[ "$(systemctl get-default 2>/dev/null)" == "graphical.target" ]] \
  && systemctl is-enabled gdm3 >/dev/null 2>&1 \
  && systemctl is-active gdm3 >/dev/null 2>&1 \
  && systemctl is-enabled open-vm-tools >/dev/null 2>&1 \
  && systemctl is-active open-vm-tools >/dev/null 2>&1; then
  pass "graphical VMware desktop"
else
  fail "graphical desktop or VMware guest tools are not ready"
fi

root_kib="$(df -Pk / 2>/dev/null | awk 'NR == 2 { print $2 }')"
if [[ "$root_kib" =~ ^[0-9]+$ ]] && ((root_kib >= 209715200)); then
  pass "root filesystem has at least 200 GiB"
else
  fail "root filesystem did not grow to the 250 GB virtual disk"
fi

if "$CHEZMOI_DOCTOR" ubuntu; then
  pass "Ubuntu Chezmoi configuration"
else
  fail "Ubuntu Chezmoi configuration"
fi

mise_herdr="$("$MISE_BIN" which herdr 2>/dev/null || true)"
if [[ -x "$mise_herdr" ]] \
  && [[ -x "$HOME/.local/bin/herdr" ]] \
  && cmp -s "$mise_herdr" "$HOME/.local/bin/herdr"; then
  pass "remote Herdr client matches mise"
else
  fail "remote Herdr client must match the mise-managed binary"
fi

if systemctl is-enabled docker >/dev/null 2>&1 \
  && systemctl is-active docker >/dev/null 2>&1; then
  pass "Docker service enabled and active"
else
  fail "Docker service is not enabled and active"
fi

if docker info >/dev/null 2>&1; then
  pass "Docker is usable without sudo"
else
  fail "Docker is not usable by the current user"
fi

if command -v tailscale >/dev/null 2>&1 \
  && systemctl is-enabled tailscaled >/dev/null 2>&1 \
  && systemctl is-active tailscaled >/dev/null 2>&1; then
  pass "Tailscale is installed and active"
else
  fail "Tailscale is not installed and active"
fi

if ((OFFLINE == 1)); then
  skip "Tailscale connection (--offline)"
elif [[ "$(tailscale ip -4 2>/dev/null)" == 100.* ]]; then
  pass "Tailscale is connected"
else
  fail "Tailscale is not connected"
fi

if zsh -lic '
  set -e
  for command_name in \
    bookokrat brave-browser btop codex docker fastfetch gh ghostty herdr hunk lsd \
    mise nvim tailscale tmux; do
    command -v "$command_name" >/dev/null
  done
  alias hwatch >/dev/null
  alias hdiff >/dev/null
  alias hstaged >/dev/null
  alias hshow >/dev/null
  alias npb >/dev/null
  test "$(whence -w herdr)" = "herdr: function"
  test "$(whence -w _dotfiles_herdr_reset)" = "_dotfiles_herdr_reset: function"
  whence -w _zsh_autosuggest_start >/dev/null
  whence -w _zsh_highlight >/dev/null
  test -z "${GIT_PAGER+x}"
  test "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" = "fg=#9399b2"
' >/dev/null 2>&1; then
  pass "Ubuntu shell and development aliases"
else
  fail "Ubuntu shell, tools, aliases, or colors are incomplete"
fi

while IFS='|' read -r font_directory font_version font_family font_name; do
  if [[ -f "$HOME/.local/share/fonts/$font_directory/.font-version" ]] \
    && [[ "$(<"$HOME/.local/share/fonts/$font_directory/.font-version")" == "$font_version" ]] \
    && fc-list | grep -F "$font_family" >/dev/null; then
    pass "$font_name $font_version"
  else
    fail "$font_name $font_version is missing"
  fi
done <<'EOF'
CaskaydiaCove|3.4.0|CaskaydiaCove Nerd Font|Caskaydia Cove Nerd Font
Hasklig|3.4.0|Hasklug Nerd Font|Hasklug Nerd Font
MapleMono|7.9|Maple Mono NF|Maple Mono NF
EOF

ghostty_font="$(
  sed -n 's/^font-family = //p' "$HOME/.config/ghostty/config" 2>/dev/null \
    | head -n 1
)"
if [[ "$ghostty_font" == "Maple Mono NF" ]]; then
  pass "Maple Mono NF is the Ghostty default"
else
  fail "Maple Mono NF must be the first Ghostty font family"
fi

if bash "$NEOVIM_SETUP_SCRIPT" --check >/dev/null 2>&1; then
  pass "Neovim daily-driver check"
else
  fail "Neovim daily-driver check failed"
fi

check_local_identity_route github.com id_ed25519_hd719
check_local_identity_route github.com-arbiter id_ed25519_arbiter_hd
check_local_identity_route forgejo-truenas-lan id_ed25519_forgejo_truenas
check_local_identity_route forgejo-truenas-ts id_ed25519_forgejo_truenas

unique_git_keys="$(
  awk 'NF >= 2 { print $2 }' \
    "$HOME/.ssh/id_ed25519_hd719.pub" \
    "$HOME/.ssh/id_ed25519_arbiter_hd.pub" \
    "$HOME/.ssh/id_ed25519_forgejo_truenas.pub" \
    2>/dev/null | sort -u | wc -l | tr -d ' '
)"
if [[ "$unique_git_keys" == "3" ]]; then
  pass "three unique VM-local Git keys"
else
  fail "GitHub, Arbiter, and Forgejo must use three unique VM-local keys"
fi

if ((OFFLINE == 1)); then
  skip "remote GitHub, Forgejo, and Codex login checks (--offline)"
else
  check_identity github.com "Hi hd719!"
  check_identity github.com-arbiter "Hi arbiter-hd!"
  check_identity forgejo-truenas-lan "Hi there, hd719!"
  check_identity forgejo-truenas-ts "Hi there, hd719!"

  gh_login="$(gh api user --jq .login 2>/dev/null || true)"
  if [[ "$gh_login" == "arbiter-hd" ]]; then
    pass "GitHub CLI authenticates as arbiter-hd"
  else
    fail "GitHub CLI must authenticate as arbiter-hd"
  fi

  codex_login_status="$(zsh -lic 'codex login status' 2>&1 || true)"
  if [[ "$codex_login_status" == *"Logged in"* ]]; then
    pass "Codex login is ready"
  else
    fail "Codex login is not ready"
  fi
fi

if ((FAILURES == 0)); then
  printf 'Doctor passed for Ubuntu.\n'
  exit 0
fi

printf 'Doctor found %d failure(s).\n' "$FAILURES" >&2
exit 1
