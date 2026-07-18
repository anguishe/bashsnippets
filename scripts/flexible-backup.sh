#!/bin/bash
# Script: flexible-backup.sh
# Purpose: Without required-arg validation, a missing --source backs up an empty path silently.
# Usage: ./flexible-backup.sh --source DIR --dest DIR [--days N] [--dry-run]
set -euo pipefail

CHECK="✓"
CROSS="✗"

src=""
dest=""
retention_days=30   # named default, not a magic number buried in the logic
dry_run=0

# Usage goes to stderr so it does not pollute piped stdout.
usage() {
  echo "Usage: flexible-backup.sh --source DIR --dest DIR [--days N] [--dry-run]" >&2
  exit "${1:-1}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)  src="$2"; shift 2 ;;
    --dest)    dest="$2"; shift 2 ;;
    --days)    retention_days="$2"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage 0 ;;
    --)        shift; break ;;
    -*)        echo "$CROSS Unknown option: $1" >&2; usage ;;
    *)         echo "$CROSS Unexpected argument: $1" >&2; usage ;;
  esac
done

# Validate required arguments AFTER parsing — never assume they were set.
[[ -n "$src"  ]] || { echo "$CROSS --source is required"; usage; }
[[ -n "$dest" ]] || { echo "$CROSS --dest is required";   usage; }
[[ -d "$src"  ]] || { echo "$CROSS source dir not found: $src" >&2; exit 1; }

if [[ "$dry_run" -eq 1 ]]; then
  echo "$CHECK DRY RUN: would back up $src → $dest, pruning files older than $retention_days days"
  exit 0
fi

mkdir -p "$dest"
rsync -a "$src/" "$dest/"
find "$dest" -type f -mtime +"$retention_days" -delete
echo "$CHECK Backed up $src → $dest (retention ${retention_days}d)"
