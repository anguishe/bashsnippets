#!/bin/bash
# Script: extract.sh
# Purpose: Unpacking means remembering tar xzf vs xJf vs unzip vs gunzip, and a *.gz rule placed above *.tar.gz gunzips a tarball into one opaque .tar — this picks the right tool per file with one ordered case statement.
# Usage: ./extract.sh ARCHIVE...
set -euo pipefail

CHECK="✓"
CROSS="✗"

[[ $# -ge 1 ]] || { echo "usage: $0 ARCHIVE..." >&2; exit 2; }
STATUS=0

for f in "$@"; do
  if [[ ! -f "$f" ]]; then
    echo "$CROSS $f: not a file"
    STATUS=1
    continue
  fi
  # case takes the FIRST matching pattern, so the two-part extensions must come before .gz/.bz2/.xz.
  # ${f,,} lowercases the name, so BACKUP.TGZ matches too.
  case "${f,,}" in
    *.tar.gz|*.tgz)   cmd=(tar -xzf "$f") ;;
    *.tar.bz2|*.tbz2) cmd=(tar -xjf "$f") ;;
    *.tar.xz|*.txz)   cmd=(tar -xJf "$f") ;;
    *.tar.zst)        cmd=(tar --zstd -xf "$f") ;;
    *.tar)            cmd=(tar -xf "$f") ;;
    *.gz)             cmd=(gunzip -k "$f") ;;
    *.bz2)            cmd=(bunzip2 -k "$f") ;;
    *.xz)             cmd=(unxz -k "$f") ;;
    *.zip)            cmd=(unzip -q -n "$f") ;;
    *)
      echo "$CROSS $f: unknown archive type"
      STATUS=1
      continue
      ;;
  esac
  # An array keeps file names with spaces as one argument.
  if "${cmd[@]}"; then
    echo "$CHECK $f: ${cmd[*]}"
  else
    echo "$CROSS $f: ${cmd[0]} failed"
    STATUS=1
  fi
done
exit "$STATUS"
