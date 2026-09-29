#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/journalctl-disk-usage-vacuum
# Script: journal-disk-usage.sh
# Purpose: systemd-journald keeps logs until it hits its own cap (10% of the filesystem, up to 4G by default), so an unconfigured journal quietly holds gigabytes — this reports the size, the cap in force, and vacuums down to a limit you choose.
# Usage: ./journal-disk-usage.sh [MAX_SIZE] [--apply]   (default MAX_SIZE 1G; --apply needs root)
set -euo pipefail
export LC_ALL=C

CHECK="✓"
CROSS="✗"

MAX_SIZE="${1:-1G}"                  # the size you want the journal held to (K, M, G suffixes)
APPLY=0
[[ "${2:-}" == "--apply" ]] && APPLY=1

# "Archived and active journals take up 3.4G in the file system." -> 3.4G
USED_HUMAN=$(journalctl --disk-usage 2>/dev/null | grep -oE '[0-9.]+[KMGT]?B?' | head -1)
USED_HUMAN="${USED_HUMAN%B}"
USED_BYTES=$(numfmt --from=iec "$USED_HUMAN")
MAX_BYTES=$(numfmt --from=iec "$MAX_SIZE")

# The effective setting is the last uncommented SystemMaxUse= across journald.conf and every drop-in.
CAP=$(systemd-analyze cat-config systemd/journald.conf 2>/dev/null | grep -E '^SystemMaxUse=' | tail -1 | cut -d= -f2 || true)

echo "journal on disk: $USED_HUMAN"
echo "SystemMaxUse:    ${CAP:-not set (default: 10% of the filesystem, capped at 4G)}"

if (( USED_BYTES <= MAX_BYTES )); then
  echo "$CHECK journal is within $MAX_SIZE"
  exit 0
fi

echo "$CROSS journal is over $MAX_SIZE"
if (( ! APPLY )); then
  echo "  one-off:   sudo journalctl --vacuum-size=$MAX_SIZE"
  echo "  permanent: set SystemMaxUse=$MAX_SIZE in /etc/systemd/journald.conf.d/size.conf, then sudo systemctl restart systemd-journald"
  exit 1
fi

if (( EUID != 0 )); then
  echo "$CROSS --apply needs root: re-run with sudo" >&2
  exit 2
fi

# Vacuum only removes archived files; rotate first so the active file becomes archived too.
journalctl --rotate
journalctl --vacuum-size="$MAX_SIZE"
echo "$CHECK now: $(journalctl --disk-usage)"
