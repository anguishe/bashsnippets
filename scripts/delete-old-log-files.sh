#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/delete-old-log-files
# Delete Old Log Files
# find /var/log -name "*.log" -mtime +30 -delete removes every log file older than 30 days in one command.
# Always run with -print instead of -delete first — it previews exactly which files will be removed
# without touching anything. Swap to -delete when you're satisfied with the list.
# SAFE: swap -delete for -print to preview first.
#
# USAGE: ./cleanlog.sh
# REQUIRES: bash, find (pre-installed on all Linux/macOS)

LOG_DIR="/var/log/myapp"   # ← your log folder
DAYS=30                    # ← delete logs older than this many days

echo "Cleaning logs older than $DAYS days in $LOG_DIR..."

find "$LOG_DIR" -type f -name "*.log" \
  -mtime +$DAYS -delete

echo "✓ Done. Cleaned logs older than $DAYS days."
