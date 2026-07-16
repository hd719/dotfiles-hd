#!/usr/bin/env bash
set -euo pipefail

ROOT_PREFIX="${DOTFILES_ROOT_PREFIX:-}"
OS_RELEASE_FILE="${DOTFILES_OS_RELEASE_FILE:-${ROOT_PREFIX}/etc/os-release}"

print_usage() {
  cat <<'EOF'
Usage: cleanup-legacy.sh --yes

Remove the superseded tools installed by the old Ubuntu setup before running
the lean APT + mise workstation installer. This is intentionally separate from
the normal, non-destructive setup.
EOF
}

log() {
  printf '\n==> %s\n' "$1"
}

require_ubuntu() {
  [[ -r "$OS_RELEASE_FILE" ]] || {
    printf 'Cannot read %s.\n' "$OS_RELEASE_FILE" >&2
    exit 1
  }

  # shellcheck disable=SC1090
  source "$OS_RELEASE_FILE"
  if [[ "${ID:-}" != "ubuntu" ]]; then
    printf 'This cleanup supports Ubuntu only (detected: %s).\n' "${ID:-unknown}" >&2
    exit 1
  fi
}

collect_legacy_packages() {
  local package status base_name

  while IFS=$'\t' read -r package status; do
    [[ "$status" == ii* || "$status" == rc* ]] || continue
    base_name="${package%%:*}"
    case "$base_name" in
      code | code-insiders | containerd.io | docker-buildx-plugin | docker-ce | docker-ce-cli | docker-ce-rootless-extras | docker-compose-plugin | fastfetch | golang | golang-go | golang-doc | golang-src | golang-[0-9]* | redis-server | redis-tools | ulauncher)
        printf '%s\n' "$package"
        ;;
    esac
  done < <(dpkg-query -W -f='${binary:Package}\t${db:Status-Abbrev}\n' 2>/dev/null || true)
}

remove_legacy_packages() {
  local packages=()
  local package

  while IFS= read -r package; do
    [[ -n "$package" ]] && packages+=("$package")
  done < <(collect_legacy_packages)
  if ((${#packages[@]} > 0)); then
    log "Removing superseded APT packages"
    sudo env DEBIAN_FRONTEND=noninteractive apt-get purge -y "${packages[@]}"
  fi
}

remove_legacy_snaps() {
  local package

  command -v snap >/dev/null 2>&1 || return 0
  log "Removing superseded development snaps"
  for package in ghostty kubectl fx ngrok; do
    if snap list "$package" >/dev/null 2>&1; then
      sudo snap remove "$package"
    fi
  done
}

remove_root_artifacts() {
  local root_paths=(
    "${ROOT_PREFIX}/etc/apt/keyrings/docker.asc"
    "${ROOT_PREFIX}/etc/apt/keyrings/docker.gpg"
    "${ROOT_PREFIX}/etc/apt/keyrings/packages.microsoft.gpg"
    "${ROOT_PREFIX}/usr/local/aws-cli"
    "${ROOT_PREFIX}/usr/local/bin/aws"
    "${ROOT_PREFIX}/usr/local/bin/aws_completer"
    "${ROOT_PREFIX}/usr/local/bin/kubectl"
    "${ROOT_PREFIX}/usr/local/bin/starship"
    "${ROOT_PREFIX}/usr/local/bin/terraform"
  )

  shopt -s nullglob
  root_paths+=(
    "${ROOT_PREFIX}/etc/apt/sources.list.d/"*docker*
    "${ROOT_PREFIX}/etc/apt/sources.list.d/"*fastfetch*
    "${ROOT_PREFIX}/etc/apt/sources.list.d/"*ulauncher*
    "${ROOT_PREFIX}/etc/apt/sources.list.d/"*vscode*
  )
  shopt -u nullglob

  log "Removing superseded repositories and direct installs"
  sudo rm -rf -- "${root_paths[@]}"
}

remove_user_toolchains() {
  local user_paths=(
    "$HOME/.config/autostart/ulauncher.desktop"
    "$HOME/.config/ulauncher"
    "$HOME/.local/bin/bash-language-server"
    "$HOME/.local/bin/diff-so-fancy"
    "$HOME/.local/bin/fd"
    "$HOME/.local/bin/gopls"
    "$HOME/.local/bin/graphql-lsp"
    "$HOME/.local/bin/lua-language-server"
    "$HOME/.local/bin/nvim"
    "$HOME/.local/bin/ruff"
    "$HOME/.local/bin/stylua"
    "$HOME/.local/bin/tree-sitter"
    "$HOME/.local/bin/uv"
    "$HOME/.local/bin/uvx"
    "$HOME/.local/bin/vscode-css-language-server"
    "$HOME/.local/bin/vscode-eslint-language-server"
    "$HOME/.local/bin/vscode-html-language-server"
    "$HOME/.local/bin/vscode-json-language-server"
    "$HOME/.local/bin/vtsls"
    "$HOME/.local/bin/zoxide"
    "$HOME/.local/nvim-node-tools"
    "$HOME/.local/opt/lua-language-server"
    "$HOME/.local/opt/nvim"
    "$HOME/.local/opt/stylua"
    "$HOME/.local/opt/tree-sitter"
    "$HOME/.local/share/diff-so-fancy"
    "$HOME/.local/share/pnpm"
    "$HOME/.local/share/ulauncher"
    "$HOME/.local/share/uv/tools/ruff"
    "$HOME/.rbenv"
    "$HOME/Developer/zsh-plugins/zsh-autosuggestions"
    "$HOME/Developer/zsh-plugins/zsh-syntax-highlighting"
    "$HOME/Developer/zsh-plugins/zsh-you-should-use"
  )

  log "Removing superseded user-level toolchains"
  rm -rf -- "${user_paths[@]}"
  rmdir "$HOME/Developer/zsh-plugins" 2>/dev/null || true
}

remove_ulauncher_shortcut() {
  local media_schema="org.gnome.settings-daemon.plugins.media-keys"
  local shortcut_schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
  local current path schema name command binding value
  local keep_paths=()
  local found=0

  command -v gsettings >/dev/null 2>&1 || return 0
  current="$(gsettings get "$media_schema" custom-keybindings 2>/dev/null)" || return 0

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    schema="${shortcut_schema}:${path}"
    name="$(gsettings get "$schema" name 2>/dev/null || true)"
    command="$(gsettings get "$schema" command 2>/dev/null || true)"
    binding="$(gsettings get "$schema" binding 2>/dev/null || true)"

    if [[ "$name" == "'Ulauncher'" \
      && "$command" == "'ulauncher-toggle'" \
      && "$binding" == "'<Super>space'" ]]; then
      gsettings reset-recursively "$schema"
      found=1
    else
      keep_paths+=("$path")
    fi
  done < <(printf '%s\n' "$current" | grep -oE "'/[^']+/'" | tr -d "'" || true)

  ((found == 1)) || return 0

  value="["
  for path in "${keep_paths[@]}"; do
    [[ "$value" == "[" ]] || value+=", "
    value+="'$path'"
  done
  value+="]"

  log "Removing the legacy Ulauncher shortcut"
  gsettings set "$media_schema" custom-keybindings "$value"
  gsettings reset org.gnome.desktop.wm.keybindings switch-input-source
  gsettings reset org.gnome.desktop.wm.keybindings switch-input-source-backward
}

main() {
  if (($# != 1)) || [[ "$1" != "--yes" ]]; then
    print_usage >&2
    exit 2
  fi

  require_ubuntu
  sudo -v
  remove_legacy_packages
  remove_legacy_snaps
  remove_root_artifacts
  remove_user_toolchains
  remove_ulauncher_shortcut

  log "Refreshing Ubuntu package state"
  sudo env DEBIAN_FRONTEND=noninteractive apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
  sudo apt-get autoclean

  printf '\nLegacy Ubuntu cleanup complete. AWS and Kubernetes credentials, projects, Docker data, Firefox, and system snaps were preserved.\n'
}

main "$@"
