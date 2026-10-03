#!/bin/bash
# Script: docker-remove-containers.sh
# Purpose: `docker rm $(docker ps -aq)` errors on an empty list, refuses running containers and leaves volumes behind without saying so — this shows what will go, removes it, and reports what survived.
# Usage: ./docker-remove-containers.sh [--running] [--filter KEY=VALUE]... [--yes]   (dry run by default)
set -euo pipefail

CHECK="✓"
CROSS="✗"

INCLUDE_RUNNING=0
YES=0
FILTERS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --running) INCLUDE_RUNNING=1 ;;
    --yes) YES=1 ;;
    --filter) [[ $# -ge 2 ]] || { echo "--filter needs KEY=VALUE" >&2; exit 2; }; FILTERS+=(--filter "$2"); shift ;;
    *) echo "usage: $0 [--running] [--filter KEY=VALUE]... [--yes]" >&2; exit 2 ;;
  esac
  shift
done

command -v docker >/dev/null || { echo "$CROSS docker is not installed" >&2; exit 2; }

# Stopped containers only unless asked: a running container is somebody's service.
# Repeated status filters are OR'ed by docker; different keys (label, name) are AND'ed.
if (( ! INCLUDE_RUNNING )); then
  FILTERS+=(--filter status=exited --filter status=created --filter status=dead)
fi

mapfile -t ROWS < <(docker ps -a "${FILTERS[@]}" --format '{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}')

if [[ ${#ROWS[@]} -eq 0 ]]; then
  # The case that breaks `docker rm $(docker ps -aq)`: an empty list is "requires at least 1 argument".
  echo "$CHECK no containers match — nothing to remove"
  exit 0
fi

IDS=()
for row in "${ROWS[@]}"; do
  IFS=$'\t' read -r id name status image <<< "$row"
  printf '%s %-24s %-28s %s\n' "$CROSS" "$name" "$status" "$image"
  IDS+=("$id")
done

if (( ! YES )); then
  echo "dry run: re-run with --yes to remove ${#IDS[@]} container(s)"
  exit 1
fi

# -v takes anonymous volumes with their container; named volumes always survive rm.
if (( INCLUDE_RUNNING )); then
  docker rm -f -v "${IDS[@]}" >/dev/null
else
  docker rm -v "${IDS[@]}" >/dev/null
fi
echo "$CHECK removed ${#IDS[@]} container(s)"

DANGLING=$(docker volume ls -q --filter dangling=true | wc -l)
echo "  left behind: images, networks, and $DANGLING volume(s) no container uses (docker volume prune removes those)"
