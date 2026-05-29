#!/usr/bin/env bash
set -Eeuo pipefail
threshold="${1:-85}"
usage="$(awk -v FS=' ' '/cpu / {idle=$5; total=0; for (i=2;i<=NF;i++) total+=$i; print int((1-idle/total)*100)}' /proc/stat)"
if (( usage > threshold )); then
  logger -p daemon.warning "OpenClaw alert: CPU ${usage}% exceeds ${threshold}%"
  echo "ALERT CPU ${usage}% > ${threshold}%"
  exit 2
fi
echo "OK CPU ${usage}%"
