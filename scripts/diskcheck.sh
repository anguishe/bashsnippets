#!/bin/bash
# ─────────────────────────────────────────────────────────────
# diskcheck.sh — Disk Space Warning Script
# Checks disk usage and warns when it crosses a threshold.
#
# Usage:    ./diskcheck.sh
# Schedule: Add to crontab -e for automatic monitoring
# Author:   BashSnippets.xyz
# Full reference + explanation:
#           https://bashsnippets.xyz/snippets/disk-space-warning.html
# ─────────────────────────────────────────────────────────────

THRESHOLD=80    # warn when disk exceeds this %

USAGE=$(df / | awk 'NR==2{print $5}' | tr -d '%')

if [ "$USAGE" -gt "$THRESHOLD" ]; then
  echo "⚠ Disk usage at ${USAGE}% — above ${THRESHOLD}% threshold. Clean up."
else
  echo "✓ Disk usage at ${USAGE}% — within threshold."
fi
