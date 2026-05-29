#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

require_root
detect_os
inspect_system

mkdir -p "${OPENCLAW_HOME}/monitoring/prometheus" "${OPENCLAW_HOME}/monitoring/grafana"
mkdir -p "${OPENCLAW_HOME}/docker-openclaw"
install_file "${SCRIPT_DIR}/../openclaw/Dockerfile" "${OPENCLAW_HOME}/docker-openclaw/Dockerfile" 0644
install_file "${SCRIPT_DIR}/../openclaw/entrypoint.sh" "${OPENCLAW_HOME}/docker-openclaw/entrypoint.sh" 0755
install_file "${SCRIPT_DIR}/../openclaw/config.yaml" "${OPENCLAW_HOME}/docker-openclaw/config.yaml" 0644
install_file "${SCRIPT_DIR}/../openclaw/skills.yaml" "${OPENCLAW_HOME}/docker-openclaw/skills.yaml" 0644
install_file "${SCRIPT_DIR}/../monitoring/prometheus/prometheus.yml" "${OPENCLAW_HOME}/monitoring/prometheus/prometheus.yml" 0644
install_file "${SCRIPT_DIR}/../monitoring/prometheus/alerts.yml" "${OPENCLAW_HOME}/monitoring/prometheus/alerts.yml" 0644
install_file "${SCRIPT_DIR}/../monitoring/grafana/provisioning/datasources/prometheus.yml" "${OPENCLAW_HOME}/monitoring/grafana/provisioning/datasources/prometheus.yml" 0644
install_file "${SCRIPT_DIR}/../monitoring/grafana/provisioning/dashboards/openclaw.yml" "${OPENCLAW_HOME}/monitoring/grafana/provisioning/dashboards/openclaw.yml" 0644
install_file "${SCRIPT_DIR}/../monitoring/grafana/dashboards/openclaw-host.json" "${OPENCLAW_HOME}/monitoring/grafana/dashboards/openclaw-host.json" 0644
install_file "${SCRIPT_DIR}/../docker/docker-compose.yml" "${OPENCLAW_HOME}/docker-compose.yml" 0644
install_file "${SCRIPT_DIR}/../services/openclaw-stack.service" /etc/systemd/system/openclaw-stack.service 0644

systemctl daemon-reload
systemctl enable --now openclaw-stack
sleep 10
docker compose -f "${OPENCLAW_HOME}/docker-compose.yml" ps | tee -a "$LOG_FILE"
curl -fsS http://127.0.0.1:9090/-/healthy | tee -a "$LOG_FILE"
curl -fsS http://127.0.0.1:3000/api/health | tee -a "$LOG_FILE"
log "Monitoring stack is operational."
