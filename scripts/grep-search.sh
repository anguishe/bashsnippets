#!/bin/bash
# ─────────────────────────────────────────────────────────────
# grep-search.sh — Search Files for Text Recursively
# Uses grep -rn to search every file in a directory
# and return each match with filename and line number.
#
# Usage:    ./grep-search.sh
# Author:   BashSnippets.xyz
# Full reference + flags guide:
#           https://bashsnippets.xyz/snippets/search-files-for-text-grep.html
# ─────────────────────────────────────────────────────────────

KEYWORD="TODO"           # ← what to search for
SEARCH_DIR="$HOME"       # ← where to search
FILE_TYPE="*.txt"        # ← file types to include

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
