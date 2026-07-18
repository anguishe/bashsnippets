#!/bin/bash

CHECK="✓"
CROSS="✗"

# --- Configuration ---
THRESHOLD=80
EMAIL="you@example.com"
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# --- Check disk usage on root partition ---
USAGE=$(df / | awk 'NR==2{print $5}' | tr -d '%')

echo "[$DATE] Disk usage: ${USAGE}%"

if [ "$USAGE" -gt "$THRESHOLD" ]; then
  echo "$CROSS Disk at ${USAGE}% — sending alert to $EMAIL"

  MESSAGE="[DISK ALERT] ${HOSTNAME}

Disk usage on / is at ${USAGE}% as of ${DATE}.
Threshold: ${THRESHOLD}%

Top disk consumers:
$(du -sh /* 2>/dev/null | sort -rh | head -5)

-- BashSnippets monitor"

  echo "$MESSAGE" | mail -s "[ALERT] Disk Space on ${HOSTNAME}" "$EMAIL"
  echo "$CHECK Alert sent to $EMAIL"
else
  echo "$CHECK Disk OK at ${USAGE}%"
fi
