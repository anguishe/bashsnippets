#!/bin/bash
# Script: deploy-helpers.sh
# Purpose: show function arguments and safe local scope
# Usage: ./deploy-helpers.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"

greet_all() {
  echo "$CHECK got $# argument(s)"
  for name in "$@"; do
    echo "  - $name"
  done
}

greet_all "web-01" "db primary" "cache-02"
