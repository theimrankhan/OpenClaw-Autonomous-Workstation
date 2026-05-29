#!/usr/bin/env bash
set -Eeuo pipefail
cd /opt/openclaw/app
export OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-/opt/openclaw/config/config.yaml}"
export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://ollama:11434}"
export OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-qwen2.5:7b}"

if [[ -x ./openclaw ]]; then
  exec ./openclaw serve --host 0.0.0.0 --port "${OPENCLAW_PORT:-8080}" --config "$OPENCLAW_CONFIG"
elif [[ -f package.json ]]; then
  exec npm run start -- --host 0.0.0.0 --port "${OPENCLAW_PORT:-8080}"
elif [[ -f main.py ]]; then
  exec /opt/openclaw/venv/bin/python main.py --host 0.0.0.0 --port "${OPENCLAW_PORT:-8080}"
else
  echo "OpenClaw upstream layout is unknown. Set OPENCLAW_GIT_URL/branch or update entrypoint." >&2
  sleep infinity
fi
