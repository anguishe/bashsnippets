#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/find-large-files-linux
# Script: find-large-files.sh
# Purpose: Identify the largest files and directories consuming disk space
# Usage: sudo ./find-large-files.sh [directory] [min-size]
set -euo pipefail

CHECK="✓"
CROSS="✗"

TARGET_DIR="${1:-/}"
MIN_SIZE="${2:-500M}"
TOP_COUNT=20

echo "=== Top $TOP_COUNT largest entries under $TARGET_DIR ==="
du -ah "$TARGET_DIR" --exclude=/proc --exclude=/sys --exclude=/dev 2>/dev/null \
  | sort -rh \
  | head -n "$TOP_COUNT"

echo ""
echo "=== Individual files larger than $MIN_SIZE ==="
find "$TARGET_DIR" -type f -size +"$MIN_SIZE" \
  -not -path "/proc/*" \
  -not -path "/sys/*" \
  -not -path "/dev/*" \
  -exec ls -lh {} \; 2>/dev/null \
  | sort -k5 -rh

echo ""
echo "$CHECK Scan complete. Review the output above and remove or compress the largest offenders."
