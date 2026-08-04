# Personal readiness owns the thin Mac, Ubuntu VM, and the guarded Mac mini
# goodMorning lane. It does not run general home-lab recovery or maintenance.

write_personal_report() {
  local report_date report thin_verdict ubuntu_verdict mac_mini_verdict
  report_date="$(/bin/date +%F)"
  report="$(prepare_report_path "personal-readiness-${report_date}-manual.md")"
  thin_verdict="$(personal_verdict thin-mac)"
  ubuntu_verdict="$(personal_verdict ubuntu-vm)"
  mac_mini_verdict="$(personal_verdict mac-mini)"

  {
    printf '# Personal Readiness - %s\n\n' "$report_date"
    printf '## Summary\n\n'
    printf -- '- Invocation: Manual fallback CLI\n'
    printf -- '- Thin Mac: %s\n' "$thin_verdict"
    printf -- '- Ubuntu development VM: %s\n' "$ubuntu_verdict"
    printf -- '- Mac mini: %s\n' "$mac_mini_verdict"
    printf -- '- Report: %s\n\n' "$report"
    printf '## Checks\n\n'
  } >"$report"
  write_results_table "$report"
  {
    printf '\n## Notes\n\n'
    printf -- '- Automatic work was limited to the personal-mac-ops standing approvals.\n'
    printf -- '- VM restart or recreation was not attempted.\n'
  } >>"$report"

  printf '\nPERSONAL READINESS\n\nThin Mac: %s\nUbuntu VM: %s\nMac mini: %s\n\nReport:\n%s\n' \
    "$thin_verdict" "$ubuntu_verdict" "$mac_mini_verdict" "$report"
}

run_personal_mac_mini_updates() {
  local mac_host="mac-mini-ts"

  # Probe the transport before running any update. A failed maintenance command
  # may have partially mutated the host, so it must never be replayed over LAN.
  ssh_capture "$mac_host" 'true'
  if ((LAST_STATUS != 0)); then
    mac_host="mac-mini-lan"
    ssh_capture "$mac_host" 'true'
    if ((LAST_STATUS != 0)); then
      add_result FAIL mac-mini "Mac mini goodMorning" \
        "Tailscale and LAN SSH probes failed" \
        "Run: ssh mac-mini-ts true"
      return 1
    fi
    add_result WARN mac-mini "Mac mini SSH" \
      "Tailscale unavailable; LAN fallback completed" \
      "Inspect Tailscale after readiness completes"
  fi

  # Pull first, then start a fresh login shell. This prevents a newly pulled
  # goodMorning implementation from running stale in-memory function code.
  ssh_capture "$mac_host" 'zsh -lic "_goodmorning_sync_dotfiles"'
  if ((LAST_STATUS != 0)); then
    add_result FAIL mac-mini "Mac mini dotfiles" \
      "clean dotfiles fast-forward failed; maintenance was not attempted" \
      "Inspect the Mac mini dotfiles checkout"
    return 1
  fi

  ssh_capture "$mac_host" 'zsh -lic "goodMorning --updates-only"'
  if ((LAST_STATUS != 0)); then
    add_result FAIL mac-mini "Mac mini goodMorning" \
      "guarded update command failed and was not replayed" \
      "Inspect the first failure before retrying"
    return 1
  fi

  add_result PASS mac-mini "Mac mini goodMorning" \
    "guarded package and runtime updates completed" "None"
}

check_ubuntu_forgejo_routes() {
  local vm_host="$1"

  ssh_capture "$vm_host" \
    'ssh -n -o BatchMode=yes -o ConnectTimeout=8 -T forgejo-truenas-ts'
  if ((LAST_STATUS == 0)); then
    add_result PASS ubuntu-vm "Forgejo Tailscale Git" \
      "Tailscale route authenticates" "None"
    return 0
  fi

  ssh_capture "$vm_host" \
    'ssh -n -o BatchMode=yes -o ConnectTimeout=8 -T forgejo-truenas-lan'
  if ((LAST_STATUS == 0)); then
    add_result FAIL ubuntu-vm "Forgejo Tailscale Git" \
      "LAN authenticates; Tailscale route is blocked" \
      "Allow tag:ubuntu-dev to tag:truenas-scale TCP 30143 at https://login.tailscale.com/admin/acls"
    return 1
  fi

  add_result FAIL ubuntu-vm "Forgejo Git" \
    "Tailscale and LAN Forgejo routes both failed" \
    "Run: ssh -T forgejo-truenas-ts; ssh -T forgejo-truenas-lan"
  return 1
}

run_personal_ready() {
  local vm_output vm_host="ubuntu-vm-ts"
  local mac_mini_failed=0
  reset_results

  capture "$DOTFILES_ROOT/setup/mac-thin/doctor.sh"
  record_command_result PASS FAIL thin-mac "Thin-Mac doctor" \
    "doctor passed" "doctor reported failures" \
    "$DOTFILES_ROOT/setup/mac-thin/doctor.sh"

  capture /bin/df -Pk /
  if ((LAST_STATUS == 0)); then
    local available_kib
    available_kib="$(printf '%s\n' "$LAST_OUTPUT" | /usr/bin/awk 'NR == 2 {print $4}')"
    if [[ "$available_kib" =~ ^[0-9]+$ ]] && ((available_kib < 5242880)); then
      add_result FAIL thin-mac "Thin-Mac disk" "less than 5 GiB available" "Review storage before continuing"
    elif [[ "$available_kib" =~ ^[0-9]+$ ]] && ((available_kib < 20971520)); then
      add_result WARN thin-mac "Thin-Mac disk" "less than 20 GiB available" "Review storage soon"
    else
      add_result PASS thin-mac "Thin-Mac disk" "filesystem headroom is available" "None"
    fi
  else
    add_result FAIL thin-mac "Thin-Mac disk" "df failed" "/bin/df -h /"
  fi

  if [[ -x "$BREW_BIN" ]]; then
    capture "$BREW_BIN" trust --json=v1
    if ((LAST_STATUS == 0)); then
      add_result PASS thin-mac "Homebrew tap trust" "trust state inspected; unchanged" "None"
    else
      add_result WARN thin-mac "Homebrew tap trust" "trust inspection unavailable" \
        "Run: brew trust --json=v1"
    fi

    capture "$BREW_BIN" update
    if ((LAST_STATUS != 0)); then
      add_result FAIL thin-mac "Homebrew updates" "brew update failed; upgrade not attempted" \
        "Review the Homebrew error and do not change trust automatically"
    else
      capture /usr/bin/env HOMEBREW_NO_AUTO_UPDATE=1 "$BREW_BIN" upgrade
      if ((LAST_STATUS == 0)); then
        capture /usr/bin/env HOMEBREW_NO_AUTO_UPDATE=1 "$BREW_BIN" outdated
        if ((LAST_STATUS == 0)) && [[ -z "$LAST_OUTPUT" ]]; then
          add_result PASS thin-mac "Homebrew updates" "metadata refreshed and packages upgraded" "None"
        else
          add_result WARN thin-mac "Homebrew updates" "upgrade completed; packages remain outdated" \
            "HOMEBREW_NO_AUTO_UPDATE=1 brew outdated"
        fi
      else
        add_result FAIL thin-mac "Homebrew updates" "brew upgrade failed; tap trust was not changed" \
          "Review the Homebrew error and do not change trust automatically"
      fi
    fi
  else
    add_result FAIL thin-mac "Homebrew" "Homebrew missing" \
      "Install Homebrew through the supported thin-Mac bootstrap"
  fi

  run_personal_mac_mini_updates || mac_mini_failed=1

  capture "$ZSH_BIN" -c "source '$DOTFILES_ROOT/setup/mac-thin/vm.zsh'; uvm-status"
  vm_output="$LAST_OUTPUT"
  if ((LAST_STATUS != 0)); then
    add_result FAIL ubuntu-vm "Ubuntu VM state" "uvm-status failed" \
      "Inspect VMware Fusion and run uvm-status"
    write_personal_report
    return 1
  fi

  if [[ "$vm_output" == *"running"* ]]; then
    add_result PASS ubuntu-vm "Ubuntu VM state" "running" "None"
  elif [[ "$vm_output" == *"powered off"* || "$vm_output" == *"suspended"* ]]; then
    capture "$ZSH_BIN" -c "source '$DOTFILES_ROOT/setup/mac-thin/vm.zsh'; uvm-up"
    if ((LAST_STATUS == 0)); then
      capture "$ZSH_BIN" -c "source '$DOTFILES_ROOT/setup/mac-thin/vm.zsh'; uvm-status"
    fi
    if ((LAST_STATUS == 0)) && [[ "$LAST_OUTPUT" == *"running"* ]]; then
      add_result PASS ubuntu-vm "Ubuntu VM state" "started through uvm-up" "None"
    else
      add_result FAIL ubuntu-vm "Ubuntu VM state" "uvm-up did not reach running" \
        "Keep VMware Fusion open and run uvm-status"
      write_personal_report
      return 1
    fi
  else
    add_result FAIL ubuntu-vm "Ubuntu VM state" "missing, aborted, or unknown state; not started" \
      "Inspect VMware Fusion and run uvm-status"
    write_personal_report
    return 1
  fi

  ssh_capture ubuntu-vm-ts 'true'
  if ((LAST_STATUS != 0)); then
    ssh_capture ubuntu-vm 'true'
    if ((LAST_STATUS == 0)); then
      vm_host="ubuntu-vm"
      add_result WARN ubuntu-vm "Ubuntu SSH" "Tailscale unavailable; local Vagrant fallback works" \
        "Inspect Tailscale after readiness completes"
    else
      add_result FAIL ubuntu-vm "Ubuntu SSH" "Tailscale and local Vagrant SSH unavailable" \
        "Inspect VMware NAT, DNS, and the VM network adapter"
      write_personal_report
      return 1
    fi
  else
    add_result PASS ubuntu-vm "Ubuntu SSH" "ubuntu-vm-ts reachable" "None"
  fi

  ssh_capture "$vm_host" 'cd /home/hamel/Developer/dotfiles-hd && bash setup/ubuntu/update-system.sh'
  record_command_result PASS FAIL ubuntu-vm "Ubuntu updater" \
    "supported updater completed" "supported updater failed" \
    "Verify narrow unattended sudo and rerun setup/ubuntu/update-system.sh"

  ssh_capture "$vm_host" 'cd /home/hamel/Developer/dotfiles-hd && bash setup/ubuntu/doctor.sh'
  record_command_result PASS FAIL ubuntu-vm "Ubuntu doctor" \
    "doctor passed" "doctor reported failures" \
    "cd /home/hamel/Developer/dotfiles-hd && bash setup/ubuntu/doctor.sh"

  check_ubuntu_forgejo_routes "$vm_host" || true

  ssh_capture "$vm_host" 'zsh -lic "command -v codex >/dev/null && codex login status 2>&1 | grep -q '\''Logged in'\'' && mise doctor >/dev/null"'
  record_command_result PASS FAIL ubuntu-vm "Codex and mise" \
    "Codex login and mise passed" "Codex login or mise failed" \
    "zsh -lic 'codex login status; mise doctor'"

  ssh_capture "$vm_host" 'docker info >/dev/null 2>&1'
  record_command_result PASS FAIL ubuntu-vm "Docker" \
    "Docker ready without sudo" "Docker not ready" "docker info"

  ssh_capture "$vm_host" 'test ! -f /var/run/reboot-required'
  if ((LAST_STATUS == 0)); then
    add_result PASS ubuntu-vm "Ubuntu reboot" "no reboot required" "None"
  else
    add_result WARN ubuntu-vm "Ubuntu reboot" "reboot required; not restarted automatically" \
      "Run uvm-stop, then uvm-up"
  fi

  capture "$DOTFILES_ROOT/setup/mac-thin/doctor.sh"
  if ((LAST_STATUS != 0)); then
    add_result FAIL thin-mac "Thin-Mac post-update doctor" "doctor failed after updates" \
      "$DOTFILES_ROOT/setup/mac-thin/doctor.sh"
  else
    add_result PASS thin-mac "Thin-Mac post-update doctor" "doctor passed after updates" "None"
  fi

  write_personal_report
  ((mac_mini_failed == 0))
}
