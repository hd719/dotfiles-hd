# Mac Studio Vagrant shortcuts. Ubuntu is preserved for explicitly requested manual use.

_ubuntu_vagrant() {
  emulate -L zsh

  local project_dir="${DOTFILES_UBUNTU_VAGRANT_DIR:-$HOME/Developer/dotfiles-hd/hosts/ubuntu-dev}"
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

_require_preserved_ubuntu() {
  local project_dir="${DOTFILES_UBUNTU_VAGRANT_DIR:-$HOME/Developer/dotfiles-hd/hosts/ubuntu-dev}"
  if [[ ! -s "$project_dir/.vagrant/machines/default/vmware_desktop/id" ]]; then
    echo "Restore and verify the preserved VM and Vagrant metadata before starting Ubuntu."
    echo "This helper will not create a replacement VM."
    return 1
  fi
  local vm_status
  vm_status="$(_ubuntu_vagrant status --machine-readable)" || return
  if ! print -r -- "$vm_status" | awk -F, '
    $2 == "default" && $3 == "state" && $4 ~ /^(poweroff|running|suspended|saved)$/ { found = 1 }
    END { exit !found }
  '; then
    echo "Preserved Ubuntu is unavailable; refusing to create a replacement VM."
    return 1
  fi
}

uvm-up() {
  _require_preserved_ubuntu || return
  UBUNTU_VM_GUI=1 _ubuntu_vagrant up --no-provision
}

uvm-stop() {
  _ubuntu_vagrant halt
}

uvm-suspend() {
  _ubuntu_vagrant suspend
}

uvm-resume() {
  _require_preserved_ubuntu || return
  _ubuntu_vagrant resume
}

uvm-status() {
  _ubuntu_vagrant status
}

uvm-ip() {
  _ubuntu_vagrant ssh -c 'hostname -I'
}
