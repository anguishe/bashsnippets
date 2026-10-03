#!/bin/bash
# Script: cron-doctor.sh
# Purpose: A cron job that never runs, or runs and fails, leaves no error anywhere you would look — this checks the daemon and every line of a crontab for the seven causes that account for most of them.
# Usage: ./cron-doctor.sh [CRONTAB_FILE]   (default: your own crontab, via crontab -l)
set -euo pipefail

CHECK="✓"
CROSS="✗"
WARN="!"

# cron's PATH when the crontab does not set one (Debian/Ubuntu cron and cronie both default to this).
CRON_DEFAULT_PATH="/usr/bin:/bin"
PROBLEMS=0
problem() { echo "  $CROSS $*"; PROBLEMS=$((PROBLEMS + 1)); }

# 1. Is a cron daemon running at all?
DAEMON=""
for unit in cron crond cronie; do
  if systemctl is-active --quiet "$unit" 2>/dev/null; then DAEMON="$unit"; break; fi
done
if [[ -n "$DAEMON" ]]; then
  echo "$CHECK cron daemon active ($DAEMON.service)"
else
  echo "$CROSS no active cron daemon (cron, crond or cronie): nothing in any crontab will run"
  PROBLEMS=$((PROBLEMS + 1))
fi

# 2. Can cron mail the output anywhere? Without an MTA, output that is not redirected is thrown away.
HAS_MTA=0
if command -v sendmail >/dev/null; then
  HAS_MTA=1
  echo "$CHECK an MTA is installed (sendmail found): unredirected output is mailed"
else
  echo "$WARN no MTA (no sendmail): output a job does not redirect is discarded"
  if [[ -n "$DAEMON" ]] && LOST=$(journalctl -u "$DAEMON" --since "-7 days" -o cat 2>/dev/null | grep -c "No MTA installed"); then
    echo "  cron logged \"No MTA installed, discarding output\" $LOST time(s) in the last 7 days"
  fi
fi

# 3. Read the crontab.
if [[ $# -ge 1 ]]; then
  CRONTAB=$(cat -- "$1")
  SOURCE="$1"
else
  CRONTAB=$(crontab -l 2>/dev/null) || { echo "$CROSS you have no crontab (crontab -l failed)"; exit 1; }
  SOURCE="crontab -l"
fi
echo "checking $SOURCE"
if grep -q $'\r' <<< "$CRONTAB"; then
  problem "the crontab has CRLF line endings: cron reads the carriage return as part of each command"
fi

CRONTAB_PATH=""
n=0
while IFS= read -r line || [[ -n "$line" ]]; do
  n=$((n + 1))
  line="${line%$'\r'}"
  [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
  # Environment lines (PATH=, MAILTO=, SHELL=) apply to the jobs below them.
  if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*= ]]; then
    [[ "${BASH_REMATCH[1]}" == "PATH" ]] && CRONTAB_PATH="${line#*=}"
    continue
  fi

  read -r -a f <<< "$line"
  if [[ "$line" =~ ^[[:space:]]*@[a-z]+[[:space:]]+(.*)$ ]]; then
    dom="*"; dow="*"
    cmd="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^[[:space:]]*([^[:space:]]+[[:space:]]+){5}(.*)$ ]]; then
    dom="${f[2]}"; dow="${f[4]}"
    cmd="${BASH_REMATCH[2]}"
  else
    echo "line $n: $line"
    problem "fewer than 6 fields: cron cannot parse this line"
    continue
  fi
  echo "line $n: $cmd"

  # Both day fields restricted: cron runs when EITHER matches (man 5 crontab).
  if [[ "$dom" != "*" && "$dow" != "*" ]]; then
    problem "day-of-month ($dom) and day-of-week ($dow) are both set: cron runs on either, not only when both match"
  fi

  # An unescaped % ends the command; everything after it becomes stdin.
  if grep -qE '(^|[^\\])%' <<< "$cmd"; then
    problem "unescaped % in the command: cron cuts the command there; write \\% (e.g. date +\\%F)"
  fi

  first="${cmd%% *}"
  if [[ "$first" == /* ]]; then
    if [[ ! -e "$first" ]]; then
      problem "$first does not exist"
    elif [[ ! -x "$first" ]]; then
      problem "$first is not executable: chmod +x $first"
    elif head -n 1 -- "$first" | grep -q $'\r'; then
      problem "$first has a CRLF shebang: it fails with bad interpreter"
    fi
  elif ! type -t "$first" >/dev/null 2>&1 || [[ "$(type -t "$first")" == "file" ]]; then
    # Found by your shell's PATH is not the same as found by cron's.
    if ! PATH="${CRONTAB_PATH:-$CRON_DEFAULT_PATH}" command -v "$first" >/dev/null; then
      problem "'$first' is not on cron's PATH (${CRONTAB_PATH:-$CRON_DEFAULT_PATH}): use its full path ($(command -v "$first" || echo 'not found here either'))"
    fi
  fi

  if (( ! HAS_MTA )) && ! grep -qE '>' <<< "$cmd"; then
    problem "output is not redirected and there is no MTA: errors vanish; append >> /path/job.log 2>&1"
  fi
done <<< "$CRONTAB"

if (( PROBLEMS )); then
  echo "$CROSS $PROBLEMS problem(s) found"
  exit 1
fi
echo "$CHECK no problems found"
