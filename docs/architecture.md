# Architecture

OpenClaw-Autonomous-Workstation provisions a local or cloud Ubuntu 24.04 host with:

- Ollama serving `qwen2.5:7b` for local inference.
- OpenClaw as the gateway and autonomous agent runtime.
- Persistent storage under `/opt/openclaw` for config, memory, skills, workspace, logs, and backups.
- Docker Compose for Ollama, OpenClaw, Prometheus, Grafana, and Node Exporter.
- systemd units for boot recovery and restart-on-failure behavior.
- Tailscale for private remote access without port forwarding.
- UFW, Fail2Ban, and SSH hardening for host security.

Operational flow:

1. Scripts inspect the host and log facts.
2. Existing config paths are backed up.
3. Changes are applied idempotently.
4. Services are enabled and started.
5. Health checks verify the result.
6. Logs are written under `/opt/openclaw/logs`.
