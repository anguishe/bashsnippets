#!/bin/bash
# Script: bashlib.sh
# Purpose: Shared functions so logging and dependency checks live in exactly one place.
# Usage: source bashlib.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"

# Timestamped info line to stdout.
log_info() {
  local msg="$1"
  echo "$CHECK [$(date +%H:%M:%S)] $msg"
}

# Error line to stderr so it survives stdout redirection.
log_error() {
  local msg="$1"
  echo "$CROSS [$(date +%H:%M:%S)] $msg" >&2
}

# Abort early if a required command is missing, with a clear message.
require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "required command not found: $cmd"
    return 1
  fi
}
