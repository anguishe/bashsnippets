#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/bash-arrays
# Script: health-check.sh
# Purpose: Without collecting failures, the script stops at the first dead service and hides the others.
# Usage: ./health-check.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"

# Service name → expected port. Associative array = readable, no parallel lists.
declare -A services
services[nginx]=80
services[postgres]=5432
services[redis]=6379

failures=()   # indexed array; we append every failure and report them together

for svc in "${!services[@]}"; do
  port="${services[$svc]}"
  # Quote everything; a value with a space would otherwise split the test.
  if timeout 2 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null; then
    echo "$CHECK $svc up on port $port"
  else
    echo "$CROSS $svc DOWN on port $port"
    failures+=("$svc (port $port)")   # collect, do not abort
  fi
done

# Report the complete failure set, using ${#failures[@]} to decide the exit code.
if [[ "${#failures[@]}" -gt 0 ]]; then
  echo "$CROSS ${#failures[@]} service(s) failed: ${failures[*]}"
  exit 1
fi
echo "$CHECK All ${#services[@]} services healthy"
