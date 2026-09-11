#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/ports-audit
# Script: ports-audit.sh
# Purpose: A listener you did not open — a debug endpoint left running, a container that published a port, an intruder's shell — stays invisible until something diffs the list. This prints every listening socket as CSV and alerts once when the set changes.
# Usage: ./ports-audit.sh            print every listening socket as CSV (root shows the process for every socket; non-root shows the owning cgroup or uid)
#        ./ports-audit.sh --diff     also compare with the previous run and alert on new or vanished listeners
#   cron: 0 * * * * /usr/local/sbin/ports-audit.sh --diff >/dev/null
set -euo pipefail
export LC_ALL=C                       # deterministic sort order across runs, whatever the locale

CHECK="✓"
CROSS="✗"

STATE_DIR="${STATE_DIR:-/var/tmp/ports-audit}"
ALERT_CMD="${ALERT_CMD:-}"            # reads the report on stdin, e.g. mail -s "listener change on $(hostname)" you@example.com
DIFF=0
[[ "${1:-}" == "--diff" ]] && DIFF=1

mkdir -p "$STATE_DIR"
CURRENT="$STATE_DIR/current.csv"
PREVIOUS="$STATE_DIR/previous.csv"

# One line per listening socket: proto,address,port,service,owner
# ss flags: -H no header, -l listening only, -t -u tcp and udp, -n numeric ports,
#           -p owning process (other users' sockets need root), -e uid and cgroup (no root needed)
snapshot() {
  ss -Hltunpe | awk '
    {
      proto = $1
      n = split($5, a, ":"); port = a[n]
      addr = substr($5, 1, length($5) - length(port) - 1)
      owner = "?"
      if (match($0, /users:\(\("[^"]+"/)) {            # root, or a socket of your own
        owner = substr($0, RSTART + 9, RLENGTH - 10)
      } else if (match($0, /cgroup:[^ ]+/)) {           # anyone: the systemd unit that owns it
        cg = substr($0, RSTART + 7, RLENGTH - 7); m = split(cg, p, "/"); owner = "cgroup:" p[m]
      } else if (match($0, /uid:[0-9]+/)) {
        owner = "uid:" substr($0, RSTART + 4, RLENGTH - 4)
      }
      printf "%s,%s,%s,%s\n", proto, addr, port, owner
    }' | while IFS=, read -r proto addr port owner; do
      # getent exits 2 for a port with no /etc/services entry; under pipefail that would kill the loop
      svc=$(getent services "$port/$proto" 2>/dev/null | awk '{print $1}' || true)
      printf '%s,%s,%s,%s,%s\n' "$proto" "$addr" "$port" "${svc:-unknown}" "$owner"
    done | sort -t, -k1,1 -k3,3n -k2,2 -k5,5 -u   # proto, port, address, owner; exact duplicates collapse
}

[[ -f "$CURRENT" ]] && mv -f "$CURRENT" "$PREVIOUS"
snapshot > "$CURRENT"

if [[ $EUID -ne 0 ]]; then
  echo "$CROSS not root: process names appear only for your own sockets; everything else shows its systemd cgroup or uid" >&2
fi
cat "$CURRENT"
echo "$CHECK $(wc -l < "$CURRENT") listening sockets on $(hostname) at $(date '+%F %T')" >&2

if (( DIFF )) && [[ -f "$PREVIOUS" ]]; then
  # Whole-line set difference. grep exits 1 when nothing is selected, hence the || true.
  added=$(grep -Fxv -f "$PREVIOUS" "$CURRENT" || true)
  removed=$(grep -Fxv -f "$CURRENT" "$PREVIOUS" || true)
  if [[ -n "$added$removed" ]]; then
    report=$(printf 'Listener changes on %s at %s\n\nNEW:\n%s\n\nGONE:\n%s\n' \
      "$(hostname)" "$(date)" "${added:-(none)}" "${removed:-(none)}")
    echo "$CROSS listener set changed since the previous run" >&2
    printf '%s\n' "$report" >&2
    if [[ -n "$ALERT_CMD" ]]; then
      printf '%s\n' "$report" | bash -c "$ALERT_CMD"
    fi
    exit 3
  fi
  echo "$CHECK no listener changes since the previous run" >&2
fi
