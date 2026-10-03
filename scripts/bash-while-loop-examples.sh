#!/bin/bash
# Script: wait-until.sh
# Purpose: `while ! check; do sleep 1; done` waits forever when the thing never comes up — this polls with a deadline and exits 124 on timeout, like timeout(1).
# Usage: ./wait-until.sh TIMEOUT_SECONDS INTERVAL_SECONDS COMMAND [ARGS...]
set -euo pipefail

CHECK="✓"
CROSS="✗"

[[ $# -ge 3 ]] || { echo "usage: $0 TIMEOUT_SECONDS INTERVAL_SECONDS COMMAND [ARGS...]" >&2; exit 2; }
TIMEOUT="$1"
INTERVAL="$2"
shift 2
[[ "$TIMEOUT" =~ ^[0-9]+$ && "$INTERVAL" =~ ^[0-9]+$ && "$INTERVAL" -gt 0 ]] || { echo "timeout and interval must be whole seconds, interval > 0" >&2; exit 2; }

# SECONDS is bash's built-in elapsed-time counter; a deadline survives slow checks, a loop counter does not.
DEADLINE=$(( SECONDS + TIMEOUT ))
ATTEMPT=0

while true; do
  ATTEMPT=$(( ATTEMPT + 1 ))
  # The check runs inside `if`, so set -e does not kill the script when it fails; </dev/null stops it eating our stdin.
  if "$@" </dev/null >/dev/null 2>&1; then
    echo "$CHECK ready after $ATTEMPT attempt(s), ${SECONDS}s: $*"
    exit 0
  fi
  if (( SECONDS + INTERVAL > DEADLINE )); then
    echo "$CROSS not ready after ${TIMEOUT}s ($ATTEMPT attempts): $*" >&2
    exit 124
  fi
  sleep "$INTERVAL"
done
