#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

require_root
inspect_system
RETENTION="${BACKUP_RETENTION_DAYS:-14}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE="${BACKUP_DIR}/openclaw-backup-${STAMP}.tar.gz"
mkdir -p "$BACKUP_DIR"
tar -czf "$ARCHIVE" \
  "${OPENCLAW_HOME}/config" \
  "${OPENCLAW_HOME}/docker-compose.yml" \
  "${OPENCLAW_HOME}/logs" \
  /usr/local/sbin/openclaw-backup-daily \
  /etc/systemd/system/openclaw*.service \
  /etc/systemd/system/openclaw*.timer 2>&1 | tee -a "$LOG_FILE"
find "$BACKUP_DIR" -type f -name 'openclaw-backup-*.tar.gz' -mtime +"$RETENTION" -print -delete | tee -a "$LOG_FILE"
test -s "$ARCHIVE"
log "Backup verified: ${ARCHIVE}"
