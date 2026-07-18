#!/bin/bash
# Create a dated folder with an optional name
# USAGE: ./mkdate.sh [optional-name]
# EXAMPLE: ./mkdate.sh deployment → creates 2026-05-03_deployment

DATE=$(date +%Y-%m-%d)
NAME="${1:-folder}"       # ← uses "folder" if no argument given
FULL="${DATE}_${NAME}"

mkdir -p "$FULL"
echo "✓ Created: $FULL"
cd "$FULL"
