# AWS Setup Guide

This guide launches OpenClaw-Autonomous-Workstation on an AWS EC2 Spot Instance:

- Instance type: `m7i-flex.large`
- OS: Ubuntu 24.04
- Disk: 50GB encrypted gp3 SSD
- Access: Tailscale, no public inbound ports
- Runtime: Docker, Ollama, OpenClaw, Prometheus, Grafana, Node Exporter

## 1. Prepare Your Local Machine

Install these locally:

- Git
- AWS CLI v2
- A terminal with Bash support, preferably Ubuntu 24.04 on WSL2

Verify:

```bash
git --version
aws --version
```

If you are on Windows and WSL2 is not installed:

```powershell
wsl --install -d Ubuntu-24.04
```

Restart Windows if prompted, then open Ubuntu.

## 2. Create an AWS IAM User or Role

Use an AWS identity that can manage EC2 resources. Minimum practical permissions for this deployment:

- `ec2:RunInstances`
- `ec2:DescribeImages`
- `ec2:DescribeInstances`
- `ec2:DescribeVpcs`
- `ec2:DescribeAvailabilityZones`
- `ec2:DescribeSecurityGroups`
- `ec2:CreateSecurityGroup`
- `ec2:AuthorizeSecurityGroupEgress`
- `ec2:RevokeSecurityGroupIngress`
- `ec2:CreateTags`
- `iam:PassRole` only if you later attach an instance profile

For a personal first deployment, using `AmazonEC2FullAccess` temporarily is simpler. Replace it with least privilege after the system is working.

Configure AWS CLI:

```bash
aws configure
```

Recommended defaults:

```text
AWS Access Key ID: <your-access-key>
AWS Secret Access Key: <your-secret>
Default region name: us-east-1
Default output format: json
```

Verify:

```bash
aws sts get-caller-identity
```

## 3. Choose a Region

Start with `us-east-1` unless you have a reason to run elsewhere.

Good defaults:

```bash
export AWS_REGION=us-east-1
```

Check that `m7i-flex.large` is available:

```bash
aws ec2 describe-instance-type-offerings \
  --region "$AWS_REGION" \
  --location-type availability-zone \
  --filters Name=instance-type,Values=m7i-flex.large \
  --query 'InstanceTypeOfferings[].Location' \
  --output table
```

## 4. Create an EC2 Key Pair

Even though Tailscale is the main access method, keep an EC2 key pair as emergency access.

```bash
aws ec2 create-key-pair \
  --region "$AWS_REGION" \
  --key-name openclaw-key \
  --key-type ed25519 \
  --query 'KeyMaterial' \
  --output text > openclaw-key.pem

chmod 400 openclaw-key.pem
```

On Windows PowerShell:

```powershell
icacls .\openclaw-key.pem /inheritance:r
icacls .\openclaw-key.pem /grant:r "$env:USERNAME:R"
```

## 5. Create a Tailscale Auth Key

In the Tailscale admin console:

1. Go to **Settings > Keys**.
2. Generate an auth key.
3. Prefer a non-ephemeral key for this workstation.
4. Keep the expiry reasonable.
5. Copy the key once.

Do not commit this key to Git.

## 6. Publish or Copy This Repository

The AWS bootstrap needs to fetch this repo. Use one of these paths:

Option A: push to a private GitHub repo:

```bash
git remote add origin git@github.com:<you>/OpenClaw-Autonomous-Workstation.git
git add OpenClaw-Autonomous-Workstation
git commit -m "Initial OpenClaw autonomous workstation"
git push -u origin main
```

Option B: upload the directory manually to the EC2 instance after launch.

Option A is cleaner because user data can install everything automatically.

## 7. Configure `.env`

From the repo root:

```bash
cd OpenClaw-Autonomous-Workstation
cp .env.example .env
nano .env
```

Set:

```env
AWS_REGION=us-east-1
AWS_INSTANCE_TYPE=m7i-flex.large
AWS_VOLUME_SIZE_GB=50
AWS_KEY_NAME=openclaw-key
AWS_SECURITY_GROUP_NAME=openclaw-workstation
TAILSCALE_AUTHKEY=tskey-auth-xxxxxxxx
REPO_URL=https://github.com/<you>/OpenClaw-Autonomous-Workstation.git
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=use-a-long-random-password
```

If your repo is private, use a deploy key or a private package/bootstrap method. Do not put a GitHub personal access token directly into user data unless you understand the exposure risk.

## 8. Launch the Spot Instance

Run:

```bash
bash aws/create_spot_instance.sh
```

The script will:

- Inspect your AWS caller identity.
- Find the latest Ubuntu 24.04 AMD64 AMI.
- Create or reuse a security group.
- Use no inbound public ports.
- Launch `m7i-flex.large` as a persistent Spot Instance.
- Use `stop` as the Spot interruption behavior.
- Create a 50GB encrypted gp3 root volume.
- Run the bootstrap script.

Save the returned instance ID:

```bash
export INSTANCE_ID=i-xxxxxxxxxxxxxxxxx
```

Watch startup:

```bash
aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].{State:State.Name,PublicIp:PublicIpAddress,PrivateIp:PrivateIpAddress}' \
  --output table
```

## 9. Wait for Bootstrap

Give the instance 10 to 20 minutes. The first run installs Docker, Ollama, OpenClaw, monitoring, Tailscale, and pulls `qwen2.5:7b`.

Check cloud-init logs over SSH if needed:

```bash
ssh -i openclaw-key.pem ubuntu@<public-ip>
sudo tail -f /var/log/cloud-init-output.log
sudo tail -f /opt/openclaw/logs/aws-bootstrap.log
```

If you use Tailscale successfully, prefer:

```bash
tailscale ssh ubuntu@<tailscale-device-name>
```

## 10. Verify Services on the Instance

Run on the EC2 instance:

```bash
cd /opt/OpenClaw-Autonomous-Workstation
sudo bash scripts/verify_stack.sh
```

Manual checks:

```bash
sudo systemctl status ollama openclaw openclaw-stack --no-pager
curl -fsS http://127.0.0.1:11434/api/tags
curl -fsS http://127.0.0.1:8080/health
curl -fsS http://127.0.0.1:9090/-/healthy
curl -fsS http://127.0.0.1:3000/api/health
```

Confirm the model:

```bash
ollama list
```

Expected model:

```text
qwen2.5:7b
```

## 11. Access the System Securely

Use Tailscale device IP or MagicDNS:

- OpenClaw: `http://<tailscale-ip>:8080`
- Grafana: `http://<tailscale-ip>:3000`
- Ollama: `http://<tailscale-ip>:11434`
- Prometheus: `http://<tailscale-ip>:9090`

Do not open these ports to the public internet.

## 12. Confirm Security

On the EC2 instance:

```bash
sudo ufw status verbose
sudo fail2ban-client status
sudo sshd -T | grep -E 'passwordauthentication|permitrootlogin|pubkeyauthentication'
```

Expected:

```text
passwordauthentication no
permitrootlogin no
pubkeyauthentication yes
```

In AWS, confirm the security group has no inbound rules:

```bash
bash aws/security_group_tailscale_only.sh
```

## 13. Confirm Monitoring

In Grafana:

1. Open `http://<tailscale-ip>:3000`.
2. Log in with `GRAFANA_ADMIN_USER` and `GRAFANA_ADMIN_PASSWORD`.
3. Open dashboard folder `OpenClaw`.
4. Confirm CPU, RAM, Disk, and Network panels show data.

Prometheus alerts are in:

```text
/opt/openclaw/monitoring/prometheus/alerts.yml
```

Local alert scripts are:

```bash
scripts/alert_cpu.sh
scripts/alert_ram.sh
scripts/alert_disk.sh
```

## 14. Confirm Backups

Run:

```bash
sudo systemctl status openclaw-backup.timer --no-pager
sudo bash scripts/backup_daily.sh
ls -lh /opt/openclaw/backups
```

Backups include:

- OpenClaw configs
- Docker Compose config
- Logs
- Backup script
- systemd units

## 15. Spot Instance Behavior

This deployment uses a persistent Spot request with interruption behavior `stop`.

That means:

- AWS can still interrupt the instance.
- The instance stops instead of terminating when possible.
- EBS-backed data survives stop/start.
- AWS can restart it when compatible Spot capacity returns.
- systemd and Docker restart policies recover the workstation after boot.

This is cost-efficient, not guaranteed always-on capacity. For strict uptime, use On-Demand or an Auto Scaling Group with multiple instance types.

## 16. Stop, Start, and Terminate

Stop to save compute cost:

```bash
aws ec2 stop-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID"
```

Start again:

```bash
aws ec2 start-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID"
```

Terminate when done:

```bash
aws ec2 terminate-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID"
```

After termination, check for leftover Spot requests, EBS volumes, and snapshots:

```bash
aws ec2 describe-spot-instance-requests --region "$AWS_REGION" --output table
aws ec2 describe-volumes --region "$AWS_REGION" --filters Name=status,Values=available --output table
```

## 17. Troubleshooting

If bootstrap failed:

```bash
sudo tail -n 200 /var/log/cloud-init-output.log
sudo tail -n 200 /opt/openclaw/logs/aws-bootstrap.log
```

If Docker failed:

```bash
sudo systemctl status docker --no-pager
sudo docker ps -a
sudo docker compose -f /opt/openclaw/docker-compose.yml logs --tail=100
```

If Ollama is missing the model:

```bash
sudo systemctl restart ollama
ollama pull qwen2.5:7b
```

If Tailscale did not authenticate:

```bash
sudo tailscale up --ssh
tailscale status
```

If SSH hardening blocks access, use the AWS console serial console or recovery mode, then run:

```bash
sudo /opt/OpenClaw-Autonomous-Workstation/security/rollback_security.sh
```
