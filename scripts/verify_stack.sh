#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

inspect_system
verify_command docker
docker compose -f "${OPENCLAW_HOME}/docker-compose.yml" ps | tee -a "$LOG_FILE" || true
systemctl is-enabled ollama | tee -a "$LOG_FILE"
systemctl is-active ollama | tee -a "$LOG_FILE"
systemctl is-enabled openclaw | tee -a "$LOG_FILE" || true
systemctl is-active openclaw | tee -a "$LOG_FILE" || true
curl -fsS http://127.0.0.1:11434/api/tags | tee -a "$LOG_FILE"
curl -fsS http://127.0.0.1:9090/-/healthy | tee -a "$LOG_FILE" || true
curl -fsS http://127.0.0.1:3000/api/health | tee -a "$LOG_FILE" || true
df -h / "${OPENCLAW_HOME}" | tee -a "$LOG_FILE"
log "Verification complete."
