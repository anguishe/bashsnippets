#!/bin/bash
# Script: ssh-run-remote-commands.sh
# Purpose: A loop that runs one command over SSH on twenty hosts and ignores
#          the exit codes reports "done" while three boxes never got the
#          change — this runs the command per host and refuses to exit 0
#          unless every host did.
# Usage: ./ssh-run-remote-commands.sh 'command' host1 [host2 ...]
#        ./ssh-run-remote-commands.sh 'command'          (hosts read from $HOSTS_FILE)
# Tested: Kali 2026.3 (bash 5.3), Ubuntu 22.04 LTS, Fedora 39
set -euo pipefail

CHECK="✓"
CROSS="✗"

# ── CONFIGURATION ──────────────────────────────────────────────
HOSTS_FILE="${HOSTS_FILE:-./hosts.txt}"   # one host per line; used when no hosts are passed
SSH_USER="${SSH_USER:-}"                  # empty = your current username, like plain ssh
CONNECT_TIMEOUT=5                         # seconds before an unreachable host is written off
SSH_FAILED_CODE=255                       # ssh's own failure code (DNS, refused, auth) — not the remote command's

REMOTE_CMD="${1:?usage: $0 'command' [host ...]}"
shift

# ── HOST LIST ──────────────────────────────────────────────────
HOSTS=("$@")
if [ "${#HOSTS[@]}" -eq 0 ]; then
  if [ ! -r "$HOSTS_FILE" ]; then
    echo "$CROSS no hosts given and $HOSTS_FILE is not readable" >&2
    exit 1
  fi
  # mapfile keeps one host per element — no word-splitting surprises.
  # The grep drops blank lines and comments so the file can be annotated.
  mapfile -t HOSTS < <(grep -Ev '^[[:space:]]*(#|$)' "$HOSTS_FILE")
fi

# BatchMode=yes: never prompt for a password or a host-key confirmation —
# a prompt inside a loop hangs the whole run until someone notices.
# -n: stdin from /dev/null, so ssh cannot swallow the rest of the host list
# if this ever runs inside a while-read loop.
SSH_OPTS=(-n -o BatchMode=yes -o ConnectTimeout="$CONNECT_TIMEOUT")

FAILED=0
for host in "${HOSTS[@]}"; do
  target="$host"
  if [ -n "$SSH_USER" ]; then
    target="$SSH_USER@$host"
  fi

  # The remote command is passed as ONE argument so its quoting reaches the
  # remote shell intact. The exit code is captured, never masked by set -e.
  code=0
  output=$(ssh "${SSH_OPTS[@]}" "$target" -- "$REMOTE_CMD" 2>&1) || code=$?

  if [ "$code" -eq 0 ]; then
    printf '%s %-20s exit 0\n' "$CHECK" "$host"
  elif [ "$code" -eq "$SSH_FAILED_CODE" ]; then
    printf '%s %-20s ssh failed (exit %d): %s\n' "$CROSS" "$host" "$code" "$output"
    FAILED=$((FAILED + 1))
    continue
  else
    printf '%s %-20s exit %d\n' "$CROSS" "$host" "$code"
    FAILED=$((FAILED + 1))
  fi
  # Indent the remote output under its status line so twenty hosts stay
  # readable: every embedded newline gets four spaces appended after it.
  if [ -n "$output" ]; then
    printf '    %s\n' "${output//$'\n'/$'\n    '}"
  fi
done

echo
if [ "$FAILED" -gt 0 ]; then
  echo "$CROSS $FAILED of ${#HOSTS[@]} hosts failed"
  exit 1
fi
echo "$CHECK all ${#HOSTS[@]} hosts succeeded"
