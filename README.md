# OpenClaw-Autonomous-Workstation

Production-ready automation workstation for Windows 11 plus WSL2 Ubuntu 24.04, native Ubuntu 24.04, or AWS EC2 Spot.

## What It Builds

- Ollama with `qwen2.5:7b` as the default local model.
- OpenClaw gateway, memory, skills, workspace, file tools, terminal tools, and browser tools.
- Docker Compose stack with OpenClaw, Ollama, Prometheus, Grafana, and Node Exporter.
- systemd boot recovery and restart-on-failure services.
- UFW, Fail2Ban, SSH key-only hardening, and rollback scripts.
- Tailscale remote access with no port forwarding.
- Daily backups for configs, Compose files, logs, scripts, and service units.
- AWS Spot deployment scripts for `m7i-flex.large`, 50GB gp3 SSD, Ubuntu 24.04.

## Install Locally

On Ubuntu 24.04 or WSL2 Ubuntu 24.04:

```bash
cd OpenClaw-Autonomous-Workstation
cp .env.example .env
sudo bash scripts/deploy_local.sh
```

Set `TAILSCALE_AUTHKEY` in `.env` before deployment for unattended Tailscale login. Otherwise run:

```bash
sudo tailscale up --ssh
```

## Verify

```bash
sudo bash scripts/verify_stack.sh
```

Expected endpoints:

- OpenClaw: `http://127.0.0.1:8080`
- Ollama: `http://127.0.0.1:11434`
- Prometheus: `http://127.0.0.1:9090`
- Grafana: `http://127.0.0.1:3000`

## AWS Spot Deployment

Full instructions are in [docs/aws_setup.md](docs/aws_setup.md).

Install and configure AWS CLI first, then:

```bash
cd OpenClaw-Autonomous-Workstation
cp .env.example .env
vi .env
bash aws/create_spot_instance.sh
```

The security group intentionally has no required public inbound ports. Use Tailscale for SSH, mobile access, Grafana, OpenClaw, and Ollama.

## Maintenance

```bash
sudo systemctl status ollama openclaw openclaw-stack
sudo journalctl -u openclaw -f
sudo bash scripts/backup_daily.sh
sudo docker compose -f /opt/openclaw/docker-compose.yml pull
sudo systemctl restart openclaw-stack
```

## Recovery

See [docs/recovery.md](docs/recovery.md) and [docs/troubleshooting.md](docs/troubleshooting.md).

## Upstream Note

The default OpenClaw source is `https://github.com/openclaw/openclaw.git`, based on the currently referenced public project path. Override `OPENCLAW_GIT_URL` and `OPENCLAW_BRANCH` in `.env` when using a fork, private mirror, or changed upstream.
