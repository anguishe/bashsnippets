#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/start-request-repeated-too-quickly
# Script: start-limit-check.sh
# Purpose: "Start request repeated too quickly" hides the real crash behind systemd's rate limit, and raising the limit only hides it longer; this prints the limit math and the error that tripped it.
# Usage: ./start-limit-check.sh [--user] UNIT
set -euo pipefail

CHECK="✓"
CROSS="✗"

SCOPE=()
if [[ "${1:-}" == "--user" ]]; then SCOPE=(--user); shift; fi
[[ $# -eq 1 ]] || { echo "usage: $0 [--user] UNIT" >&2; exit 2; }
UNIT="$1"
LOG_LINES=200   # how far back to look for the program's own output before the limit hit

prop() { systemctl "${SCOPE[@]}" show -p "$1" --value "$UNIT"; }
# show reports times like "10s" or "100ms"; convert to milliseconds so the two can be compared.
to_ms() {
  local v=$1 total=0 n unit
  [[ "$v" == "infinity" || -z "$v" ]] && { echo 0; return; }
  while [[ "$v" =~ ^([0-9]+)(min|ms|us|h|s)(.*)$ ]]; do
    n=${BASH_REMATCH[1]} unit=${BASH_REMATCH[2]} v=${BASH_REMATCH[3]}
    case "$unit" in h) total=$((total + n * 3600000)) ;; min) total=$((total + n * 60000)) ;;
      s) total=$((total + n * 1000)) ;; ms) total=$((total + n)) ;; us) total=$((total + n / 1000)) ;; esac
  done
  echo "$total"
}

RESULT=$(prop Result)
RESTART=$(prop Restart)
BURST=$(prop StartLimitBurst)
INTERVAL=$(prop StartLimitIntervalUSec)
RESTART_SEC=$(prop RestartUSec)
NRESTARTS=$(prop NRestarts)
echo "  $UNIT: Result=$RESULT, Restart=$RESTART, RestartSec=$RESTART_SEC, restarts so far=$NRESTARTS"
echo "  start limit: $BURST starts within $INTERVAL"

INTERVAL_MS=$(to_ms "$INTERVAL")
RESTART_MS=$(to_ms "$RESTART_SEC")
# Every automatic restart counts as a start, so a program that dies at once spends the burst in burst*RestartSec.
if [[ "$RESTART" != "no" ]] && (( INTERVAL_MS > 0 && BURST * RESTART_MS < INTERVAL_MS )); then
  echo "$CROSS a crash loop will trip the limit: $BURST restarts every ${RESTART_MS}ms take $((BURST * RESTART_MS))ms, inside the ${INTERVAL_MS}ms window"
  echo "    RestartSec=$(( (INTERVAL_MS / BURST / 1000) + 1 ))s or more spreads them out; the limit then only stops a real tight loop"
fi

if [[ "$RESULT" == "start-limit-hit" ]]; then
  echo "$CROSS the unit is parked: systemd refuses every start, including yours, until you run:"
  echo "    systemctl ${SCOPE[*]:+${SCOPE[*]} }reset-failed $UNIT && systemctl ${SCOPE[*]:+${SCOPE[*]} }start $UNIT"
  # The limit message is never the cause; the last line the program itself wrote usually is.
  CAUSE=$(journalctl "${SCOPE[@]}" -u "$UNIT" -n "$LOG_LINES" --no-pager -o short-iso 2>/dev/null |
    grep -v ' systemd\[[0-9]*\]: ' | grep -v '^-- ' | tail -3 || true)
  if [[ -n "$CAUSE" ]]; then
    echo "  last lines from the program before the loop stopped:"
    while IFS= read -r line; do echo "    $line"; done <<< "$CAUSE"
  else
    echo "  the program logged nothing: the failure is in systemd's own lines (try journalctl ${SCOPE[*]} -u $UNIT -n 30)"
  fi
  exit 1
fi

echo "$CHECK not rate-limited right now (Result=$RESULT)"
exit 0
