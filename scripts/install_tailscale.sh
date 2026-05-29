#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

require_root
detect_os
inspect_system

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh 2>&1 | tee -a "$LOG_FILE"
else
  log "Tailscale already installed."
fi
systemctl enable --now tailscaled
if [[ -n "${TAILSCALE_AUTHKEY:-}" ]]; then
  tailscale up --authkey "$TAILSCALE_AUTHKEY" --ssh --accept-routes 2>&1 | tee -a "$LOG_FILE"
else
  log "TAILSCALE_AUTHKEY not set. Run: sudo tailscale up --ssh"
fi
tailscale status | tee -a "$LOG_FILE" || true
log "Tailscale installed for no-port-forwarding remote access."
