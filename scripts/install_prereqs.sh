#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

require_root
detect_os
inspect_system
backup_path /etc/apt/sources.list
backup_path /etc/apt/sources.list.d

run_step "Refresh apt metadata" apt-get update
apt_install ca-certificates curl gnupg lsb-release git tmux nginx jq unzip tar gzip ufw fail2ban python3 python3-pip python3-venv nodejs npm

if ! command -v docker >/dev/null 2>&1; then
  install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    run_step "Install Docker apt key" bash -c 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && chmod a+r /etc/apt/keyrings/docker.asc'
  fi
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" >/etc/apt/sources.list.d/docker.list
  run_step "Refresh apt metadata for Docker" apt-get update
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  log "Docker already installed."
fi

systemctl enable --now docker
verify_command docker
docker version | tee -a "$LOG_FILE"
docker compose version | tee -a "$LOG_FILE"
verify_command git
verify_command tmux
verify_command nginx
verify_command node
verify_command python3
log "Prerequisite installation complete."
