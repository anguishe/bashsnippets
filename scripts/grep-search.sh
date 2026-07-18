#!/bin/bash
# Search files for text — grep reference
# Replace KEYWORD and SEARCH_DIR with your values
#
# USAGE: ./grep-search.sh
# REQUIRES: grep (pre-installed on Linux/macOS)

KEYWORD="TODO"          # ← what to search for
SEARCH_DIR="$HOME"    # ← where to search
FILE_TYPE="*.txt"     # ← file types to include

echo "Searching for '$KEYWORD' in $SEARCH_DIR..."
echo "────────────────────────────────────────"

grep -rn "$KEYWORD" "$SEARCH_DIR" \
  --include="$FILE_TYPE" \
  --color=auto

COUNT=$(grep -rc "$KEYWORD" "$SEARCH_DIR" \
  --include="$FILE_TYPE" 2>/dev/null \
  | grep -v ":0$" | wc -l)

echo "────────────────────────────────────────"
echo "Found in $COUNT file(s)"
