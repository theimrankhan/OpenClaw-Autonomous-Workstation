#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

require_root
detect_os
inspect_system

export OPENCLAW_GIT_URL="${OPENCLAW_GIT_URL:-https://github.com/openclaw/openclaw.git}"
export OPENCLAW_BRANCH="${OPENCLAW_BRANCH:-main}"
export OPENCLAW_PORT="${OPENCLAW_PORT:-8080}"

ensure_user
mkdir -p "${OPENCLAW_HOME}/"{app,config,workspace,memory,skills,tools,logs,backups,data}
chown -R "${OPENCLAW_USER}:${OPENCLAW_USER}" "$OPENCLAW_HOME"

backup_path "${OPENCLAW_HOME}/app"
if [[ -d "${OPENCLAW_HOME}/app/.git" ]]; then
  run_step "Update OpenClaw source" as_openclaw git -C "${OPENCLAW_HOME}/app" pull --ff-only
else
  rm -rf "${OPENCLAW_HOME}/app"
  run_step "Clone OpenClaw latest source" as_openclaw git clone --branch "$OPENCLAW_BRANCH" "$OPENCLAW_GIT_URL" "${OPENCLAW_HOME}/app"
fi

install_file "${SCRIPT_DIR}/../openclaw/config.yaml" "${OPENCLAW_HOME}/config/config.yaml" 0640
install_file "${SCRIPT_DIR}/../openclaw/skills.yaml" "${OPENCLAW_HOME}/skills/skills.yaml" 0640
install_file "${SCRIPT_DIR}/../services/openclaw.service" /etc/systemd/system/openclaw.service 0644

if [[ -f "${OPENCLAW_HOME}/app/package.json" ]]; then
  run_step "Install OpenClaw Node dependencies" as_openclaw bash -lc "cd '${OPENCLAW_HOME}/app' && npm ci || npm install"
fi
if [[ -f "${OPENCLAW_HOME}/app/requirements.txt" ]]; then
  run_step "Install OpenClaw Python dependencies" as_openclaw bash -lc "python3 -m venv '${OPENCLAW_HOME}/venv' && '${OPENCLAW_HOME}/venv/bin/pip' install -r '${OPENCLAW_HOME}/app/requirements.txt'"
fi

systemctl daemon-reload
systemctl enable --now openclaw
sleep 8
systemctl --no-pager --full status openclaw | tee -a "$LOG_FILE" || true
curl -fsS "http://127.0.0.1:${OPENCLAW_PORT}/health" | tee -a "$LOG_FILE" || log "OpenClaw health endpoint did not respond; check upstream startup command in services/openclaw.service."
log "OpenClaw install workflow completed."
