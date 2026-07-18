#!/bin/bash
# Script: uptimecheck.sh
# Purpose: Alert when a site stops returning HTTP 200 — silent outages cost real traffic
# Usage: ./uptimecheck.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"

URL="https://bashsnippets.xyz"

STATUS=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$URL")

if [ "$STATUS" -eq 200 ]; then
  echo "$CHECK $URL is up (HTTP $STATUS)"
else
  echo "$CROSS WARNING: $URL returned HTTP $STATUS"
fi
