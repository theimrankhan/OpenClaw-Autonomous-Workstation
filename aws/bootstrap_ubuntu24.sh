#!/usr/bin/env bash
set -Eeuo pipefail
export OPENCLAW_HOME="${OPENCLAW_HOME:-/opt/openclaw}"
export LOG_DIR="${OPENCLAW_HOME}/logs"
mkdir -p "$LOG_DIR"
exec > >(tee -a "${LOG_DIR}/aws-bootstrap.log") 2>&1

echo "$(date -Is) Starting OpenClaw AWS bootstrap"
apt-get update
apt-get install -y git ca-certificates curl unzip

if [[ ! -d /opt/OpenClaw-Autonomous-Workstation ]]; then
  git clone "${REPO_URL:-https://github.com/replace-me/OpenClaw-Autonomous-Workstation.git}" /opt/OpenClaw-Autonomous-Workstation
fi

cd /opt/OpenClaw-Autonomous-Workstation
chmod +x scripts/*.sh security/*.sh aws/*.sh
scripts/deploy_local.sh
echo "$(date -Is) OpenClaw AWS bootstrap finished"
