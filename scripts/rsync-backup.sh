#!/bin/bash
# Script: rsync-backup.sh
# Purpose: Push incremental backups to a remote server over SSH
# Usage: ./rsync-backup.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"

SOURCE_DIR="/home/user/projects/"
REMOTE_USER="backups"
REMOTE_HOST="backup-server.example.com"
REMOTE_DIR="/backup/projects/"
EXCLUDE_FILE="/home/user/.rsync-excludes"
LOG_FILE="/var/log/rsync-backup.log"

SSH_KEY="/home/user/.ssh/id_ed25519"
BANDWIDTH_LIMIT=0

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting backup: $SOURCE_DIR -> $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR" | tee -a "$LOG_FILE"

RSYNC_OPTS=(
  -avz
  --delete
  --partial
  --progress
  -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=accept-new"
)

if [ -f "$EXCLUDE_FILE" ]; then
  RSYNC_OPTS+=(--exclude-from="$EXCLUDE_FILE")
fi

if [ "$BANDWIDTH_LIMIT" -gt 0 ]; then
  RSYNC_OPTS+=(--bwlimit="$BANDWIDTH_LIMIT")
fi

if rsync "${RSYNC_OPTS[@]}" "$SOURCE_DIR" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR" 2>&1 | tee -a "$LOG_FILE"; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $CHECK Backup completed successfully" | tee -a "$LOG_FILE"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $CROSS Backup FAILED (exit code: $?)" | tee -a "$LOG_FILE"
  exit 1
fi
