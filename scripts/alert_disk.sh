#!/usr/bin/env bash
set -Eeuo pipefail
threshold="${1:-90}"
usage="$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')"
if (( usage > threshold )); then
  logger -p daemon.warning "OpenClaw alert: Disk ${usage}% exceeds ${threshold}%"
  echo "ALERT Disk ${usage}% > ${threshold}%"
  exit 2
fi
echo "OK Disk ${usage}%"
