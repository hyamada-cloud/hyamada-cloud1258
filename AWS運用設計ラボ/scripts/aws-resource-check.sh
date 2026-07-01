#!/bin/bash

# ============================================================
# AWS Resource Check Script
# 個人学習用：AWS CLI読み取り系コマンドによる構成確認スクリプト
#
# 注意：
# - 作成・変更・削除・起動停止系コマンドは含めない
# - 課金リソースは作成しない
# - 実行ログにはAWSリソースIDやアカウント情報が出る可能性があるため、
#   logsディレクトリの中身をGitHubへそのまま載せないこと
# ============================================================

set -u

REGION="${REGION:-us-east-1}"
VPC_ID="${VPC_ID:-}"

LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/aws-resource-check-$(date +%Y%m%d-%H%M%S).log"

ERROR_COUNT=0

mkdir -p "${LOG_DIR}"

log() {
  echo "$1" | tee -a "${LOG_FILE}"
}

section() {
  log ""
  log "============================================================"
  log "$1"
  log "============================================================"
}

run_check() {
  local title="$1"
  shift

  section "${title}"

  if "$@" 2>&1 | tee -a "${LOG_FILE}"; then
    log "[OK] ${title}"
  else
    log "[ERROR] ${title}"
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
}

log "AWS Resource Check Start"
log "Start Time : $(date '+%Y-%m-%d %H:%M:%S')"
log "User       : $(whoami)"
log "Host       : $(hostname)"
log "Region     : ${REGION}"

if [ -z "${VPC_ID}" ]; then
  log "VPC_ID     : Not set"
  log "Message    : VPC_ID is not set. Checks will run without VPC-specific filtering."
else
  log "VPC_ID     : Set by environment variable"
  log "Message    : VPC-specific checks will use the specified VPC_ID."
fi

section "AWS CLI Installed Check"

if command -v aws >/dev/null 2>&1; then
  log "[OK] AWS CLI command found."
else
  log "[ERROR] AWS CLI command not found."
  log "Please install AWS CLI or run this script in AWS CloudShell."
  log "End Time   : $(date '+%Y-%m-%d %H:%M:%S')"
  log "Final Result: ERROR"
  exit 1
fi

run_check "AWS CLI Version" aws --version

run_check "AWS Configure" aws configure list

run_check "Caller Identity" aws sts get-caller-identity

if [ -z "${VPC_ID}" ]; then
  run_check "VPC" aws ec2 describe-vpcs \
    --region "${REGION}" \
    --output json

  run_check "Subnets" aws ec2 describe-subnets \
    --region "${REGION}" \
    --output json

  run_check "Route Tables" aws ec2 describe-route-tables \
    --region "${REGION}" \
    --output json

  run_check "Internet Gateways" aws ec2 describe-internet-gateways \
    --region "${REGION}" \
    --output json

  run_check "Security Groups" aws ec2 describe-security-groups \
    --region "${REGION}" \
    --output json

  run_check "Network ACLs" aws ec2 describe-network-acls \
    --region "${REGION}" \
    --output json
else
  run_check "VPC" aws ec2 describe-vpcs \
    --region "${REGION}" \
    --vpc-ids "${VPC_ID}" \
    --output json

  run_check "Subnets" aws ec2 describe-subnets \
    --region "${REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --output json

  run_check "Route Tables" aws ec2 describe-route-tables \
    --region "${REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --output json

  run_check "Internet Gateways" aws ec2 describe-internet-gateways \
    --region "${REGION}" \
    --filters "Name=attachment.vpc-id,Values=${VPC_ID}" \
    --output json

  run_check "Security Groups" aws ec2 describe-security-groups \
    --region "${REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --output json

  run_check "Network ACLs" aws ec2 describe-network-acls \
    --region "${REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --output json
fi

run_check "EBS Volumes" aws ec2 describe-volumes \
  --region "${REGION}" \
  --output json

run_check "EBS Snapshots" aws ec2 describe-snapshots \
  --region "${REGION}" \
  --owner-ids self \
  --output json

run_check "RDS/Aurora DB Cluster Snapshots" aws rds describe-db-cluster-snapshots \
  --region "${REGION}" \
  --output json

run_check "Load Balancers" aws elbv2 describe-load-balancers \
  --region "${REGION}" \
  --output json

run_check "Target Groups" aws elbv2 describe-target-groups \
  --region "${REGION}" \
  --output json

log ""
log "AWS Resource Check End"
log "End Time   : $(date '+%Y-%m-%d %H:%M:%S')"
log "Error Count: ${ERROR_COUNT}"

if [ "${ERROR_COUNT}" -eq 0 ]; then
  log "Final Result: OK"
  exit 0
else
  log "Final Result: ERROR"
  exit 1
fi
