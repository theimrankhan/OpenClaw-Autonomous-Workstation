#!/usr/bin/env bash
set -Eeuo pipefail
threshold="${1:-85}"
usage="$(free | awk '/Mem:/ {print int(($2-$7)/$2*100)}')"
if (( usage > threshold )); then
  logger -p daemon.warning "OpenClaw alert: RAM ${usage}% exceeds ${threshold}%"
  echo "ALERT RAM ${usage}% > ${threshold}%"
  exit 2
fi
echo "OK RAM ${usage}%"
