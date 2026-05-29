# Recovery

## Reboot Recovery

The following services are enabled at boot:

- `ollama.service`
- `openclaw.service`
- `openclaw-stack.service`
- `openclaw-backup.timer`
- `tailscaled.service`
- `fail2ban.service`

Run:

```bash
sudo systemctl status ollama openclaw openclaw-stack openclaw-backup.timer tailscaled fail2ban
sudo /opt/OpenClaw-Autonomous-Workstation/scripts/verify_stack.sh
```

## Restore Backups

Daily archives are stored in `/opt/openclaw/backups`.

```bash
sudo tar -xzf /opt/openclaw/backups/openclaw-backup-YYYYMMDDTHHMMSSZ.tar.gz -C /
sudo systemctl daemon-reload
sudo systemctl restart ollama openclaw openclaw-stack
```

## Security Rollback

Use this only if SSH hardening locked out a desired authentication path:

```bash
sudo /opt/OpenClaw-Autonomous-Workstation/security/rollback_security.sh
```
