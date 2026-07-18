#!/bin/bash
# Script: disk-if-else.sh
# Purpose: Classify disk usage into critical, warning, or OK — three-branch if/elif/else
# Usage: ./disk-if-else.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"

THRESHOLD=80
CRITICAL=90
PARTITION="/"

USAGE=$(df "$PARTITION" | awk 'NR==2{print $5}' | tr -d '%')

if [ "$USAGE" -gt "$CRITICAL" ]; then
  echo "$CROSS CRITICAL: Disk at ${USAGE}% — free space immediately"
elif [ "$USAGE" -gt "$THRESHOLD" ]; then
  echo "$CROSS WARNING: Disk at ${USAGE}% — above ${THRESHOLD}% threshold"
else
  echo "$CHECK OK: Disk at ${USAGE}% (warn: ${THRESHOLD}%, critical: ${CRITICAL}%)"
fi
