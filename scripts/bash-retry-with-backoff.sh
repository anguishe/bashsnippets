#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/bash-retry-with-backoff
# Script: retry.sh
# Purpose: Survive transient failures (a flaky network, a service still booting)
#          instead of dying on the first error
# Usage: retry.sh   (or source the retry() function into your own scripts)
set -euo pipefail

CHECK="✓"
CROSS="✗"

# Retry a command with exponential backoff and jitter.
# Usage: retry <max_attempts> <command> [args...]
retry() {
    local max_attempts="$1"; shift
    local attempt=1
    local delay=1            # base delay in seconds — doubles each round
    local max_delay=30       # cap so the backoff never runs away

    until "$@"; do
        if (( attempt >= max_attempts )); then
            echo "$CROSS '$*' failed after $attempt attempts" >&2
            return 1
        fi
        # 0–2s of jitter so parallel callers don't all retry on the same beat
        local pause=$(( delay + RANDOM % 3 ))
        echo "$CROSS attempt $attempt failed — retrying in ${pause}s" >&2
        sleep "$pause"
        attempt=$(( attempt + 1 ))
        delay=$(( delay * 2 ))
        if (( delay > max_delay )); then delay=$max_delay; fi
    done

    echo "$CHECK '$*' succeeded on attempt $attempt"
}

# The fix for my 11pm deploy: wait for Postgres to accept connections first.
retry 6 nc -z -w 2 db.internal 5432
echo "$CHECK database reachable — running migration"

# A release artifact that occasionally 503s while the CDN warms up.
retry 5 curl -fsS --max-time 10 -o /tmp/pkg.tar.gz https://releases.example.com/pkg.tar.gz
