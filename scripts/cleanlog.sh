#!/bin/bash
# ─────────────────────────────────────────────────────────────
# cleanlog.sh — Delete Old Log Files
# Finds and deletes .log files older than N days using find.
# Always run with -print first to preview before -delete.
#
# Usage:    ./cleanlog.sh
# Schedule: crontab -e → 0 3 * * 0 ~/bash-scripts/scripts/cleanlog.sh
# Author:   BashSnippets.xyz
# Full reference + explanation:
#           https://bashsnippets.xyz/snippets/delete-old-log-files.html
# ─────────────────────────────────────────────────────────────

LOG_DIR="/var/log/myapp"   # ← change to your log folder
DAYS=30                    # ← delete files older than this many days

echo "Cleaning logs older than $DAYS days in $LOG_DIR..."

find "$LOG_DIR" -type f -name "*.log" \
  -mtime +$DAYS -delete

echo "✓ Done. Cleaned logs older than $DAYS days."
