#!/bin/bash
# ─────────────────────────────────────────────────────────────
# backup.sh — Automated File Backup with Timestamp
# Copies a folder to a backup location stamped with
# the current date and time. Run manually or via cron.
#
# Usage:    ./backup.sh
# Schedule: crontab -e → 0 2 * * * ~/bash-scripts/scripts/backup.sh
# Author:   BashSnippets.xyz
# Full reference + explanation:
#           https://bashsnippets.xyz/snippets/automated-file-backup.html
# ─────────────────────────────────────────────────────────────

SOURCE="/home/user/documents"   # ← change to your folder
DEST="/backup"                  # ← change to your backup location
DATE=$(date +%Y-%m-%d_%H-%M)

mkdir -p "$DEST"
cp -r "$SOURCE" "$DEST/backup_$DATE"
echo "✓ Done. Saved to: $DEST/backup_$DATE"
