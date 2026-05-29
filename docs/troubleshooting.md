# Troubleshooting

## Logs

```bash
sudo journalctl -u ollama -n 100 --no-pager
sudo journalctl -u openclaw -n 100 --no-pager
sudo journalctl -u openclaw-stack -n 100 --no-pager
sudo tail -n 100 /opt/openclaw/logs/*.log
```

## Health Checks

```bash
curl -fsS http://127.0.0.1:11434/api/tags
curl -fsS http://127.0.0.1:8080/health
curl -fsS http://127.0.0.1:9090/-/healthy
curl -fsS http://127.0.0.1:3000/api/health
```

## Common Fixes

- If Ollama has no model, run `sudo ollama pull qwen2.5:7b`.
- If OpenClaw does not start, inspect `/opt/openclaw/app` and adjust `services/openclaw.service` for the upstream command.
- If Grafana login fails, reset the password with `docker exec -it openclaw-grafana grafana cli admin reset-admin-password NEW_PASSWORD`.
- If disk is full, inspect Docker usage with `docker system df` and backups under `/opt/openclaw/backups`.
