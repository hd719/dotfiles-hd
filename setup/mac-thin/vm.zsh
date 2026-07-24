# Thin-Mac VMware shortcuts. Development still runs inside the guest.

alias u='ssh ubuntu-vm'
alias ubuntu='ssh ubuntu-vm'
alias uvm-open='open -a "VMware Fusion"'

uvm-status() {
  emulate -L zsh

  local vmrun="/Applications/VMware Fusion.app/Contents/Library/vmrun"
  local vmx="$HOME/Virtual Machines.localized/VMWIsoImages/Ubuntu 64-bit Arm 25.10.vmwarevm/Ubuntu 64-bit Arm 25.10.vmx"

  if [[ ! -x "$vmrun" ]]; then
    echo "VMware Fusion is not installed."
    return 1
  fi

  if "$vmrun" list | /usr/bin/grep -Fqx "$vmx"; then
    echo "Ubuntu VM: running"
  else
    echo "Ubuntu VM: stopped"
  fi
}

uvm-ip() {
  emulate -L zsh

  local vmrun="/Applications/VMware Fusion.app/Contents/Library/vmrun"
  local vmx="$HOME/Virtual Machines.localized/VMWIsoImages/Ubuntu 64-bit Arm 25.10.vmwarevm/Ubuntu 64-bit Arm 25.10.vmx"

  if [[ ! -x "$vmrun" ]]; then
    echo "VMware Fusion is not installed."
    return 1
  fi

  "$vmrun" getGuestIPAddress "$vmx" -wait
}
