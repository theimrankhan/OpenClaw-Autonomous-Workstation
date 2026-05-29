#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

require_root
inspect_system
install_file "${SCRIPT_DIR}/backup_daily.sh" /usr/local/sbin/openclaw-backup-daily 0755
install_file "${SCRIPT_DIR}/../services/openclaw-backup.service" /etc/systemd/system/openclaw-backup.service 0644
install_file "${SCRIPT_DIR}/../services/openclaw-backup.timer" /etc/systemd/system/openclaw-backup.timer 0644
systemctl daemon-reload
systemctl enable --now openclaw-backup.timer
systemctl list-timers openclaw-backup.timer | tee -a "$LOG_FILE"
log "Daily backup timer configured."
