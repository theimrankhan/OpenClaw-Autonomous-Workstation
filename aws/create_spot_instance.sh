#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${PROJECT_DIR}/.env" 2>/dev/null || true

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_INSTANCE_TYPE="${AWS_INSTANCE_TYPE:-m7i-flex.large}"
AWS_VOLUME_SIZE_GB="${AWS_VOLUME_SIZE_GB:-50}"
AWS_SECURITY_GROUP_NAME="${AWS_SECURITY_GROUP_NAME:-openclaw-workstation}"
AWS_KEY_NAME="${AWS_KEY_NAME:?Set AWS_KEY_NAME in .env or environment}"
REPO_URL="${REPO_URL:-https://github.com/replace-me/OpenClaw-Autonomous-Workstation.git}"

echo "Inspecting AWS caller and region"
aws sts get-caller-identity
aws ec2 describe-availability-zones --region "$AWS_REGION" --query 'AvailabilityZones[0].ZoneName' --output text

echo "Creating or reusing security group"
VPC_ID="$(aws ec2 describe-vpcs --region "$AWS_REGION" --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)"
SG_ID="$(aws ec2 describe-security-groups --region "$AWS_REGION" --filters Name=group-name,Values="$AWS_SECURITY_GROUP_NAME" Name=vpc-id,Values="$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)"
if [[ "$SG_ID" == "None" || -z "$SG_ID" ]]; then
  SG_ID="$(aws ec2 create-security-group --region "$AWS_REGION" --group-name "$AWS_SECURITY_GROUP_NAME" --description "OpenClaw Tailscale-only workstation" --vpc-id "$VPC_ID" --query GroupId --output text)"
fi
aws ec2 authorize-security-group-egress --region "$AWS_REGION" --group-id "$SG_ID" --ip-permissions IpProtocol=-1,IpRanges='[{CidrIp=0.0.0.0/0,Description=Outbound}]' 2>/dev/null || true

echo "Finding Ubuntu 24.04 AMI"
AMI_ID="$(aws ec2 describe-images --region "$AWS_REGION" --owners 099720109477 --filters 'Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*' 'Name=state,Values=available' --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text)"

USER_DATA="$(mktemp)"
cat >"$USER_DATA" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
apt-get update
apt-get install -y git ca-certificates curl
git clone __REPO_URL__ /opt/OpenClaw-Autonomous-Workstation || true
cd /opt/OpenClaw-Autonomous-Workstation
chmod +x scripts/*.sh aws/*.sh security/*.sh
scripts/deploy_local.sh
EOF
sed -i "s#__REPO_URL__#${REPO_URL}#g" "$USER_DATA"

echo "Requesting persistent Spot instance with automatic recovery behavior through restart policies"
aws ec2 run-instances \
  --region "$AWS_REGION" \
  --image-id "$AMI_ID" \
  --instance-type "$AWS_INSTANCE_TYPE" \
  --key-name "$AWS_KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --instance-market-options 'MarketType=spot,SpotOptions={SpotInstanceType=persistent,InstanceInterruptionBehavior=stop}' \
  --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=${AWS_VOLUME_SIZE_GB},VolumeType=gp3,DeleteOnTermination=true,Encrypted=true}" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=OpenClaw-Autonomous-Workstation},{Key=CostProfile,Value=Spot-Minimal}]' \
  --user-data "file://${USER_DATA}" \
  --query 'Instances[0].InstanceId' \
  --output text

rm -f "$USER_DATA"
