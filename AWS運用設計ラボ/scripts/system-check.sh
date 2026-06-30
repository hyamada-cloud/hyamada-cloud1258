#!/usr/bin/env bash

# system-check.sh
# Linuxサーバ運用を想定した基本状態確認スクリプト
# 個人学習用。削除・変更・課金につながる処理は行わない。

set -u

LOG_DIR="${LOG_DIR:-./logs}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/system-check-$(date '+%Y%m%d-%H%M%S').log}"
DISK_THRESHOLD="${DISK_THRESHOLD:-80}"
MEM_THRESHOLD="${MEM_THRESHOLD:-80}"
PROCESS_NAME="${PROCESS_NAME:-}"
STATUS=0

mkdir -p "$LOG_DIR"

log() {
  local level="$1"
  local message="$2"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [${level}] ${message}" | tee -a "$LOG_FILE"
}

check_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    log "ERROR" "Required command not found: ${command_name}"
    STATUS=1
    return 1
  fi

  return 0
}

log "INFO" "System check started."
log "INFO" "Log file: ${LOG_FILE}"

log "INFO" "===== Basic information ====="
log "INFO" "Hostname: $(hostname)"
log "INFO" "Current user: $(whoami)"

if [ -f /etc/os-release ]; then
  OS_NAME=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
  log "INFO" "OS: ${OS_NAME}"
else
  log "WARN" "/etc/os-release was not found."
fi

log "INFO" "===== Disk usage check ====="
if check_command df; then
  DISK_USAGE=$(df -P / | awk 'NR==2 {gsub("%", "", $5); print $5}')
  log "INFO" "Root disk usage: ${DISK_USAGE}% / threshold: ${DISK_THRESHOLD}%"

  if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
    log "ERROR" "Disk usage is over threshold."
    STATUS=1
  else
    log "INFO" "Disk usage is normal."
  fi
fi

log "INFO" "===== Memory usage check ====="
if check_command free; then
  MEM_USAGE=$(free | awk '/Mem:/ {printf "%d", ($3 / $2) * 100}')
  log "INFO" "Memory usage: ${MEM_USAGE}% / threshold: ${MEM_THRESHOLD}%"

  if [ "$MEM_USAGE" -ge "$MEM_THRESHOLD" ]; then
    log "ERROR" "Memory usage is over threshold."
    STATUS=1
  else
    log "INFO" "Memory usage is normal."
  fi
fi

log "INFO" "===== Process check ====="
if [ -z "$PROCESS_NAME" ]; then
  log "INFO" "PROCESS_NAME is not set. Process check was skipped."
else
  if check_command pgrep; then
    if pgrep -x "$PROCESS_NAME" >/dev/null 2>&1 || pgrep -f "$PROCESS_NAME" >/dev/null 2>&1; then
      log "INFO" "Process is running: ${PROCESS_NAME}"
    else
      log "ERROR" "Process is not running: ${PROCESS_NAME}"
      STATUS=1
    fi
  fi
fi

log "INFO" "===== Result ====="
if [ "$STATUS" -eq 0 ]; then
  log "INFO" "System check completed successfully."
  exit 0
else
  log "ERROR" "System check completed with errors."
  exit 1
fi
