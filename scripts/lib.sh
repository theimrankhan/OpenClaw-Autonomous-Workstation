#!/usr/bin/env bash
set -Eeuo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${LIB_DIR}/.." && pwd)"
if [[ -f "${PROJECT_ROOT}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  . "${PROJECT_ROOT}/.env"
  set +a
fi

export OPENCLAW_HOME="${OPENCLAW_HOME:-/opt/openclaw}"
export OPENCLAW_USER="${OPENCLAW_USER:-openclaw}"
export LOG_DIR="${LOG_DIR:-${OPENCLAW_HOME}/logs}"
export BACKUP_DIR="${BACKUP_DIR:-${OPENCLAW_HOME}/backups}"

mkdir -p "$LOG_DIR" "$BACKUP_DIR"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/bootstrap-$(date -u +%Y%m%dT%H%M%SZ).log}"
touch "$LOG_FILE"

log() {
  printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$LOG_FILE"
}

fail() {
  log "ERROR: $*"
  exit 1
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    fail "Run this script as root or with sudo."
  fi
}

detect_os() {
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    log "Detected OS: ${PRETTY_NAME:-unknown}"
    [[ "${ID:-}" == "ubuntu" ]] || log "Warning: scripts are optimized for Ubuntu 24.04."
  else
    fail "Cannot inspect /etc/os-release."
  fi
}

inspect_system() {
  log "Inspecting system."
  uname -a | tee -a "$LOG_FILE"
  df -h / | tee -a "$LOG_FILE"
  free -h | tee -a "$LOG_FILE"
  command -v systemctl >/dev/null 2>&1 && systemctl --version | head -1 | tee -a "$LOG_FILE" || true
}

backup_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    local dest="${BACKUP_DIR}/prechange-$(date -u +%Y%m%dT%H%M%SZ)$(echo "$path" | tr '/' '_')"
    log "Backing up ${path} to ${dest}."
    cp -a "$path" "$dest"
  else
    log "No existing ${path}; backup skipped."
  fi
}

run_step() {
  local description="$1"
  shift
  log "ACTION: ${description}"
  "$@" 2>&1 | tee -a "$LOG_FILE"
  log "VERIFIED: ${description}"
}

apt_install() {
  export DEBIAN_FRONTEND=noninteractive
  run_step "Install packages: $*" apt-get install -y "$@"
}

ensure_user() {
  if id "$OPENCLAW_USER" >/dev/null 2>&1; then
    log "User ${OPENCLAW_USER} already exists."
  else
    run_step "Create service user ${OPENCLAW_USER}" useradd --system --create-home --home-dir "$OPENCLAW_HOME" --shell /usr/sbin/nologin "$OPENCLAW_USER"
  fi
}

install_file() {
  local src="$1"
  local dst="$2"
  local mode="${3:-0644}"
  backup_path "$dst"
  install -D -m "$mode" "$src" "$dst"
  log "Installed ${dst}."
}

verify_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing command: $1"
  log "Verified command: $1"
}

as_openclaw() {
  runuser -u "$OPENCLAW_USER" -- "$@"
}
