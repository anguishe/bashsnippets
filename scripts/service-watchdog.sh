#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/service-watchdog
# Script: service-watchdog.sh
# Purpose: A crashed daemon stays down until a human notices, and a hung one stays "active" while serving nothing — this restarts the first, probes for the second, and alerts once per outage instead of once per minute.
# Usage: ./service-watchdog.sh <unit> [probe command...]
#   e.g. ./service-watchdog.sh nginx curl -fsS --max-time 5 http://127.0.0.1/
# Run from root's crontab: * * * * * /usr/local/sbin/service-watchdog.sh nginx curl -fsS --max-time 5 http://127.0.0.1/ >> /var/log/service-watchdog.cron 2>&1
set -euo pipefail

CHECK="✓"
CROSS="✗"

UNIT="${1:?usage: $0 <unit> [probe command...]}"
shift
PROBE=("$@")                                   # optional; a command that exits 0 only when the service answers
STATE_DIR="${STATE_DIR:-/var/tmp/service-watchdog}"
LOG_FILE="${LOG_FILE:-/var/log/service-watchdog.log}"
MAX_RESETS="${MAX_RESETS:-3}"                  # start-limit resets allowed per outage before the watchdog gives up
SETTLE_SECONDS="${SETTLE_SECONDS:-3}"          # how long a fresh start gets before the verify step
ALERT_CMD="${ALERT_CMD:-}"                     # reads the message on stdin, e.g. mail -s "watchdog: $UNIT" you@example.com

mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/$UNIT.state"            # last verdict: up | down | stuck
RESET_FILE="$STATE_DIR/$UNIT.resets"           # start-limit resets used in the current outage
LOCK_FILE="$STATE_DIR/$UNIT.lock"

log() { printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" | tee -a "$LOG_FILE"; }

# Alert only when the verdict changes. A service that is down for an hour sends one
# message when it goes down and one when it comes back, not sixty.
set_verdict() {
  local verdict="$1" message="$2" previous="none"
  [[ -f "$STATE_FILE" ]] && previous=$(<"$STATE_FILE")
  printf '%s\n' "$verdict" > "$STATE_FILE"
  # First run of a healthy unit is not a recovery — only alert on a real change.
  [[ "$previous" == "none" && "$verdict" == "up" ]] && return 0
  if [[ "$verdict" != "$previous" && -n "$ALERT_CMD" ]]; then
    printf '%s\n%s on %s at %s\n' "$message" "$UNIT" "$(hostname)" "$(date)" | bash -c "$ALERT_CMD" || true
  fi
}

# Two watchdog runs at once (a slow probe plus the next cron tick) would both try to
# restart. The lock is released by the kernel when this process exits, crash included.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "$CHECK $UNIT: previous watchdog run still holds the lock, leaving it alone"
  exit 0
fi

# is-active exits 4 for a unit that does not exist, which a naive watchdog reads as
# "down" and then tries to start every minute forever. Check the load state first.
if [[ "$(systemctl show -p LoadState --value "$UNIT")" == "not-found" ]]; then
  log "$CROSS $UNIT: no such unit — fix the name, there is nothing to restart"
  exit 2
fi

# A human running maintenance touches this file first and the watchdog stays out of it.
if [[ -f "$STATE_DIR/$UNIT.maintenance" ]]; then
  log "$CHECK $UNIT: maintenance flag present, skipping"
  exit 0
fi

probe_ok() {
  [[ ${#PROBE[@]} -eq 0 ]] && return 0        # no probe configured: "active" is the whole verdict
  "${PROBE[@]}" >/dev/null 2>&1
}

start_unit() {
  local result
  result=$(systemctl show -p Result --value "$UNIT")
  if [[ "$result" == "start-limit-hit" ]]; then
    local resets=0
    [[ -f "$RESET_FILE" ]] && resets=$(<"$RESET_FILE")
    if (( resets >= MAX_RESETS )); then
      log "$CROSS $UNIT: crash-looping (start limit hit $resets times this outage), leaving it failed for a human"
      set_verdict stuck "CRITICAL: $UNIT is crash-looping and the watchdog has stopped resetting it. journalctl -u $UNIT"
      return 1
    fi
    printf '%s\n' "$(( resets + 1 ))" > "$RESET_FILE"
    log "$CROSS $UNIT: start limit hit, clearing it (reset $(( resets + 1 )) of $MAX_RESETS)"
    systemctl reset-failed "$UNIT"
  fi
  systemctl start "$UNIT"
}

verify() {
  sleep "$SETTLE_SECONDS"
  if systemctl is-active --quiet "$UNIT" && probe_ok; then
    log "$CHECK $UNIT: back up and answering (NRestarts=$(systemctl show -p NRestarts --value "$UNIT"))"
    rm -f "$RESET_FILE"
    set_verdict up "RECOVERED: $UNIT restarted by the watchdog and passed its probe"
    return 0
  fi
  log "$CROSS $UNIT: started but not healthy — state=$(systemctl show -p ActiveState --value "$UNIT")"
  set_verdict down "CRITICAL: $UNIT was restarted but is not answering. journalctl -u $UNIT"
  return 1
}

state=$(systemctl show -p ActiveState --value "$UNIT")
case "$state" in
  active)
    if probe_ok; then
      rm -f "$RESET_FILE"
      set_verdict up "RECOVERED: $UNIT is active and answering again"
      exit 0
    fi
    # Active but failing the probe is the hung case. Restart is stop + start, so a
    # process that ignores SIGTERM holds this for TimeoutStopSec before the SIGKILL.
    log "$CROSS $UNIT: active but not answering the probe, restarting (evidence: journalctl -u $UNIT)"
    set_verdict down "DOWN: $UNIT is active but not answering its probe; the watchdog is restarting it"
    systemctl restart "$UNIT"
    verify
    ;;
  activating|deactivating|reloading)
    log "$CHECK $UNIT: in transition ($state), checking again next run"
    exit 0
    ;;
  inactive|failed)
    log "$CROSS $UNIT: $state (Result=$(systemctl show -p Result --value "$UNIT")), starting"
    set_verdict down "DOWN: $UNIT is $state; the watchdog is starting it"
    start_unit && verify
    ;;
  *)
    log "$CROSS $UNIT: unexpected ActiveState '$state'"
    exit 1
    ;;
esac
