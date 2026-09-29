#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/port-listening-but-connection-refused
# Script: check-bind-address.sh
# Purpose: A service that listens only on 127.0.0.1 answers curl on the box and refuses every other machine with "Connection refused" — this shows which address each listener on a port is bound to and who can reach it.
# Usage: ./check-bind-address.sh PORT   (exit 0 = reachable from the network, 1 = nothing listening, 2 = loopback only)
set -euo pipefail

CHECK="✓"
CROSS="✗"

PORT="${1:?usage: $0 PORT}"
[[ "$PORT" =~ ^[0-9]+$ ]] || { echo "$CROSS port must be a number" >&2; exit 2; }

# -H drops the header; the filter matches the local port exactly, so :80 never matches :8080.
mapfile -t LISTENERS < <(ss -Hltn "sport = :$PORT" | awk '{print $4}')

if [[ ${#LISTENERS[@]} -eq 0 ]]; then
  echo "$CROSS nothing is listening on TCP port $PORT — connection refused from everywhere"
  exit 1
fi

NETWORK=0
for addr in "${LISTENERS[@]}"; do
  host="${addr%:*}"
  case "$host" in
    127.*|'[::1]'|*%lo)       echo "  $addr  loopback only: this machine can connect, no other machine can" ;;
    0.0.0.0|'[::]'|'*')       echo "  $addr  every interface: reachable from any network this host is on"; NETWORK=1 ;;
    *)                        echo "  $addr  one address only: reachable through that interface"; NETWORK=1 ;;
  esac
done

if (( NETWORK )); then
  echo "$CHECK port $PORT accepts connections from the network (a firewall can still block them)"
  exit 0
fi
echo "$CROSS port $PORT is loopback only — from another host this is \"Connection refused\". Bind the service to 0.0.0.0 or the LAN address to expose it."
exit 2
