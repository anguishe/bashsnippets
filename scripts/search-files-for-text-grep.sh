#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/search-files-for-text-grep
# Search files for text — grep reference
# Replace KEYWORD and SEARCH_DIR with your values
#
# USAGE: ./grep-search.sh
# REQUIRES: grep (pre-installed on Linux/macOS)
set -euo pipefail

KEYWORD="TODO"          # ← what to search for
SEARCH_DIR="$HOME"    # ← where to search
FILE_TYPE="*.txt"     # ← file types to include

echo "Searching for '$KEYWORD' in $SEARCH_DIR..."
echo "────────────────────────────────────────"

grep -rn "$KEYWORD" "$SEARCH_DIR" \
  --include="$FILE_TYPE" \
  --color=auto || true   # grep exits 1 on no matches; that is not an error here

COUNT=$(grep -rc "$KEYWORD" "$SEARCH_DIR" \
  --include="$FILE_TYPE" 2>/dev/null \
  | grep -cv ":0$" || true)

echo "────────────────────────────────────────"
echo "Found in $COUNT file(s)"
