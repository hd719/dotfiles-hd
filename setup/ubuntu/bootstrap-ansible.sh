#!/usr/bin/env bash
set -euo pipefail

# Keep this bootstrap intentionally small. Ansible owns everything after its
# normal Ubuntu package is available.
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ansible-core

# The file provisioner uploads a fresh playbook after this step.
rm -rf -- /tmp/ubuntu-workstation-ansible

secrets_file="/dev/shm/ubuntu-workstation-secrets.json"
install -o vagrant -g vagrant -m 600 /dev/null "$secrets_file"

# JSON avoids shell-quoting bugs in public keys and one-time auth keys.
python3 - "$secrets_file" <<'PY'
import json
import os
import sys

data = {
    "dotfiles_git_ref": os.environ.get("DOTFILES_GIT_REF", "master"),
    "tailscale_auth_key": os.environ.get("TAILSCALE_AUTH_KEY", ""),
    "workstation_hostname": os.environ.get(
        "WORKSTATION_HOSTNAME", "ubuntu-dev-canary"
    ),
    "workstation_login_public_key": os.environ[
        "WORKSTATION_LOGIN_PUBLIC_KEY"
    ],
}

with open(sys.argv[1], "w", encoding="utf-8") as stream:
    json.dump(data, stream)
PY
