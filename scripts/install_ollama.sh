#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

require_root
detect_os
inspect_system
export OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-qwen2.5:7b}"

backup_path /etc/systemd/system/ollama.service
mkdir -p "${OPENCLAW_HOME}/ollama/models"
install_file "${SCRIPT_DIR}/../ollama/ollama.env" "${OPENCLAW_HOME}/ollama/ollama.env" 0644

if ! command -v ollama >/dev/null 2>&1; then
  log "Installing Ollama from official installer."
  curl -fsSL https://ollama.com/install.sh | sh 2>&1 | tee -a "$LOG_FILE"
else
  log "Ollama already installed."
fi

if id ollama >/dev/null 2>&1; then
  chown -R ollama:ollama "${OPENCLAW_HOME}/ollama"
fi

install_file "${SCRIPT_DIR}/../services/ollama.service" /etc/systemd/system/ollama.service 0644
systemctl daemon-reload
systemctl enable --now ollama
sleep 5

run_step "Pull default Ollama model ${OLLAMA_DEFAULT_MODEL}" ollama pull "$OLLAMA_DEFAULT_MODEL"
run_step "Probe Ollama API" curl -fsS http://127.0.0.1:11434/api/tags
log "Ollama is operational with default model ${OLLAMA_DEFAULT_MODEL}."
