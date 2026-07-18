#!/bin/bash
# Script: backup-exports.sh
# Purpose: copy export files to a backup dir without losing ones with spaces
# Usage: ./backup-exports.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"
SRC_DIR="/data/exports"
DEST_DIR="/backup/exports"
shopt -s nullglob   # an empty match expands to nothing, not the literal pattern

for f in "$SRC_DIR"/*.xlsx; do
  if cp -- "$f" "$DEST_DIR/"; then
    echo "$CHECK backed up: $(basename "$f")"
  else
    echo "$CROSS failed: $(basename "$f")"
  fi
done
