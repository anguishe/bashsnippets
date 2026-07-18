#!/bin/bash
# Script: bounded-dump.sh
# Purpose: Stop a hung command from running forever and jamming the cron slot
# Usage: bounded-dump.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"

# Longer than the job's normal worst case, well under its cron interval.
MAX_RUNTIME="5m"
# After SIGTERM, wait this long, then SIGKILL — for processes wedged in I/O.
KILL_GRACE="20s"

DEST="/backup/mydb.sql"

# In an `if` so set -e doesn't abort before we read the exit code.
# Write to a .partial file so a timed-out run never leaves a corrupt "backup".
if timeout -k "$KILL_GRACE" "$MAX_RUNTIME" \
        mysqldump --single-transaction mydb > "$DEST.partial"; then
    mv "$DEST.partial" "$DEST"
    echo "$CHECK dump completed within $MAX_RUNTIME"
else
    code=$?
    rm -f "$DEST.partial"
    case "$code" in
        124) echo "$CROSS dump exceeded $MAX_RUNTIME and was terminated (SIGTERM)" >&2 ;;
        137) echo "$CROSS dump ignored SIGTERM and was force-killed (SIGKILL)" >&2 ;;
        *)   echo "$CROSS dump failed with exit code $code" >&2 ;;
    esac
    exit "$code"
fi
