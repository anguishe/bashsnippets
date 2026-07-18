#!/bin/bash
# Script: find-dupes.sh
# Purpose: Recover disk space lost to byte-for-byte duplicate files across directories
# Usage: ./find-dupes.sh [directory]
set -euo pipefail

CHECK="✓"
CROSS="✗"

TARGET="${1:-$HOME/Downloads}"

if [[ ! -d "$TARGET" ]]; then
  echo "$CROSS Directory not found: $TARGET" >&2
  exit 1
fi

echo "Scanning for duplicates in $TARGET..."
echo ""

find "$TARGET" -type f \
  | xargs -r md5sum 2>/dev/null \
  | sort \
  | awk 'seen[$1]++'

echo ""
echo "$CHECK Scan complete — lines above are duplicate copies (review before deleting)"
