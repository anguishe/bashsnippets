#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/kill-process-on-port
# Script: kill-port.sh
# Purpose: Find and kill the process occupying a specific network port
# Usage: ./kill-port.sh <port-number>
set -euo pipefail

CHECK="✓"
CROSS="✗"

PORT="${1:?Usage: $0 <port-number>}"
TIMEOUT=5

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  echo "$CROSS Invalid port number: $PORT (must be 1-65535)"
  exit 1
fi

echo "=== Finding process on port $PORT ==="

PID=""
if command -v lsof &>/dev/null; then
  PID=$(lsof -ti :"$PORT" 2>/dev/null | head -n 1)
elif command -v ss &>/dev/null; then
  PID=$(ss -ltnp "sport = :$PORT" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -n 1)
fi

if [ -z "$PID" ]; then
  echo "$CHECK Port $PORT is not in use — nothing to kill."
  exit 0
fi

PROC_NAME=$(ps -p "$PID" -o comm= 2>/dev/null || echo "unknown")
echo "Found: PID $PID ($PROC_NAME) is holding port $PORT"

echo "Sending SIGTERM to PID $PID..."
kill "$PID" 2>/dev/null || true

ELAPSED=0
while kill -0 "$PID" 2>/dev/null && [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done

if kill -0 "$PID" 2>/dev/null; then
  echo "Process did not stop after ${TIMEOUT}s — escalating to SIGKILL..."
  kill -9 "$PID" 2>/dev/null || true
  echo "$CHECK Port $PORT freed (SIGKILL sent to PID $PID)"
else
  echo "$CHECK Port $PORT freed (PID $PID stopped gracefully)"
fi
