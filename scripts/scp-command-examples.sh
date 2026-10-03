#!/bin/bash
# Script: scp-verified.sh
# Purpose: scp exits 0 without checking what arrived, and a copy cut off midway leaves a half file under the real name — this uploads to a temporary name, compares SHA-256 on both ends, then renames into place.
# Usage: ./scp-verified.sh HOST REMOTE_DIR FILE...   (HOST can be an ~/.ssh/config alias)
set -euo pipefail

CHECK="✓"
CROSS="✗"

[[ $# -ge 3 ]] || { echo "usage: $0 HOST REMOTE_DIR FILE..." >&2; exit 2; }
HOST="$1"
REMOTE_DIR="$2"
shift 2
# Options valid for both ssh and scp (-F, -i, -o …), e.g. SSH_OPTS="-F ./ssh_config"; put ports in ~/.ssh/config, since scp spells it -P and ssh -p. Word splitting is intended.
read -r -a SSH_OPTS <<< "${SSH_OPTS:-}"
FAILED=0

for f in "$@"; do
  if [[ ! -f "$f" ]]; then
    echo "$CROSS $f: not a regular file"
    FAILED=$((FAILED + 1))
    continue
  fi
  name=$(basename -- "$f")
  part="$REMOTE_DIR/.$name.part"
  local_sum=$(sha256sum -- "$f" | cut -d' ' -f1)

  # -p keeps the modification time; -q hides the progress bar so cron logs stay readable.
  rc=0
  scp "${SSH_OPTS[@]}" -p -q -- "$f" "$HOST:$part" || rc=$?
  if (( rc )); then
    echo "$CROSS $f: scp failed (exit $rc)"
    FAILED=$((FAILED + 1))
    continue
  fi

  # printf %q quotes the paths for the remote shell, so spaces and quotes in names survive.
  remote_sum=$(ssh "${SSH_OPTS[@]}" -n "$HOST" "sha256sum -- $(printf '%q' "$part")" | cut -d' ' -f1)
  if [[ "$remote_sum" != "$local_sum" ]]; then
    echo "$CROSS $f: checksum mismatch (local ${local_sum:0:12}, remote ${remote_sum:0:12}); left as $part"
    FAILED=$((FAILED + 1))
    continue
  fi

  # mv within one directory is an atomic rename: readers see the old file or the whole new one.
  ssh "${SSH_OPTS[@]}" -n "$HOST" "mv -f -- $(printf '%q' "$part") $(printf '%q' "$REMOTE_DIR/$name")"
  echo "$CHECK $f -> $HOST:$REMOTE_DIR/$name (sha256 ${local_sum:0:12}…)"
done

if (( FAILED )); then
  echo "$CROSS $FAILED file(s) not delivered"
  exit 1
fi
