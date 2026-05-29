#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

require_root
detect_os
inspect_system

backup_path /etc/ssh/sshd_config
backup_path /etc/ufw
backup_path /etc/fail2ban

apt_install ufw fail2ban openssh-server

install -d -m 0755 /etc/ssh/sshd_config.d
install_file "${SCRIPT_DIR}/../security/99-openclaw-hardening.conf" /etc/ssh/sshd_config.d/99-openclaw-hardening.conf 0644
sshd -t
systemctl reload ssh || systemctl reload sshd || true

ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 3000/tcp comment Grafana
ufw allow 8080/tcp comment OpenClaw
ufw allow 11434/tcp comment Ollama
ufw --force enable
ufw status verbose | tee -a "$LOG_FILE"

install_file "${SCRIPT_DIR}/../security/jail.local" /etc/fail2ban/jail.local 0644
systemctl enable --now fail2ban
fail2ban-client status | tee -a "$LOG_FILE"
log "Security hardening complete. Confirm SSH keys before closing existing sessions."
