# Thin-Mac Vagrant shortcuts. Development still runs inside the Ubuntu guest.

alias u='ssh ubuntu-vm'
alias ut='ssh ubuntu-vm-ts'

shotvm() {
  emulate -L zsh

  local host="${1:-ubuntu-vm-ts}"
  local tmp_root="${TMPDIR:-/tmp}"
  local screenshot_dir
  local screenshot_file
  local remote_dir="/tmp/codex-images"
  local remote_file

  tmp_root="${tmp_root%/}"
  screenshot_dir="$(command mktemp -d "$tmp_root/shotvm.XXXXXX")" || {
    print -u2 "shotvm: could not create a temporary directory"
    return 1
  }
  screenshot_file="$screenshot_dir/screenshot.png"
  remote_file="$remote_dir/${screenshot_dir##*/}.png"

  {
    if ! command screencapture -i "$screenshot_file" || [[ ! -s "$screenshot_file" ]]; then
      print -u2 "shotvm: screenshot cancelled"
      return 1
    fi

    if ! command ssh "$host" \
      'umask 077; mkdir -p /tmp/codex-images; chmod 700 /tmp/codex-images'; then
      print -u2 "shotvm: could not prepare $host:$remote_dir"
      return 1
    fi

    if ! command scp -q "$screenshot_file" "$host:$remote_file"; then
      print -u2 "shotvm: upload failed"
      return 1
    fi

    if ! print -rn -- "$remote_file" | command pbcopy; then
      print -u2 "shotvm: uploaded $remote_file but could not copy its path"
      return 1
    fi

    print "shotvm: uploaded $remote_file"
    print "shotvm: paste into Codex with Cmd-V"
  } always {
    command rm -f "$screenshot_file"
    command rmdir "$screenshot_dir" 2>/dev/null || true
  }
}

_ubuntu_vagrant() {
  emulate -L zsh

  local project_dir="${DOTFILES_UBUNTU_VAGRANT_DIR:-$HOME/Developer/dotfiles-hd/setup/ubuntu}"
  local clone_dir="${VAGRANT_VMWARE_CLONE_DIRECTORY:-$HOME/Virtual Machines.localized/VMWIsoImages}"

  if [[ ! -f "$project_dir/Vagrantfile" ]]; then
    echo "Ubuntu Vagrant project missing: $project_dir"
    return 1
  fi

  (
    cd "$project_dir" || return
    export VAGRANT_CWD="$project_dir"
    export VAGRANT_DEFAULT_PROVIDER=vmware_desktop
    export VAGRANT_VMWARE_CLONE_DIRECTORY="$clone_dir"
    command vagrant "$@"
  )
}

uvm-up() {
  UBUNTU_VM_GUI=1 _ubuntu_vagrant up
}

uvm-stop() {
  _ubuntu_vagrant halt
}

uvm-suspend() {
  _ubuntu_vagrant suspend
}

uvm-resume() {
  _ubuntu_vagrant resume
}

uvm-status() {
  _ubuntu_vagrant status
}

uvm-ip() {
  _ubuntu_vagrant ssh -c 'hostname -I'
}

uvm-destroy() {
  emulate -L zsh

  # Best effort only: the VM may already be stopped. Never start it to inspect keys.
  _ubuntu_vagrant ssh -c \
    'sudo -n -u hamel sh -c '\''for key in /home/hamel/.ssh/id_ed25519_hd719 /home/hamel/.ssh/id_ed25519_arbiter_hd /home/hamel/.ssh/id_ed25519_forgejo_truenas; do test -f "$key.pub" && ssh-keygen -lf "$key.pub"; done'\''' \
    2>/dev/null || true

  echo "Remove this VM's three registered Git public keys after replacement."
  echo "Vagrant will ask for confirmation; this command never forces destroy."
  _ubuntu_vagrant destroy
}
