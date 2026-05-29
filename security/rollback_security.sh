#!/usr/bin/env bash
set -Eeuo pipefail
latest="$(find /opt/openclaw/backups -maxdepth 1 -type f -name 'prechange-*etc_ssh_sshd_config*' | sort | tail -1 || true)"
if [[ -n "$latest" ]]; then
  cp -a "$latest" /etc/ssh/sshd_config
fi
rm -f /etc/ssh/sshd_config.d/99-openclaw-hardening.conf
sshd -t
systemctl reload ssh || systemctl reload sshd || true
ufw --force disable || true
systemctl restart fail2ban || true
echo "Security rollback applied. Review SSH before closing current session."
