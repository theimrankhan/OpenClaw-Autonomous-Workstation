#!/usr/bin/env bash
set -Eeuo pipefail
source ./.env 2>/dev/null || true
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_SECURITY_GROUP_NAME="${AWS_SECURITY_GROUP_NAME:-openclaw-workstation}"
VPC_ID="$(aws ec2 describe-vpcs --region "$AWS_REGION" --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)"
SG_ID="$(aws ec2 describe-security-groups --region "$AWS_REGION" --filters Name=group-name,Values="$AWS_SECURITY_GROUP_NAME" Name=vpc-id,Values="$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text)"
aws ec2 revoke-security-group-ingress --region "$AWS_REGION" --group-id "$SG_ID" --ip-permissions "$(aws ec2 describe-security-groups --region "$AWS_REGION" --group-ids "$SG_ID" --query 'SecurityGroups[0].IpPermissions' --output json)" 2>/dev/null || true
echo "Security group ${SG_ID} has no inbound rules. Use Tailscale for SSH, Grafana, OpenClaw, and Ollama."
