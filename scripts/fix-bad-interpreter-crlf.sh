#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/fix-bad-interpreter-crlf
# Script: crlf-check.sh
# Purpose: A script saved with Windows CRLF line endings dies with "/bin/bash^M: bad interpreter" or "$'\r': command not found" — this finds every text file with carriage returns under the given paths and strips them.
# Usage: ./crlf-check.sh [--apply] PATH...   (dry run by default)
set -euo pipefail

CHECK="✓"
CROSS="✗"

APPLY=0
if [[ "${1:-}" == "--apply" ]]; then APPLY=1; shift; fi
[[ $# -gt 0 ]] || { echo "usage: $0 [--apply] PATH..." >&2; exit 2; }

# -I skips binary files: a CR byte inside an image or a tarball is data, not a line ending.
mapfile -t FILES < <(grep -rlI $'\r$' -- "$@" 2>/dev/null || true)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "$CHECK no CRLF line endings under: $*"
  exit 0
fi

for f in "${FILES[@]}"; do
  echo "$CROSS $f — $(grep -c $'\r$' "$f") CRLF lines ($(file -b "$f"))"
done

if (( ! APPLY )); then
  echo "dry run: re-run with --apply to convert ${#FILES[@]} file(s) to LF"
  exit 1
fi

for f in "${FILES[@]}"; do
  # Only a CR at end of line is stripped; a CR in the middle of a line is left for a human.
  sed -i 's/\r$//' "$f"
done
echo "$CHECK converted ${#FILES[@]} file(s) to LF"
