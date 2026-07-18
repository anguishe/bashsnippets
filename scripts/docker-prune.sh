#!/bin/bash
# Script: docker-prune.sh
# Purpose: Reclaim disk space from Docker garbage — images, containers, volumes, build cache
# Usage: ./docker-prune.sh [--force]
set -euo pipefail

CHECK="✓"
CROSS="✗"
WARN="!"

FORCE="${1:-}"

if ! command -v docker &>/dev/null; then
  echo "$CROSS Docker is not installed or not in PATH."
  exit 1
fi

echo "=== Docker Disk Usage (before cleanup) ==="
docker system df
echo ""

if [[ "$FORCE" != "--force" ]]; then
  echo "$WARN This will remove:"
  echo "   - All stopped containers"
  echo "   - Images unused in the last 30 days"
  echo "   - Dangling volumes (no attached container)"
  echo "   - All build cache"
  echo ""
  read -r -p "Continue? [y/N] " CONFIRM
  [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
  echo ""
fi

echo "=== Removing stopped containers ==="
docker container prune -f
echo ""

echo "=== Removing unused images (older than 30 days) ==="
docker image prune -af --filter "until=720h"
echo ""

echo "=== Removing unattached volumes ==="
# Only removes volumes with zero attached containers — database volumes attached
# to stopped (preserved) containers are NOT removed
docker volume prune -f
echo ""

echo "=== Clearing build cache ==="
docker builder prune -af
echo ""

echo "=== Docker Disk Usage (after cleanup) ==="
docker system df
echo ""
echo "$CHECK Cleanup complete."
