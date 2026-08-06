#!/usr/bin/env bash
set -euo pipefail

minimum_root_kib=209715200
current_root_kib="$(df -Pk / | awk 'NR == 2 { print $2 }')"
if ((current_root_kib >= minimum_root_kib)); then
  printf 'root-filesystem-ready\n'
  exit 0
fi

grow_partition() {
  local partition="$1"
  local partition_name parent_name partition_number

  partition="$(readlink -f "$partition")"
  partition_name="$(basename "$partition")"
  # Do not list dependent device-mapper children; their PKNAME points back to
  # this partition and can be mistaken for the physical parent disk.
  parent_name="$(lsblk -dn -o PKNAME "$partition")"
  partition_number="$(cat "/sys/class/block/$partition_name/partition")"

  [[ -n "$parent_name" && "$partition_number" =~ ^[0-9]+$ ]] || {
    printf 'Cannot identify the root partition parent for %s.\n' "$partition" >&2
    return 1
  }
  growpart "/dev/$parent_name" "$partition_number"
}

root_source="$(findmnt -n -o SOURCE /)"
root_device="$(readlink -f "$root_source")"
root_type="$(lsblk -no TYPE "$root_device" | head -n 1)"
root_filesystem="$(findmnt -n -o FSTYPE /)"

if [[ "$root_type" == "lvm" ]]; then
  # Keep the mapper path for LVM commands. Resolving it to /dev/dm-* makes
  # lvs interpret the device name as a volume-group name.
  volume_group="$(lvs --noheadings -o vg_name "$root_source" | xargs)"
  physical_volume="$(
    pvs --noheadings -o pv_name --select "vg_name=$volume_group" | xargs
  )"
  [[ "$physical_volume" == /dev/* && "$physical_volume" != *" "* ]] || {
    printf 'Expected one physical volume for root, got: %s\n' "$physical_volume" >&2
    exit 1
  }
  grow_partition "$physical_volume"
  pvresize "$physical_volume"
  lvextend -l +100%FREE -r "$root_source"
else
  grow_partition "$root_device"
  case "$root_filesystem" in
    ext2|ext3|ext4)
      resize2fs "$root_device"
      ;;
    xfs)
      xfs_growfs /
      ;;
    *)
      printf 'Unsupported root filesystem: %s\n' "$root_filesystem" >&2
      exit 1
      ;;
  esac
fi

current_root_kib="$(df -Pk / | awk 'NR == 2 { print $2 }')"
((current_root_kib >= minimum_root_kib)) || {
  printf 'Root filesystem is still smaller than 200 GiB.\n' >&2
  exit 1
}
printf 'root-filesystem-grown\n'
