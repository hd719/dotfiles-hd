# Thin-Mac Vagrant shortcuts. Development still runs inside the Ubuntu guest.

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
