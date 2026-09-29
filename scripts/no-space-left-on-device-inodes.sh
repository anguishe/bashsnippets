#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/no-space-left-on-device-inodes
# Script: inode-usage-check.sh
# Purpose: A filesystem out of inodes fails every file create with "No space left on device" while df -h still shows free space — this checks inode use per mount and names the directories holding the most entries.
# Usage: ./inode-usage-check.sh [MOUNT] [THRESHOLD_%] [TOP_N]   (defaults: / 90 10)
set -euo pipefail
export LC_ALL=C                      # stable sort order and plain % output from df

CHECK="✓"
CROSS="✗"

MOUNT="${1:-/}"                      # any path on the filesystem you want checked
THRESHOLD="${2:-90}"                 # inode use % that counts as a problem
TOP_N="${3:-10}"                     # how many of the fullest directories to list

# --output keeps the columns fixed whatever the device name length is.
read -r ITOTAL IUSED IFREE IPCT < <(df --output=itotal,iused,iavail,ipcent "$MOUNT" | awk 'NR==2 {print $1, $2, $3, $4}')
BPCT=$(df --output=pcent "$MOUNT" | awk 'NR==2 {print $1}')

# btrfs, ZFS and some FUSE mounts allocate inodes dynamically and report 0 or "-".
if [[ "$ITOTAL" == "0" || "$IPCT" == "-" ]]; then
  echo "$CHECK $MOUNT reports no fixed inode count (dynamic allocation) — inodes cannot run out here"
  exit 0
fi

IPCT="${IPCT%\%}"
echo "blocks used: $BPCT   inodes used: ${IPCT}% ($IUSED of $ITOTAL, $IFREE free)"

if (( IPCT < THRESHOLD )); then
  echo "$CHECK inode use ${IPCT}% is under ${THRESHOLD}% on $MOUNT"
  exit 0
fi

echo "$CROSS inode use ${IPCT}% is at or over ${THRESHOLD}% on $MOUNT — directories holding the most entries:"
# -xdev stays on this filesystem: another mount's files do not use this one's inodes.
# %h prints each entry's parent directory, so uniq -c counts entries per directory.
find "$MOUNT" -xdev -mindepth 1 -printf '%h\n' 2>/dev/null | sort | uniq -c | sort -rn | head -n "$TOP_N"
exit 1
