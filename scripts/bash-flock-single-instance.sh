#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/bash-flock-single-instance
# Script: backup-with-lock.sh
# Purpose: Stop a cron job from overlapping itself when one run runs long
# Usage: backup-with-lock.sh   (self-locking — safe to call from any */N cron)
set -euo pipefail

CHECK="✓"
CROSS="✗"

# /run/lock is tmpfs, cleared cleanly on reboot. Never /tmp — temp-cleaners
# delete files there, and a deleted lock mid-run lets a second copy run.
LOCK_FILE="/run/lock/$(basename "$0").lock"

# The > opens (and creates) the lock file on fd 200 and holds it open for the
# whole script. The LOCK lives on this open descriptor, not on the file
# existing — so never rm the file to "release" it.
exec 200>"$LOCK_FILE"

# -n = non-blocking: if a previous run still holds the lock, give up now
# instead of queueing another copy behind it.
if ! flock -n 200; then
    echo "$CROSS $(date '+%F %T') previous run still active — skipping" >&2
    exit 0
fi

echo "$CHECK $(date '+%F %T') lock acquired — starting"

# --- the real work ---
rsync -a --delete /data/ /mnt/backup/data/

echo "$CHECK $(date '+%F %T') finished — kernel releases the lock on exit"
