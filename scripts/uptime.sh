#!/bin/bash
# ─────────────────────────────────────────────────────────────
# uptime.sh — Check If Website Is Up
# Uses curl to return the HTTP status code of any URL.
# 200 = site is up. Anything else = investigate.
#
# Usage:    ./uptime.sh
# Schedule: crontab -e → */5 * * * * ~/bash-scripts/scripts/uptime.sh >> ~/uptime.log 2>&1
# Author:   BashSnippets.xyz
# Full reference + explanation:
#           https://bashsnippets.xyz/snippets/check-if-website-is-up.html
# ─────────────────────────────────────────────────────────────

CHECK="✓"
CROSS="✗"

URL="https://bashsnippets.xyz"   # ← change to your site

STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$URL")

if [ "$STATUS" -eq 200 ]; then
  echo "$CHECK $URL is up (HTTP $STATUS)"
else
  echo "$CROSS $URL returned HTTP $STATUS — check it"
fi
