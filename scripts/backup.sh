#!/bin/bash
# Script: backup.sh
# Purpose: Prevent data loss from disk failure or accidental deletion with timestamped backups
# Usage: ./backup.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"

SOURCE="/home/user/documents"
DEST="/backup"
DATE=$(date +%Y-%m-%d_%H-%M)

mkdir -p "$DEST"

if cp -r "$SOURCE" "$DEST/backup_$DATE"; then
  echo "$CHECK Done. Saved to: $DEST/backup_$DATE"
else
  echo "$CROSS Backup failed — check that $SOURCE exists and $DEST is writable"
  exit 1
fi
