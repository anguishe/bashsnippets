#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/list-open-ports-linux
# Script: list-open-ports.sh
# Purpose: Audit every port your server listens on — find forgotten services before attackers do
# Usage: sudo ./list-open-ports.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"

echo "=== Listening TCP Ports ==="
echo ""

if command -v ss &>/dev/null; then
  ss -tlnp
elif command -v netstat &>/dev/null; then
  echo "(ss not found — using netstat)"
  netstat -tlnp
else
  echo "$CROSS Neither ss nor netstat found. Install iproute2 or net-tools."
  exit 1
fi

echo ""
echo "=== Listening UDP Ports ==="
echo ""

if command -v ss &>/dev/null; then
  ss -ulnp
else
  netstat -ulnp
fi

echo ""
echo "=== Port-to-Process Map (lsof) ==="
echo ""

if [[ $EUID -ne 0 ]]; then
  echo "(run with sudo for full process detail)"
fi

if command -v lsof &>/dev/null; then
  lsof -i -P -n | grep LISTEN || echo "No LISTEN sockets found by lsof"
fi

echo ""
echo "$CHECK Audit complete. Investigate any port you cannot explain."
