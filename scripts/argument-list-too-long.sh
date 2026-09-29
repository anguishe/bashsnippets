#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/argument-list-too-long
# Script: bulk-delete-files.sh
# Purpose: rm ./*.log on a directory with hundreds of thousands of files dies with "Argument list too long" and deletes nothing — this deletes by pattern with find, which never builds an argument list, and dry-runs first.
# Usage: ./bulk-delete-files.sh DIR PATTERN [--apply]   e.g. ./bulk-delete-files.sh /var/spool/app '*.log' --apply
set -euo pipefail
export LC_ALL=C

CHECK="✓"
CROSS="✗"

DIR="${1:?usage: $0 DIR PATTERN [--apply]}"
PATTERN="${2:?usage: $0 DIR PATTERN [--apply]}"
APPLY=0
[[ "${3:-}" == "--apply" ]] && APPLY=1

[[ -d "$DIR" ]] || { echo "$CROSS $DIR is not a directory" >&2; exit 2; }
[[ "$(realpath "$DIR")" == "/" ]] && { echo "$CROSS refusing to run on /" >&2; exit 2; }

# -maxdepth 1 matches what the shell glob would have matched: this directory only.
# -printf . prints one byte per file, so counting 500,000 names never holds them in memory.
COUNT=$(find "$DIR" -maxdepth 1 -type f -name "$PATTERN" -printf . | wc -c)

if (( COUNT == 0 )); then
  echo "$CROSS no files matching '$PATTERN' in $DIR" >&2
  exit 1
fi

echo "$COUNT files match '$PATTERN' in $DIR (ARG_MAX here: $(getconf ARG_MAX) bytes)"
if (( ! APPLY )); then
  echo "dry run: re-run with --apply to delete them"
  exit 0
fi

find "$DIR" -maxdepth 1 -type f -name "$PATTERN" -delete
echo "$CHECK deleted $COUNT files; $(find "$DIR" -maxdepth 1 -type f -name "$PATTERN" -printf . | wc -c) matching files remain"
