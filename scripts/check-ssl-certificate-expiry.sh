#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/check-ssl-certificate-expiry
# Script: check-ssl-expiry.sh
# Purpose: Alert before SSL certificate expires — silent expiry takes HTTPS offline
# Usage: ./check-ssl-expiry.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"

WARN_THRESHOLD=30

DOMAINS=(
  "yourdomain.com"
  "api.yourdomain.com"
)

check_ssl_expiry() {
  local DOMAIN="$1"
  local PORT="${2:-443}"

  local EXPIRY_DATE
  EXPIRY_DATE=$(echo | openssl s_client \
    -connect "${DOMAIN}:${PORT}" \
    -servername "${DOMAIN}" \
    2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

  if [[ -z "$EXPIRY_DATE" ]]; then
    echo "$CROSS  ${DOMAIN}: could not retrieve certificate"
    return 1
  fi

  local EXPIRY_EPOCH
  EXPIRY_EPOCH=$(date -d "${EXPIRY_DATE}" +%s 2>/dev/null || \
                 date -j -f "%b %d %T %Y %Z" "${EXPIRY_DATE}" +%s)

  local NOW_EPOCH
  NOW_EPOCH=$(date +%s)

  local DAYS_LEFT
  DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

  if [[ "$DAYS_LEFT" -le 0 ]]; then
    echo "$CROSS  ${DOMAIN}: EXPIRED — ${EXPIRY_DATE}"
  elif [[ "$DAYS_LEFT" -le "$WARN_THRESHOLD" ]]; then
    echo "$CROSS  ${DOMAIN}: expires in ${DAYS_LEFT} days — renew now"
  else
    echo "$CHECK  ${DOMAIN}: ${DAYS_LEFT} days remaining (${EXPIRY_DATE})"
  fi
}

for DOMAIN in "${DOMAINS[@]}"; do
  check_ssl_expiry "$DOMAIN"
done
