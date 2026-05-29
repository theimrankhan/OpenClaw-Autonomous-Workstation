#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

require_root
detect_os
inspect_system
"${SCRIPT_DIR}/install_prereqs.sh"
"${SCRIPT_DIR}/install_ollama.sh"
"${SCRIPT_DIR}/install_openclaw.sh"
"${SCRIPT_DIR}/security_hardening.sh"
"${SCRIPT_DIR}/install_monitoring.sh"
"${SCRIPT_DIR}/install_tailscale.sh"
"${SCRIPT_DIR}/setup_backup.sh"
"${SCRIPT_DIR}/verify_stack.sh"
log "Full OpenClaw autonomous workstation deployment complete."
