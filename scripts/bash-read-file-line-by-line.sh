#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/bash-read-file-line-by-line
# Script: check-hosts.sh
# Purpose: ping every host in a list, including a newline-less last line
# Usage: ./check-hosts.sh hosts.txt
set -euo pipefail

CHECK="✓"
CROSS="✗"
HOST_FILE="${1:?Usage: check-hosts.sh <host-file>}"

while IFS= read -r host || [[ -n "$host" ]]; do
  [[ -z "$host" || "$host" == \#* ]] && continue   # skip blanks and comments
  if ping -c1 -W2 "$host" >/dev/null 2>&1; then
    echo "$CHECK up:   $host"
  else
    echo "$CROSS down: $host"
  fi
done < "$HOST_FILE"
