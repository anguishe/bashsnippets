#!/bin/bash
# diskcheck.sh — warn when disk usage exceeds a threshold
set -euo pipefail

THRESHOLD=80
PARTITION="/"

USAGE=$(df "$PARTITION" | awk 'NR==2 {print $5}' | tr -d '%')

if [ "$USAGE" -gt "$THRESHOLD" ]; then
  echo "WARNING: Disk usage on $PARTITION is at ${USAGE}% (threshold: ${THRESHOLD}%)"
  exit 1
else
  echo "OK: Disk usage on $PARTITION is at ${USAGE}%"
  exit 0
fi
