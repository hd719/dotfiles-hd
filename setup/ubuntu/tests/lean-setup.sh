#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
NEOVIM_SCRIPT="$ROOT_DIR/setup/ubuntu/setup-neovim.sh"
UPDATE_SCRIPT="$ROOT_DIR/setup/ubuntu/update-system.sh"
DOCTOR_SCRIPT="$ROOT_DIR/setup/ubuntu/doctor.sh"
UBUNTU_README="$ROOT_DIR/setup/ubuntu/README.md"
UBUNTU_GUIDE="$ROOT_DIR/setup/ubuntu/GUIDE.md"
MISE_CONFIG="$ROOT_DIR/setup/ubuntu/mise.toml"
ZSH_CONFIG="$ROOT_DIR/setup/ubuntu/.zshrc"
GHOSTTY_CONFIG="$ROOT_DIR/setup/ubuntu/ghostty.conf"
GRAPHQL_WRAPPER="$ROOT_DIR/setup/ubuntu/bin/graphql-lsp"
CODEX_WRAPPER="$ROOT_DIR/setup/ubuntu/bin/codex"
LINK_SCRIPT="$ROOT_DIR/setup/ubuntu/link-dotfiles.sh"
GIT_ALIASES_SCRIPT="$ROOT_DIR/config/git/configure-aliases.sh"
GIT_ALIASES_CONFIG="$ROOT_DIR/config/git/aliases.gitconfig"
SSH_CONFIG="$ROOT_DIR/setup/ubuntu/ssh/config"
VAGRANTFILE="$ROOT_DIR/setup/ubuntu/Vagrantfile"
ANSIBLE_BOOTSTRAP="$ROOT_DIR/setup/ubuntu/bootstrap-ansible.sh"
ANSIBLE_DIR="$ROOT_DIR/setup/ubuntu/ansible"
ANSIBLE_PLAYBOOK="$ANSIBLE_DIR/playbook.yml"
FASTFETCH_CONFIG="$ROOT_DIR/config/fastfetch/config.jsonc"
BTOP_CONFIG="$ROOT_DIR/config/btop/btop.conf"
SHARED_ALIASES="$ROOT_DIR/config/zsh/shared/aliases.zsh"
SHARED_CODEX_ALIASES="$ROOT_DIR/config/zsh/shared/codex-aliases.zsh"
SHARED_DEVELOPMENT_ALIASES="$ROOT_DIR/config/zsh/shared/development-aliases.zsh"
SHARED_FUNCTIONS="$ROOT_DIR/config/zsh/shared/functions.zsh"
MAC_INIT="$ROOT_DIR/config/zsh/mac/init.zsh"
NVIM_EDITOR_CONFIG="$ROOT_DIR/config/nvim/lua/plugins/editor.lua"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

assert_file_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "$file is missing: $text"
}

extract_shell_array() {
  local array_name="$1"
  local file="$2"

  awk -v start="${array_name}=(" '
    $0 == start { in_array = 1; next }
    in_array && $0 == ")" { exit }
    in_array { for (field = 1; field <= NF; field++) print $field }
  ' "$file"
}

test_neovim_help_is_read_only() {
  local output

  output="$(bash "$NEOVIM_SCRIPT" --help)"
  assert_contains "$output" "Usage:"
  assert_contains "$output" "--check"
}

test_codex_wrapper_stabilizes_forwarded_agent() {
  local case_dir="$TEST_ROOT/codex-forwarded-agent"
  local agent_pid output socket stable_socket

  socket="$case_dir/forwarded.sock"
  stable_socket="$case_dir/home/.ssh/agent/codex-forwarded"
  mkdir -p "$case_dir/home/.local/share/mise/shims"
  cat > "$case_dir/home/.local/share/mise/shims/codex" <<'EOF'
#!/bin/sh
printf 'socket=%s\n' "$SSH_AUTH_SOCK"
printf 'args=%s\n' "$*"
EOF
  chmod +x "$case_dir/home/.local/share/mise/shims/codex"

  eval "$(ssh-agent -a "$socket" -s)" >/dev/null
  agent_pid="$SSH_AGENT_PID"
  output="$(
    HOME="$case_dir/home" \
      SSH_AUTH_SOCK="$socket" \
      "$CODEX_WRAPPER" app-server proxy
  )"
  kill "$agent_pid"

  assert_contains "$output" "socket=$stable_socket"
  assert_contains "$output" "args=app-server proxy"
  [[ -L "$stable_socket" ]] || fail "Codex wrapper did not create a stable agent socket"
  [[ "$(readlink "$stable_socket")" == "$socket" ]] \
    || fail "Codex wrapper pointed at the wrong forwarded agent socket"

  rm -f "$stable_socket"
  ln -s "$case_dir/dead-forwarded.sock" "$stable_socket"
  output="$(
    env -u SSH_AUTH_SOCK \
      HOME="$case_dir/home" \
      "$CODEX_WRAPPER" app-server proxy
  )"
  assert_contains "$output" "socket="
  [[ "$output" != *"socket=$stable_socket"* ]] \
    || fail "Codex wrapper reused a stale forwarded socket"
}

test_portable_git_aliases() {
  local case_dir="$TEST_ROOT/git-aliases"
  local home_dir="$case_dir/home"
  local linked_home="$case_dir/linked-home"
  local linked_source="$case_dir/linked-source"

  [[ ! -e "$ROOT_DIR/config/git/.gitconfig" ]] \
    || fail "legacy non-portable Git config still exists"
  [[ "$(git config --file "$GIT_ALIASES_CONFIG" --get alias.st)" == "status" ]] \
    || fail "portable Git aliases are missing st = status"

  mkdir -p "$home_dir"
  printf '[user]\n\tname = machine-owned\n' > "$home_dir/.gitconfig"
  HOME="$home_dir" DOTFILES_STAMP=20260727-120000 \
    "$GIT_ALIASES_SCRIPT" --apply >/dev/null

  [[ "$(HOME="$home_dir" git config --global --get user.name)" == "machine-owned" ]] \
    || fail "Git alias setup replaced machine-owned identity"
  [[ "$(HOME="$home_dir" git config --global --includes --get alias.st)" == "status" ]] \
    || fail "Git alias setup did not activate st = status"
  [[ -f "$home_dir/.gitconfig.backup-20260727-120000" ]] \
    || fail "Git alias setup did not back up the global config"

  HOME="$home_dir" DOTFILES_STAMP=20260727-130000 \
    "$GIT_ALIASES_SCRIPT" --apply >/dev/null
  [[ ! -e "$home_dir/.gitconfig.backup-20260727-130000" ]] \
    || fail "idempotent Git alias setup created another backup"

  mkdir -p "$linked_home"
  printf '[user]\n\tname = linked-machine\n' > "$linked_source"
  ln -s "$linked_source" "$linked_home/.gitconfig"
  HOME="$linked_home" DOTFILES_STAMP=20260727-140000 \
    "$GIT_ALIASES_SCRIPT" --apply >/dev/null
  [[ -f "$linked_home/.gitconfig" && ! -L "$linked_home/.gitconfig" ]] \
    || fail "Git alias setup did not migrate a symlinked global config"
  [[ "$(git config --file "$linked_source" --get user.name)" == "linked-machine" ]] \
    || fail "Git alias setup changed the old symlink target"
}

test_vagrant_ansible_contract() {
  local task_file

  for task_file in \
    "$VAGRANTFILE" \
    "$ANSIBLE_BOOTSTRAP" \
    "$ANSIBLE_PLAYBOOK" \
    "$ANSIBLE_DIR/vars.yml" \
    "$ANSIBLE_DIR/tasks/system.yml" \
    "$ANSIBLE_DIR/tasks/user.yml" \
    "$ANSIBLE_DIR/tasks/tailscale.yml" \
    "$ANSIBLE_DIR/tasks/identities.yml" \
    "$ANSIBLE_DIR/tasks/dotfiles.yml" \
    "$ANSIBLE_DIR/tasks/tools.yml" \
    "$ANSIBLE_DIR/tasks/verify.yml" \
    "$ANSIBLE_DIR/files/grow-root-filesystem.sh" \
    "$SSH_CONFIG" \
    "$LINK_SCRIPT"; do
    [[ -f "$task_file" ]] || fail "missing Vagrant/Ansible file: $task_file"
  done

  assert_file_contains "$ANSIBLE_BOOTSTRAP" \
    'apt-get install -y --no-install-recommends ansible-core'
  assert_file_contains "$ANSIBLE_BOOTSTRAP" \
    'install -o root -g root -m 600 /dev/null "$secrets_file"'
  assert_file_contains "$ANSIBLE_BOOTSTRAP" \
    'chown vagrant:vagrant "$secrets_file"'
  if grep -Eq 'ppa:|cloud-init' "$ANSIBLE_BOOTSTRAP" "$ANSIBLE_DIR"/*.yml "$ANSIBLE_DIR"/tasks/*.yml; then
    fail "bootstrap must not add an Ansible PPA or cloud-init"
  fi

  assert_file_contains "$VAGRANTFILE" 'config.vm.provision "file"'
  assert_file_contains "$VAGRANTFILE" 'config.vm.provision "ansible_local"'
  assert_file_contains "$VAGRANTFILE" 'ansible.install = false'
  assert_file_contains "$VAGRANTFILE" 'ansible.compatibility_mode = "2.0"'
  assert_file_contains "$VAGRANTFILE" \
    'ansible.provisioning_path = "/tmp/ubuntu-workstation-ansible"'
  assert_file_contains "$ANSIBLE_PLAYBOOK" 'hosts: all'
  assert_file_contains "$ANSIBLE_PLAYBOOK" 'tasks/system.yml'
  assert_file_contains "$ANSIBLE_PLAYBOOK" 'tasks/identities.yml'
  assert_file_contains "$ANSIBLE_PLAYBOOK" 'tasks/verify.yml'
  assert_file_contains "$ANSIBLE_DIR/tasks/verify.yml" '--offline'
  assert_file_contains "$ANSIBLE_DIR/vars.yml" '  - btop'
  assert_file_contains "$ANSIBLE_DIR/files/grow-root-filesystem.sh" \
    'growpart "/dev/$parent_name" "$partition_number"'
  assert_file_contains "$ANSIBLE_DIR/files/grow-root-filesystem.sh" \
    'lsblk -dn -o PKNAME "$partition"'
  assert_file_contains "$ANSIBLE_DIR/files/grow-root-filesystem.sh" \
    'lvs --noheadings -o vg_name "$root_source"'
  assert_file_contains "$ANSIBLE_DIR/files/grow-root-filesystem.sh" \
    'lvextend -l +100%FREE -r "$root_source"'
  assert_file_contains "$ROOT_DIR/.gitignore" 'setup/ubuntu/.vagrant/'
  assert_file_contains "$ANSIBLE_DIR/tasks/system.yml" \
    '/var/lib/dotfiles-hd/initial-upgrade-complete'
  assert_file_contains "$ANSIBLE_DIR/vars.yml" '  - gh'
  assert_file_contains "$ANSIBLE_DIR/tasks/system.yml" \
    'when: not workstation_initial_upgrade.stat.exists'
  assert_file_contains "$ANSIBLE_DIR/tasks/system.yml" \
    'dest: /etc/netplan/01-netcfg.yaml'
  assert_file_contains "$ANSIBLE_DIR/tasks/system.yml" \
    'dhcp-identifier: mac'
  assert_file_contains "$ANSIBLE_DIR/tasks/dotfiles.yml" \
    'repo: "{{ workstation_dotfiles_origin.stdout }}"'
  assert_file_contains "$ANSIBLE_DIR/tasks/dotfiles.yml" \
    '[dotfiles_repository_https, dotfiles_repository_ssh]'

  assert_file_contains "$ANSIBLE_DIR/tasks/identities.yml" \
    'creates: "{{ workstation_home }}/.ssh/{{ item.private_key }}"'
  assert_file_contains "$ANSIBLE_DIR/tasks/identities.yml" 'id_ed25519_hd719'
  assert_file_contains "$ANSIBLE_DIR/tasks/identities.yml" 'id_ed25519_arbiter_hd'
  assert_file_contains "$ANSIBLE_DIR/tasks/identities.yml" \
    'id_ed25519_forgejo_truenas'
  assert_file_contains "$SSH_CONFIG" 'Host github.com-arbiter'
  assert_file_contains "$SSH_CONFIG" 'Host forgejo-truenas-ts'
  assert_file_contains "$SSH_CONFIG" 'Host forgejo-truenas-lan'
  assert_file_contains "$SSH_CONFIG" 'IdentityAgent none'
  assert_file_contains "$ANSIBLE_DIR/tasks/tailscale.yml" 'no_log: true'
  assert_file_contains "$ANSIBLE_DIR/tasks/tailscale.yml" \
    'state: absent'
  assert_file_contains "$ANSIBLE_DIR/tasks/user.yml" 'PasswordAuthentication no'
  assert_file_contains "$ANSIBLE_DIR/tasks/user.yml" 'PermitRootLogin no'
  assert_file_contains "$ANSIBLE_DIR/tasks/user.yml" \
    'dest: /etc/ssh/sshd_config.d/00-dotfiles-workstation.conf'
  assert_file_contains "$ANSIBLE_DIR/tasks/user.yml" \
    'ansible.builtin.meta: flush_handlers'
  assert_file_contains "$ANSIBLE_DIR/tasks/user.yml" 'cmd: sshd -T'
  if grep -Fq 'dest: "{{ workstation_home }}/.ssh/config"' \
    "$ANSIBLE_DIR/tasks/identities.yml"; then
    fail "Ansible must not own the user's SSH config"
  fi
  if grep -Fq 'password: "0000"' "$ANSIBLE_DIR/tasks/user.yml"; then
    fail "the VM password must be stored only as a hash"
  fi
}

test_doctor_is_read_only_and_complete() {
  local case_dir="$TEST_ROOT/doctor"
  local output source status target
  local link_specs=(
    "setup/ubuntu/.zshrc|.zshrc"
    "setup/ubuntu/ghostty.conf|.config/ghostty/config"
    "config/starship/starship.toml|.config/starship.toml"
    "config/git/.gitignore_global|.gitignore_global"
    "setup/ubuntu/ssh/config|.ssh/config"
    "config/bookokrat|.config/bookokrat"
    "config/btop|.config/btop"
    "config/fastfetch|.config/fastfetch"
    "config/herdr/config.toml|.config/herdr/config.toml"
    "config/hunk/config.toml|.config/hunk/config.toml"
    "setup/ubuntu/mise.toml|.config/mise/config.toml"
    "config/nvim|.config/nvim"
    "config/tmux|.config/tmux"
    "setup/ubuntu/bin/codex|.local/bin/codex"
    "setup/ubuntu/bin/graphql-lsp|.local/graphql-lsp/bin/graphql-lsp"
  )

  output="$(bash "$DOCTOR_SCRIPT" --help)"
  assert_contains "$output" "Usage:"
  assert_contains "$output" "--offline"

  mkdir -p "$case_dir/home/Developer/dotfiles-hd/.git" "$case_dir/bin"
  mkdir -p \
    "$case_dir/home/Developer/dotfiles-hd/config/git" \
    "$case_dir/home/Developer/dotfiles-hd/setup"
  cp "$GIT_ALIASES_CONFIG" \
    "$case_dir/home/Developer/dotfiles-hd/config/git/aliases.gitconfig"
  cp "$GIT_ALIASES_SCRIPT" \
    "$case_dir/home/Developer/dotfiles-hd/config/git/configure-aliases.sh"
  chmod +x "$case_dir/home/Developer/dotfiles-hd/config/git/configure-aliases.sh"
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' > "$case_dir/os-release"
  mkdir -p \
    "$case_dir/home/.local/share/fonts/CaskaydiaCove" \
    "$case_dir/home/.local/share/fonts/Hasklig" \
    "$case_dir/home/.local/share/fonts/MapleMono"
  printf '3.4.0\n' > "$case_dir/home/.local/share/fonts/CaskaydiaCove/.font-version"
  printf '3.4.0\n' > "$case_dir/home/.local/share/fonts/Hasklig/.font-version"
  printf '7.9\n' > "$case_dir/home/.local/share/fonts/MapleMono/.font-version"
  mkdir -p "$case_dir/home/.ssh"
  for target in \
    id_ed25519_hd719 \
    id_ed25519_arbiter_hd \
    id_ed25519_forgejo_truenas; do
    printf 'private-%s\n' "$target" > "$case_dir/home/.ssh/$target"
    printf 'ssh-ed25519 public-%s test\n' "$target" \
      > "$case_dir/home/.ssh/$target.pub"
    chmod 600 "$case_dir/home/.ssh/$target"
  done
  for spec in "${link_specs[@]}"; do
    source="$case_dir/home/Developer/dotfiles-hd/${spec%%|*}"
    target="$case_dir/home/${spec#*|}"
    assert_file_contains "$UBUNTU_README" "\`~/${spec#*|}\`"
    assert_file_contains "$UBUNTU_README" "\`${spec%%|*}\`"
    if [[ "$source" == */setup/ubuntu/ghostty.conf ]]; then
      mkdir -p "$(dirname "$source")"
      printf 'font-family = Maple Mono NF\n' > "$source"
    elif [[ "${source##*.}" == "toml" || "$source" == */.zshrc || "$source" == */config || "$source" == */codex || "$source" == */graphql-lsp ]]; then
      mkdir -p "$(dirname "$source")"
      printf 'tracked\n' > "$source"
    else
      mkdir -p "$source"
    fi
    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
  done
  assert_file_contains "$UBUNTU_README" 'bash setup/ubuntu/doctor.sh'
  assert_file_contains "$UBUNTU_GUIDE" 'bash setup/ubuntu/doctor.sh'
  assert_file_contains "$UBUNTU_GUIDE" 'bash setup/ubuntu/doctor.sh --offline'

  cat > "$case_dir/bin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'aarch64\n'
EOF
  cat > "$case_dir/bin/git" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"remote get-url origin"*) printf 'git@github.com:hd719/dotfiles-hd.git\n' ;;
  *"branch --show-current"*) printf 'master\n' ;;
  *"rev-parse HEAD"*) printf 'doctor-test-commit\n' ;;
  *"rev-parse refs/remotes/origin/master"*) printf 'doctor-test-commit\n' ;;
  *"status --porcelain"*) ;;
  *"config --global core.editor"*) printf 'nvim\n' ;;
  *"config --global core.excludesfile"*) printf '%s/.gitignore_global\n' "$HOME" ;;
  *"config --global --get-all include.path"*)
    aliases_dir="$(cd "$HOME/Developer/dotfiles-hd/config/git" && pwd -P)"
    printf '%s/aliases.gitconfig\n' "$aliases_dir"
    ;;
  *"config --global --includes --get alias.st"*) printf 'status\n' ;;
  *) exit 1 ;;
esac
EOF
  cat > "$case_dir/bin/id" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  -un) printf 'hamel\n' ;;
  -nG) printf 'hamel docker\n' ;;
  *) printf 'uid=1000(hamel) gid=1000(hamel) groups=1000(hamel),999(docker)\n' ;;
esac
EOF
  cat > "$case_dir/bin/getent" <<'EOF'
#!/usr/bin/env bash
printf 'hamel:x:1000:1000:Hamel:/home/hamel:/usr/bin/zsh\n'
EOF
  cat > "$case_dir/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  is-enabled|is-active)
    exit 0
    ;;
  get-default)
    printf 'graphical.target\n'
    ;;
  *)
    exit 1
    ;;
esac
EOF
  cat > "$case_dir/bin/docker" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == "info" ]]
EOF
  cat > "$case_dir/bin/tailscale" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == "ip" && "${2:-}" == "-4" ]] && printf '100.64.0.1\n'
EOF
  cat > "$case_dir/bin/zsh" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"codex login status"* ]]; then
  printf 'Logged in using ChatGPT\n'
fi
exit 0
EOF
  cat > "$case_dir/bin/fc-list" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' \
  'CaskaydiaCove Nerd Font' \
  'Hasklug Nerd Font' \
  'Maple Mono NF'
EOF
  cat > "$case_dir/bin/gh" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == "api user --jq .login" ]] && printf 'arbiter-hd\n'
EOF
  cat > "$case_dir/bin/ssh" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-G" ]]; then
  case "${!#}" in
    github.com)
      key=id_ed25519_hd719
      ;;
    github.com-arbiter)
      key=id_ed25519_arbiter_hd
      ;;
    forgejo-truenas-lan|forgejo-truenas-ts)
      key=id_ed25519_forgejo_truenas
      ;;
    *)
      exit 1
      ;;
  esac
  printf 'identitiesonly yes\nidentityagent none\nidentityfile ~/.ssh/%s\n' "$key"
  exit 0
fi
case "${!#}" in
  github.com) printf 'Hi hd719!\n' ;;
  github.com-arbiter) printf 'Hi arbiter-hd!\n' ;;
  forgejo-truenas-lan|forgejo-truenas-ts) printf 'Hi there, hd719!\n' ;;
  *) exit 1 ;;
esac
EOF
  cat > "$case_dir/neovim-check.sh" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == "--check" ]]
EOF
  chmod +x "$case_dir/bin/"* "$case_dir/neovim-check.sh"

  output="$({
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_DIR="$case_dir/home/Developer/dotfiles-hd" \
      DOTFILES_OS_RELEASE_FILE="$case_dir/os-release" \
      DOTFILES_NEOVIM_SETUP_SCRIPT="$case_dir/neovim-check.sh" \
      bash "$DOCTOR_SCRIPT"
  } 2>&1)"
  assert_contains "$output" "Doctor passed for Ubuntu."
  assert_contains "$output" "github.com authenticates as Hi hd719!"
  assert_contains "$output" "github.com-arbiter authenticates as Hi arbiter-hd!"
  assert_contains "$output" "forgejo-truenas-lan authenticates as Hi there, hd719!"
  assert_contains "$output" "three unique VM-local Git keys"
  assert_contains "$output" "GitHub CLI authenticates as arbiter-hd"
  assert_contains "$output" "Codex login is ready"
  assert_contains "$output" "graphical VMware desktop"
  assert_contains "$output" "root filesystem has at least 200 GiB"
  assert_contains "$output" "Maple Mono NF is the Ghostty default"

  rm "$case_dir/home/.config/hunk/config.toml"
  set +e
  output="$({
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_DIR="$case_dir/home/Developer/dotfiles-hd" \
      DOTFILES_OS_RELEASE_FILE="$case_dir/os-release" \
      DOTFILES_NEOVIM_SETUP_SCRIPT="$case_dir/neovim-check.sh" \
      bash "$DOCTOR_SCRIPT" --offline
  } 2>&1)"
  status=$?
  set -e
  ((status != 0)) || fail "doctor ignored a missing managed link"
  assert_contains "$output" "link mismatch: $case_dir/home/.config/hunk/config.toml"
  assert_contains "$output" "SKIP  Tailscale connection (--offline)"
  assert_contains "$output" \
    "SKIP  remote GitHub, Forgejo, and Codex login checks (--offline)"
}

test_ubuntu_mise_toolchain_is_exact() {
  local actual expected

  [[ -f "$MISE_CONFIG" ]] || fail "Ubuntu mise config is missing"
  if grep -Eq '=[[:space:]]*"latest"' "$MISE_CONFIG"; then
    fail "Ubuntu mise config contains an unpinned latest version"
  fi
  assert_file_contains "$MISE_CONFIG" 'min_version = "2026.7.5"'

  actual="$(
    awk '
      /^\[tools\]$/ { in_tools = 1; next }
      in_tools && /^\[/ { exit }
      in_tools && $0 !~ /^[[:space:]]*(#|$)/ { print }
    ' "$MISE_CONFIG"
  )"
  expected="$(cat <<'EOF'
node = "24.18.0"
go = "1.26.5"
python = "3.14.6"
bun = "1.3.14"
"aqua:pnpm/pnpm" = "11.13.0"
"aqua:neovim/neovim" = "0.12.4"
"aqua:BurntSushi/ripgrep" = "15.1.0"
"aqua:sharkdp/fd" = "10.4.2"
"aqua:junegunn/fzf" = "0.74.0"
"aqua:jesseduffield/lazygit" = "0.63.0"
"aqua:tree-sitter/tree-sitter" = "0.26.11"
"aqua:LuaLS/lua-language-server" = "3.18.2"
"aqua:JohnnyMorganz/StyLua" = "2.5.2"
"aqua:astral-sh/uv" = "0.11.28"
"aqua:astral-sh/ruff" = "0.15.21"
"aqua:starship/starship" = "1.26.0"
"aqua:ajeetdsouza/zoxide" = "0.10.0"
"aqua:koalaman/shellcheck" = "0.11.0"
"aqua:fastfetch-cli/fastfetch" = "2.66.0"
"aqua:ogulcancelik/herdr" = "0.7.5"
"github:bugzmanov/bookokrat" = "0.3.12"
"go:golang.org/x/tools/gopls" = { version = "0.23.0", depends = ["go"] }
"npm:diff-so-fancy" = { version = "1.4.12", depends = ["node"] }
"npm:hunkdiff" = { version = "0.17.3", depends = ["node"] }
"npm:@openai/codex" = { version = "0.145.0", depends = ["node"] }
"npm:@vtsls/language-server" = { version = "0.3.0", depends = ["node"] }
"npm:vscode-langservers-extracted" = { version = "4.10.0", depends = ["node"] }
"npm:bash-language-server" = { version = "5.6.0", depends = ["node"] }
"npm:graphql-language-service-cli" = { version = "3.5.0", depends = ["node"] }
EOF
)"

  [[ "$actual" == "$expected" ]] || fail "Ubuntu mise [tools] manifest is not the exact lean toolchain"
}

test_ubuntu_ghostty_reuses_shared_config() {
  local font_families

  [[ -L "$GHOSTTY_CONFIG" ]] || fail "Ubuntu Ghostty config is not a symlink"
  [[ "$(readlink "$GHOSTTY_CONFIG")" == "../../config/ghostty/config" ]] || fail "Ubuntu Ghostty config points to the wrong shared file"
  [[ -f "$GHOSTTY_CONFIG" ]] || fail "Ubuntu Ghostty config symlink is broken"

  font_families="$(sed -n 's/^font-family = //p' "$GHOSTTY_CONFIG")"
  [[ "$font_families" == $'Maple Mono NF\nHasklug Nerd Font' ]] || fail "shared Ghostty font fallbacks are not ordered for Mac and Ubuntu"
}

test_fastfetch_os_age_is_cross_platform() {
  assert_file_contains "$FASTFETCH_CONFIG" 'Darwin) birth_install=$(stat -f %B /)'
  assert_file_contains "$FASTFETCH_CONFIG" 'Linux) birth_install=$(stat -c %W /)'
}

test_btop_does_not_write_through_config_link() {
  assert_file_contains "$BTOP_CONFIG" 'save_config_on_exit = false'
}

test_ubuntu_tree_sitter_inventory_matches_shared_config() {
  local shared_languages ubuntu_languages

  shared_languages="$(
    awk '
      $0 == "local parsers = {" { in_parsers = 1; next }
      in_parsers && $0 == "}" { exit }
      in_parsers {
        gsub(/[ \",]/, "")
        if (length($0) > 0) print
      }
    ' "$NVIM_EDITOR_CONFIG"
  )"
  ubuntu_languages="$(extract_shell_array TREE_SITTER_LANGUAGES "$NEOVIM_SCRIPT")"

  [[ -n "$shared_languages" ]] || fail "shared Neovim parser inventory is empty"
  [[ "$ubuntu_languages" == "$shared_languages" ]] || fail "Ubuntu Tree-sitter inventory drifted from the shared Neovim config"
}

test_ubuntu_fonts_are_pinned() {
  local font font_check_task

  for font in \
    "Caskaydia Cove Nerd Font" \
    "Hasklug Nerd Font" \
    "Maple Mono NF"; do
    assert_file_contains "$ANSIBLE_DIR/vars.yml" "name: $font"
    assert_file_contains "$DOCTOR_SCRIPT" "$font"
  done

  assert_file_contains "$ANSIBLE_DIR/vars.yml" "archive: CascadiaCode.tar.xz"
  assert_file_contains "$ANSIBLE_DIR/vars.yml" "archive: Hasklig.tar.xz"
  assert_file_contains "$ANSIBLE_DIR/vars.yml" "archive: MapleMono-NF-unhinted.zip"
  assert_file_contains "$ANSIBLE_DIR/tasks/tools.yml" \
    'checksum: "sha256:{{ item.sha256 }}"'
  assert_file_contains "$ANSIBLE_DIR/tasks/tools.yml" \
    'workstation_font_checks.results[font_index].rc != 0'

  font_check_task="$(
    awk '
      $0 == "- name: Check installed workstation font versions" {
        in_task = 1
      }
      in_task && $0 ~ /^- name:/ \
        && $0 != "- name: Check installed workstation font versions" {
        exit
      }
      in_task { print }
    ' "$ANSIBLE_DIR/tasks/tools.yml"
  )"
  assert_contains "$font_check_task" 'become_user: "{{ workstation_user }}"'
  assert_contains "$font_check_task" 'HOME: "{{ workstation_home }}"'
  assert_contains "$font_check_task" \
    'XDG_DATA_HOME: "{{ workstation_home }}/.local/share"'
}

test_zsh_config_is_linux_native() {
  local case_dir development_alias_line forbidden mise_line output

  while IFS= read -r expected; do
    [[ -n "$expected" ]] && assert_file_contains "$ZSH_CONFIG" "$expected"
  done <<'EOF'
export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="nvim"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#9399b2'
eval "$(mise activate zsh)"
export GIT_PAGER='diff-so-fancy | less --tabs=4 -RFX'
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"
/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
alias gs='git status --short --branch'
alias dc='docker compose'
source_if_exists "$ubuntu_repo/config/zsh/shared/functions.zsh"
source_if_exists "$ubuntu_repo/config/zsh/shared/aliases.zsh"
source_if_exists "$ubuntu_repo/config/zsh/shared/codex-aliases.zsh"
source_if_exists "$ubuntu_repo/config/zsh/shared/development-aliases.zsh"
EOF

  assert_file_contains "$SHARED_ALIASES" "alias gadd='git add .'"
  assert_file_contains "$SHARED_ALIASES" "alias dots='cd ~/Developer/dotfiles-hd'"
  assert_file_contains "$SHARED_CODEX_ALIASES" "alias cod='codex'"
  assert_file_contains "$SHARED_CODEX_ALIASES" "alias codu='codex update'"
  assert_file_contains "$SHARED_FUNCTIONS" "reload()"

  while IFS= read -r expected; do
    [[ -n "$expected" ]] && assert_file_contains "$SHARED_DEVELOPMENT_ALIASES" "$expected"
  done <<'EOF'
alias hwatch='hunk diff --watch'
alias hdiff='hunk diff'
alias hstaged='hunk diff --staged'
alias hshow='hunk show'
alias npb='pnpm run build'
alias ghd='gcm --no-verify'
alias v='nvim'
alias ff='fastfetch'
alias gomod='go mod'
alias tm='tmux'
EOF
  assert_file_contains "$SHARED_ALIASES" "alias ls='lsd --tree --depth 1'"
  assert_file_contains "$MAC_INIT" 'source "$zsh_shared_dir/aliases.zsh"'
  assert_file_contains "$MAC_INIT" 'source "$zsh_shared_dir/development-aliases.zsh"'
  assert_file_contains "$MAC_INIT" 'source "$zsh_mac_dir/aliases.zsh"'
  if grep -Fq 'development-aliases.zsh' "$ROOT_DIR/setup/mac-thin/.zshrc"; then
    fail "thin Mac unexpectedly loads development aliases"
  fi

  mise_line="$(grep -nF 'eval "$(mise activate zsh)"' "$ZSH_CONFIG" | cut -d: -f1)"
  development_alias_line="$(grep -nF 'source_if_exists "$ubuntu_repo/config/zsh/shared/development-aliases.zsh"' "$ZSH_CONFIG" | cut -d: -f1)"
  ((development_alias_line > mise_line)) || fail "Ubuntu loads development aliases before mise"

  for forbidden in mac-pro mac-vm mac-pro-resilience mac-resilience linuxbrew rbenv 'code --wait' kubectl terraform; do
    if grep -Fq -- "$forbidden" "$ZSH_CONFIG"; then
      fail "Ubuntu zsh config still references: $forbidden"
    fi
  done

  output="$(
    HOME="$TEST_ROOT/zsh-home" \
      PATH="/usr/bin:/bin" \
      TERM="xterm-test" \
      zsh -f -c 'source "$1"; printf "%s|%s|%s|%s" "$EDITOR" "$TERM" "$path[1]" "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE"' _ "$ZSH_CONFIG"
  )"
  [[ "$output" == "nvim|xterm-test|$TEST_ROOT/zsh-home/.local/bin|fg=#9399b2" ]] || fail "Ubuntu zsh config did not load cleanly with the readable autosuggestion color"

  HOME="$TEST_ROOT/zsh-home" \
    PATH="/usr/bin:/bin" \
    GIT_PAGER='diff-so-fancy | less --tabs=4 -RFX' \
    zsh -f -c '
      source "$1"
      [[ "$GIT_PAGER" == "less --tabs=4 -RFX" ]] || exit 1
    ' _ "$ZSH_CONFIG" || fail "Ubuntu Git pager did not fall back when diff-so-fancy was unavailable"

  case_dir="$TEST_ROOT/zsh-git-pager"
  mkdir -p "$case_dir/home" "$case_dir/bin"
  cat > "$case_dir/bin/diff-so-fancy" <<'EOF'
#!/usr/bin/env bash
cat
EOF
  chmod +x "$case_dir/bin/diff-so-fancy"
  HOME="$case_dir/home" \
    PATH="$case_dir/bin:/usr/bin:/bin" \
    GIT_PAGER='less --tabs=4 -RFX' \
    zsh -f -c '
      source "$1"
      [[ "$GIT_PAGER" == "diff-so-fancy | less --tabs=4 -RFX" ]] || exit 1
    ' _ "$ZSH_CONFIG" || fail "Ubuntu Git pager did not enable diff-so-fancy when available"

  HOME="$TEST_ROOT/zsh-home" \
    PATH="/usr/bin:/bin" \
    zsh -f -c '
      source "$1"
      [[ "$(alias g)" == "g=git" ]]
      [[ "$(alias gs)" == "gs='\''git status --short --branch'\''" ]]
      [[ "$(alias gadd)" == "gadd='\''git add .'\''" ]]
      [[ "$(alias dots)" == "dots='\''cd ~/Developer/dotfiles-hd'\''" ]]
      [[ "$(alias hdiff)" == "hdiff='\''hunk diff'\''" ]]
      [[ "$(alias npb)" == "npb='\''pnpm run build'\''" ]]
      [[ "$(alias v)" == "v=nvim" ]]
      [[ "$(alias tm)" == "tm=tmux" ]]
      [[ "$(whence -w reload)" == "reload: function" ]]
    ' _ "$ZSH_CONFIG" || fail "Ubuntu did not load the portable shell layer"

  case_dir="$TEST_ROOT/zsh-shared-aliases"
  mkdir -p "$case_dir/home" "$case_dir/bin"
  cat > "$case_dir/bin/lsd" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$case_dir/lsd.log"
EOF
  chmod +x "$case_dir/bin/lsd"

  HOME="$case_dir/home" \
    PATH="$case_dir/bin:/usr/bin:/bin" \
    zsh -f -c 'source "$1"; eval "ls -la"; eval "ll"' _ "$ZSH_CONFIG"
  [[ "$(sed -n '1p' "$case_dir/lsd.log")" == "--tree --depth 1 -la" ]] || fail "Ubuntu ls alias did not preserve lsd tree output"
  [[ "$(sed -n '2p' "$case_dir/lsd.log")" == "-la --tree --depth 1" ]] || fail "Ubuntu ll alias did not match the Mac profile"
}

test_obsolete_ubuntu_helpers_are_gone() {
  local file

  for file in \
    MIGRATION.md \
    cleanup-legacy.sh \
    install-brave.sh \
    install-ruby-lts.sh \
    setup-omakub-workspaces.sh \
    setup-ulauncher.sh \
    setup.sh; do
    [[ ! -e "$ROOT_DIR/setup/ubuntu/$file" ]] || fail "obsolete Ubuntu helper remains: $file"
  done
}

test_neovim_setup_installs_and_checks_daily_driver() {
  local case_dir="$TEST_ROOT/neovim-setup"
  local blink_commit broken_home failed_home fresh_home lazy_commit output status tool
  local tree_sitter_languages tree_sitter_parsers
  local tools=(
    bash-language-server bookokrat bun fd fastfetch fzf go gopls graphql-lsp gs herdr hunk
    lazygit lua-language-server magick mdformat node nvim pnpm python rg ruff shellcheck
    starship stylua tree-sitter uv wl-copy xclip
    vscode-css-language-server vscode-eslint-language-server
    vscode-html-language-server vscode-json-language-server vtsls zoxide
  )

  mkdir -p "$case_dir/home/.config" "$case_dir/home/.local/bin" "$case_dir/bin"
  ln -s "$case_dir/missing-mise-config" "$case_dir/home/.config/mise"
  tree_sitter_languages="$(extract_shell_array TREE_SITTER_LANGUAGES "$NEOVIM_SCRIPT")"
  tree_sitter_languages="${tree_sitter_languages//$'\n'/ }"
  tree_sitter_parsers="$(extract_shell_array TREE_SITTER_PARSERS "$NEOVIM_SCRIPT")"
  tree_sitter_parsers="${tree_sitter_parsers//$'\n'/ }"

  cat > "$case_dir/bin/mise" <<EOF
#!/usr/bin/env bash
printf 'mise %s\n' "\$*" >> "$case_dir/commands.log"
if [[ "\${1:-}" == "exec" ]]; then
  shift
  [[ "\${1:-}" == "--" ]] && shift
  exec "\$@"
fi
if [[ "\${1:-}" == "which" ]]; then
  [[ "\${MISE_AUTO_INSTALL:-}" == "0" ]] || exit 91
  printf '%s\n' "$case_dir/bin/\${2:?}"
fi
exit 0
EOF

  for tool in "${tools[@]}"; do
    cat > "$case_dir/bin/$tool" <<EOF
#!/usr/bin/env bash
printf '$tool %s\n' "\$*" >> "$case_dir/commands.log"
exit 0
EOF
    chmod +x "$case_dir/bin/$tool"
  done
  cat > "$case_dir/bin/mdformat" <<EOF
#!/usr/bin/env bash
printf 'mdformat %s\n' "\$*" >> "$case_dir/commands.log"
if [[ "\${1:-}" == "--version" ]]; then
  printf 'mdformat 1.0.0 (mdformat_footnote 0.1.3, mdformat_frontmatter 2.1.2, mdformat-gfm 1.0.0, mdformat_wikilink 0.3.0, mdformat_gfm_alerts 2.0.0)\n'
fi
EOF
  chmod +x "$case_dir/bin/mdformat"
  cat > "$case_dir/bin/nvim" <<EOF
#!/usr/bin/env bash
printf 'nvim %s\n' "\$*" >> "$case_dir/commands.log"
data_dir="\${XDG_DATA_HOME:-\$HOME/.local/share}/\${NVIM_APPNAME:-nvim}"
if [[ "\$*" == *"Lazy! restore"* ]]; then
  printf 'restore-all=%s\n' "\${DOTFILES_NVIM_RESTORE_ALL:-}" >> "$case_dir/commands.log"
  mkdir -p "\$data_dir/lazy"
  while IFS=\$'\t' read -r plugin commit; do
    mkdir -p "\$data_dir/lazy/\$plugin"
    printf '%s\n' "\$commit" > "\$data_dir/lazy/\$plugin/HEAD"
  done < <(sed -n 's/^  "\([^"]*\)":.*"commit": "\([^"]*\)".*/\1\t\2/p' "$ROOT_DIR/config/nvim/lazy-lock.json")
elif [[ "\$*" == *"nvim-treesitter"* && "\$*" == *":wait()"* ]]; then
  touch "$case_dir/parsers-complete"
  mkdir -p "\$data_dir/site/parser" "\$data_dir/site/queries"
  for parser in $tree_sitter_parsers; do
    printf 'parser data\n' > "\$data_dir/site/parser/\$parser.so"
  done
  for language in $tree_sitter_languages; do
    mkdir -p "\$data_dir/site/queries/\$language"
    printf '(identifier) @variable\n' > "\$data_dir/site/queries/\$language/highlights.scm"
  done
elif [[ "\$*" == *"Tree-sitter parser validation failed"* ]]; then
  for parser in $tree_sitter_parsers; do
    if [[ ! -s "\$data_dir/site/parser/\$parser.so" ]]; then
      printf 'Tree-sitter parser validation failed: %s\n' "\$parser" >&2
      exit 89
    fi
  done
elif [[ "\$*" == *"stdpath('data')"* ]]; then
  printf '%s' "\$data_dir"
elif [[ "\$*" == *"Neovim config validation failed"* ]]; then
  touch "$case_dir/config-loaded"
  if [[ "\${NVIM_CONFIG_FAIL:-0}" == "1" ]]; then
    printf 'Neovim config validation failed\n' >&2
    exit 88
  fi
fi
exit 0
EOF
  cat > "$case_dir/bin/git" <<EOF
#!/usr/bin/env bash
printf 'git %s\n' "\$*" >> "$case_dir/commands.log"
if [[ "\${1:-}" == "clone" ]]; then
  destination="\${!#}"
  mkdir -p "\$destination/.git"
elif [[ "\${1:-}" == "-C" ]]; then
  repository="\$2"
  shift 2
  case "\${1:-}" in
    cat-file)
      commit="\${3%\\^\{commit\}}"
      [[ -f "\$repository/commit-\$commit" ]]
      ;;
    fetch)
      commit="\${4:?}"
      touch "\$repository/commit-\$commit"
      ;;
    checkout)
      commit="\${3:?}"
      printf '%s\n' "\$commit" > "\$repository/HEAD"
      ;;
    rev-parse)
      cat "\$repository/HEAD"
      ;;
  esac
fi
EOF
  chmod +x "$case_dir/bin/nvim"
  chmod +x "$case_dir/bin/mise" "$case_dir/bin/git"

  HOME="$case_dir/home" \
    PATH="$case_dir/bin:/usr/bin:/bin" \
    DOTFILES_MISE_BIN="$case_dir/bin/mise" \
    bash "$NEOVIM_SCRIPT"

  [[ -L "$case_dir/home/.config/mise/config.toml" ]] || fail "Neovim setup did not link mise config"
  [[ "$(readlink "$case_dir/home/.config/mise/config.toml")" == "$MISE_CONFIG" ]] || fail "mise config points to the wrong source"
  [[ -d "$case_dir/home/.config/mise" && ! -L "$case_dir/home/.config/mise" ]] || fail "Neovim setup did not repair a stale mise directory link"
  [[ "$(find "$case_dir/home/.config" -maxdepth 1 -name 'mise.backup.*' | wc -l | tr -d ' ')" == "1" ]] || fail "Neovim setup did not preserve the stale mise directory link"
  [[ -L "$case_dir/home/.config/nvim" ]] || fail "Neovim setup did not link Neovim config"
  [[ "$(readlink "$case_dir/home/.config/nvim")" == "$ROOT_DIR/config/nvim" ]] || fail "Neovim config points to the wrong source"
  [[ -L "$case_dir/home/.local/graphql-lsp/bin/graphql-lsp" ]] || fail "Neovim setup did not link GraphQL wrapper"
  [[ "$(readlink "$case_dir/home/.local/graphql-lsp/bin/graphql-lsp")" == "$GRAPHQL_WRAPPER" ]] || fail "GraphQL wrapper points to the wrong source"

  assert_file_contains "$case_dir/commands.log" "mise self-update -y"
  assert_file_contains "$case_dir/commands.log" "mise install node@24.18.0 go@1.26.5 python@3.14.6 bun@1.3.14"
  assert_file_contains "$case_dir/commands.log" "mise install"
  assert_file_contains "$case_dir/commands.log" "mise reshim"
  assert_file_contains "$case_dir/commands.log" "mdformat==1.0.0"
  assert_file_contains "$case_dir/commands.log" "mdformat-gfm==1.0.0"
  assert_file_contains "$case_dir/commands.log" "mdformat-frontmatter==2.1.2"
  assert_file_contains "$case_dir/commands.log" "mdformat-footnote==0.1.3"
  assert_file_contains "$case_dir/commands.log" "mdformat-gfm-alerts==2.0.0"
  assert_file_contains "$case_dir/commands.log" "mdformat-wikilink==0.3.0"
  lazy_commit="$(sed -n 's/^  "lazy.nvim":.*"commit": "\([^"]*\)".*/\1/p' "$ROOT_DIR/config/nvim/lazy-lock.json")"
  [[ -n "$lazy_commit" ]] || fail "test could not read the locked lazy.nvim commit"
  assert_file_contains "$case_dir/commands.log" "checkout --detach $lazy_commit"
  assert_file_contains "$case_dir/commands.log" "nvim --headless +Lazy! restore +qa"
  assert_file_contains "$case_dir/commands.log" "restore-all=1"
  [[ -f "$case_dir/parsers-complete" ]] || fail "fresh Neovim setup returned before Tree-sitter parsers completed"

  : > "$case_dir/commands.log"
  rm -f "$case_dir/config-loaded"
  output="$(
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_MISE_BIN="$case_dir/bin/mise" \
      bash "$NEOVIM_SCRIPT" --check
  )"
  assert_contains "$output" "Neovim daily-driver check passed"
  assert_file_contains "$case_dir/commands.log" "mise which graphql-lsp"
  assert_file_contains "$case_dir/commands.log" "vim.go.loadplugins = true"
  [[ -e "$case_dir/config-loaded" ]] || fail "Neovim --check did not validate the real editor config"
  if grep -Fq "mise install" "$case_dir/commands.log"; then
    fail "Neovim --check attempted to install tools"
  fi

  blink_commit="$(sed -n 's/^  "blink.cmp":.*"commit": "\([^"]*\)".*/\1/p' "$ROOT_DIR/config/nvim/lazy-lock.json")"
  [[ -n "$blink_commit" ]] || fail "test could not read the locked blink.cmp commit"
  printf 'wrong-commit\n' > "$case_dir/home/.local/share/nvim/lazy/blink.cmp/HEAD"
  : > "$case_dir/commands.log"
  rm -f "$case_dir/config-loaded"
  set +e
  output="$({
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_MISE_BIN="$case_dir/bin/mise" \
      bash "$NEOVIM_SCRIPT" --check
  } 2>&1)"
  status=$?
  set -e

  ((status != 0)) || fail "Neovim --check accepted plugin commit drift"
  assert_contains "$output" "not at its locked commit: blink.cmp"
  [[ ! -e "$case_dir/config-loaded" ]] || fail "plugin drift check loaded the editor config"
  printf '%s\n' "$blink_commit" > "$case_dir/home/.local/share/nvim/lazy/blink.cmp/HEAD"

  : > "$case_dir/home/.local/share/nvim/site/parser/bash.so"
  : > "$case_dir/commands.log"
  rm -f "$case_dir/config-loaded"
  set +e
  output="$({
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_MISE_BIN="$case_dir/bin/mise" \
      bash "$NEOVIM_SCRIPT" --check
  } 2>&1)"
  status=$?
  set -e

  ((status != 0)) || fail "Neovim --check accepted a corrupt Tree-sitter parser"
  assert_contains "$output" "Tree-sitter parser validation failed"
  [[ ! -e "$case_dir/config-loaded" ]] || fail "parser failure loaded the editor config"
  printf 'parser data\n' > "$case_dir/home/.local/share/nvim/site/parser/bash.so"

  : > "$case_dir/commands.log"
  rm -f "$case_dir/config-loaded"
  set +e
  output="$({
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      NVIM_CONFIG_FAIL=1 \
      DOTFILES_MISE_BIN="$case_dir/bin/mise" \
      bash "$NEOVIM_SCRIPT" --check
  } 2>&1)"
  status=$?
  set -e

  ((status != 0)) || fail "Neovim --check ignored a config startup failure"
  [[ -e "$case_dir/config-loaded" ]] || fail "config failure test did not load the editor config"
  if grep -Fq "mise install" "$case_dir/commands.log"; then
    fail "config failure check attempted to install tools"
  fi

  : > "$case_dir/commands.log"
  rm -f "$case_dir/config-loaded"
  set +e
  output="$({
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      NVIM_APPNAME=nvim-empty-check \
      DOTFILES_MISE_BIN="$case_dir/bin/mise" \
      bash "$NEOVIM_SCRIPT" --check
  } 2>&1)"
  status=$?
  set -e

  ((status != 0)) || fail "Neovim --check accepted an empty editor state"
  assert_contains "$output" "Missing locked Neovim plugin"
  [[ ! -e "$case_dir/home/.cache/nvim-empty-check" ]] || fail "Neovim --check wrote to an empty cache directory"
  [[ ! -e "$case_dir/home/.local/share/nvim-empty-check" ]] || fail "Neovim --check wrote to an empty data directory"
  [[ ! -e "$case_dir/config-loaded" ]] || fail "empty-state Neovim --check loaded the mutating editor config"
  if grep -Fq "mise install" "$case_dir/commands.log"; then
    fail "empty-state Neovim --check attempted to install tools"
  fi

  fresh_home="$case_dir/fresh-home"
  mkdir -p "$fresh_home/.config"
  cat > "$case_dir/bin/curl" <<EOF
#!/usr/bin/env bash
printf 'curl %s\n' "\$*" >> "$case_dir/commands.log"
[[ "\$#" == "2" && "\$1" == "-fsSL" && "\$2" == "https://mise.run" ]] || exit 90
install_path="\${DOTFILES_MISE_BIN:-\$HOME/.local/bin/mise}"
cat <<INSTALLER
#!/usr/bin/env bash
mkdir -p "\$(dirname "\$install_path")"
cp "$case_dir/bin/mise" "\$install_path"
INSTALLER
EOF
  chmod +x "$case_dir/bin/curl"
  : > "$case_dir/commands.log"

  output="$(
    HOME="$fresh_home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_MISE_BIN="$fresh_home/.local/bin/mise" \
      bash "$NEOVIM_SCRIPT"
  )"
  assert_contains "$output" "Neovim daily-driver check passed"
  [[ -x "$fresh_home/.local/bin/mise" ]] || fail "fresh Neovim setup did not install mise"
  [[ -L "$fresh_home/.config/nvim" ]] || fail "fresh mise path did not continue through Neovim setup"
  assert_file_contains "$case_dir/commands.log" "curl -fsSL https://mise.run"

  broken_home="$case_dir/broken-home"
  mkdir -p "$broken_home/.config" "$broken_home/.local/bin"
  cat > "$broken_home/.local/bin/mise" <<'EOF'
#!/usr/bin/env bash
exit 139
EOF
  chmod +x "$broken_home/.local/bin/mise"

  output="$(
    HOME="$broken_home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_MISE_BIN="$broken_home/.local/bin/mise" \
      bash "$NEOVIM_SCRIPT"
  )"
  assert_contains "$output" "Repairing mise"
  "$broken_home/.local/bin/mise" version >/dev/null ||
    fail "Neovim setup did not repair a broken mise binary"

  failed_home="$case_dir/failed-home"
  mkdir -p "$failed_home/.config"
  cat > "$case_dir/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '#!/usr/bin/env bash\nexit 0\n'
EOF
  chmod +x "$case_dir/bin/curl"

  set +e
  output="$({
    HOME="$failed_home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_MISE_BIN="$failed_home/.local/bin/mise" \
      bash "$NEOVIM_SCRIPT"
  } 2>&1)"
  status=$?
  set -e

  ((status != 0)) || fail "Neovim setup ignored a failed fresh mise installation"
  assert_contains "$output" "mise was not installed"
  [[ ! -e "$failed_home/.config/nvim" ]] || fail "failed mise installation continued to Neovim linking"
}

test_update_system_stays_lean() {
  local case_dir="$TEST_ROOT/update-system"
  local output forbidden self_update_count

  mkdir -p "$case_dir/home" "$case_dir/bin" "$case_dir/dotfiles/.git"
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' > "$case_dir/os-release"

  cat > "$case_dir/bin/git" <<EOF
#!/usr/bin/env bash
if [[ "\$3" == "remote" ]]; then
  printf '%s\n' 'git@github.com:hd719/dotfiles-hd.git'
  exit 0
fi
if [[ "\$3" == "pull" ]]; then
  printf 'git %s\n' "\$*" >> "$case_dir/commands.log"
  exit 0
fi
exit 1
EOF
  cat > "$case_dir/bin/sudo" <<EOF
#!/usr/bin/env bash
printf 'sudo %s\n' "\$*" >> "$case_dir/commands.log"
EOF
  cat > "$case_dir/bin/mise" <<EOF
#!/usr/bin/env bash
printf 'mise %s\n' "\$*" >> "$case_dir/commands.log"
EOF
  cat > "$case_dir/fake-neovim-setup.sh" <<EOF
#!/usr/bin/env bash
printf 'neovim %s\n' "\$*" >> "$case_dir/commands.log"
"$case_dir/bin/mise" self-update -y
EOF
  chmod +x \
    "$case_dir/bin/git" \
    "$case_dir/bin/sudo" \
    "$case_dir/bin/mise" \
    "$case_dir/fake-neovim-setup.sh"

  output="$({
    HOME="$case_dir/home" \
      PATH="$case_dir/bin:/usr/bin:/bin" \
      DOTFILES_DIR="$case_dir/dotfiles" \
      DOTFILES_OS_RELEASE_FILE="$case_dir/os-release" \
      DOTFILES_MISE_BIN="$case_dir/bin/mise" \
      DOTFILES_NEOVIM_SETUP_SCRIPT="$case_dir/fake-neovim-setup.sh" \
      bash "$UPDATE_SCRIPT"
  } 2>&1)"
  assert_contains "$output" "Ubuntu update complete"
  assert_file_contains "$case_dir/commands.log" "pull --ff-only origin master"
  assert_file_contains "$case_dir/commands.log" "apt-get update"
  assert_file_contains "$case_dir/commands.log" "apt-get full-upgrade -y"
  assert_file_contains "$case_dir/commands.log" "apt-get autoremove -y"
  assert_file_contains "$case_dir/commands.log" "mise self-update -y"
  assert_file_contains "$case_dir/commands.log" "neovim"
  self_update_count="$(grep -Fxc "mise self-update -y" "$case_dir/commands.log")"
  [[ "$self_update_count" == "1" ]] || fail "updater refreshed mise $self_update_count times instead of once"

  for forbidden in snap flatpak rustup 'pnpm update' 'uv self update' npm npx; do
    if grep -Fq -- "$forbidden" "$UPDATE_SCRIPT"; then
      fail "lean updater still references: $forbidden"
    fi
  done
}

test_neovim_help_is_read_only
test_codex_wrapper_stabilizes_forwarded_agent
test_portable_git_aliases
test_vagrant_ansible_contract
test_doctor_is_read_only_and_complete
test_ubuntu_mise_toolchain_is_exact
test_ubuntu_ghostty_reuses_shared_config
test_fastfetch_os_age_is_cross_platform
test_btop_does_not_write_through_config_link
test_ubuntu_tree_sitter_inventory_matches_shared_config
test_ubuntu_fonts_are_pinned
test_zsh_config_is_linux_native
test_neovim_setup_installs_and_checks_daily_driver
test_update_system_stays_lean
test_obsolete_ubuntu_helpers_are_gone
printf 'lean_setup_tests=ok\n'
