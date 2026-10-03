#!/bin/bash
# Script: deleted-open-files.sh
# Purpose: df says the disk is full and du says it isn't — a deleted file that a process still holds open keeps every byte until it is closed; this lists those files, biggest first, with the PID and fd to deal with.
# Usage: ./deleted-open-files.sh [MOUNTPOINT]   (default: all filesystems; run as root to see every process)
set -euo pipefail

CHECK="✓"
CROSS="✗"

MOUNT="${1:-}"
# Below this, entries are memory buffers (PipeWire memfds, browser caches), not your missing disk.
MIN_BYTES=$((1024 * 1024))

command -v lsof >/dev/null || { echo "$CROSS lsof is not installed (apt install lsof / dnf install lsof)" >&2; exit 2; }

# lsof exits 1 even when it prints matches, so read its output, never its exit status.
# -w drops warnings about filesystems it can't stat (docker overlays, other namespaces);
# -F gives one field per line, so file names with spaces parse safely.
RAW=$(lsof -w -nP +L1 -F pcftDsin ${MOUNT:+"$MOUNT"} 2>/dev/null || true)

# One row per deleted inode, not per process: ten processes sharing one deleted binary hold its space once.
ROWS=$(awk -v min="$MIN_BYTES" '
  /^p/ { pid = substr($0, 2) }
  /^c/ { cmd = substr($0, 2) }
  /^f/ { fd = substr($0, 2); type = ""; size = 0; dev = ""; ino = "" }
  /^t/ { type = substr($0, 2) }
  /^D/ { dev = substr($0, 2) }
  /^s/ { size = substr($0, 2) + 0 }
  /^i/ { ino = substr($0, 2) }
  /^n/ {
    name = substr($0, 2)
    if (type != "REG" || size < min || name ~ /^\/memfd:/) next
    key = dev ":" ino
    if (!(key in bytes)) { bytes[key] = size; file[key] = name }
    if (n[key]++ < 3) held[key] = held[key] (held[key] == "" ? " " : ", ") cmd "[" pid "] fd " fd
  }
  END { for (k in bytes) printf "%d\t%s\t%s%s\n", bytes[k], file[k], held[k], (n[k] > 3 ? " +" n[k] - 3 " more" : "") }
' <<< "$RAW" | sort -t$'\t' -k1,1nr)

if [[ -z "$ROWS" ]]; then
  echo "$CHECK no deleted-but-open files over $(numfmt --to=iec "$MIN_BYTES") ${MOUNT:+on $MOUNT }(as $(id -un))"
  exit 0
fi

TOTAL=0
while IFS=$'\t' read -r size name holders; do
  printf '%s %6s  %s\n         held by:%s\n' "$CROSS" "$(numfmt --to=iec "$size")" "$name" "$holders"
  TOTAL=$((TOTAL + size))
done <<< "$ROWS"

echo "  held by deleted files: $(numfmt --to=iec "$TOTAL")"
echo "  free it: restart the process, or empty one file in place with  : > /proc/PID/fd/FD  (its data is lost)"
exit 1
