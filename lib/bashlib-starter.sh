#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/bashlib-starter
# Script: bashlib-starter.sh — ten functions to source into every script
# Purpose: Without it every script re-invents (or forgets) strict mode, an ERR trap
#          that names the failing line, cleanup on every exit path, a lock and a timeout
# Usage:
#   source "/path/to/bashlib-starter.sh"
#   enable_strict_traps                        # set -Eeuo pipefail + ERR/EXIT traps
#   require_cmd curl timeout                   # fail before doing any work
#   acquire_lock                               # one running copy at a time
#   tmp="$(make_temp_file)"                    # deleted on every exit path
#   run_with_timeout 30 curl -fsS "$URL" -o "$tmp"
#   retry 5 2 -- rsync -a "$tmp" backup:/srv/
#   log INFO "done"
#
# This is a library: source it, don't run it. Sourcing changes nothing about your
# shell until you call enable_strict_traps — that decision stays in your script.
# Same function names as the Production Bash Toolkit's bashlib.sh
# (https://bashsnippets.xyz/starter-kit).
# Tested: Kali 2026.3 (bash 5.3) — see bashlib-starter.test.sh. MIT licence.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "bashlib-starter.sh is a library: source it from your script, don't run it." >&2
  exit 1
fi
# Safe to source from several files; the second source is a no-op.
if [[ -n "${_BASHLIB_STARTER_LOADED:-}" ]]; then
  return 0
fi
_BASHLIB_STARTER_LOADED=1

_BL_TEMP_ITEMS=()
# tmp="$(make_temp_file)" runs make_temp_file in a subshell, and an array change
# made there dies with it. So enable_strict_traps also creates this private
# registry file: a path appended to a file survives the subshell.
_BL_TEMP_REGISTRY=""

# 1. log LEVEL MESSAGE... — timestamped line on stderr, plus $LOG_FILE if set.
#    stderr keeps a function's stdout clean for "$(capture)".
log() {
  local level="$1"; shift
  local line
  line="$(date '+%Y-%m-%d %H:%M:%S') [${level}] $*"
  printf '%s\n' "$line" >&2
  if [[ -n "${LOG_FILE:-}" ]]; then
    printf '%s\n' "$line" >> "$LOG_FILE" 2>/dev/null || true
  fi
}

# 2. die [CODE] MESSAGE... — log an error and exit (code 1 unless given).
die() {
  local code=1
  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    code="$1"; shift
  fi
  log ERROR "$*"
  exit "$code"
}

# 3. require_cmd CMD... — check every tool up front, so a missing one fails
#    before the script has half-done anything.
require_cmd() {
  local c missing=0
  for c in "$@"; do
    if ! command -v "$c" >/dev/null 2>&1; then
      log ERROR "required command not found: $c"
      missing=1
    fi
  done
  if (( missing )); then
    die "install the missing command(s) and re-run"
  fi
}

# 4. enable_strict_traps — strict mode plus the two traps that make it survivable.
#    -E is the letter most strict-mode lines miss: without it the ERR trap does
#    not fire inside functions, and a failure one level down exits with no message.
enable_strict_traps() {
  set -Eeuo pipefail
  if [[ -z "$_BL_TEMP_REGISTRY" ]]; then
    _BL_TEMP_REGISTRY="$(mktemp "${TMPDIR:-/tmp}/bashlib.reg.XXXXXX")" || die "mktemp failed"
  fi
  trap '_bl_on_err "$?" "$LINENO" "$BASH_COMMAND"' ERR
  trap '_bl_cleanup' EXIT
}

_bl_on_err() {
  log ERROR "failed (exit $1) at line $2: $3"
}

# Runs on every exit path: success, exit N, a set -e abort, Ctrl-C, SIGTERM.
# It never calls exit, so the script's own exit status passes through untouched.
_bl_cleanup() {
  local item
  local -a items=()
  items=(${_BL_TEMP_ITEMS[@]+"${_BL_TEMP_ITEMS[@]}"})
  if [[ -n "$_BL_TEMP_REGISTRY" && -f "$_BL_TEMP_REGISTRY" ]]; then
    while IFS= read -r -d '' item; do
      items+=("$item")
    done < "$_BL_TEMP_REGISTRY"
    items+=("$_BL_TEMP_REGISTRY")
  fi
  for item in ${items[@]+"${items[@]}"}; do
    if [[ -e "$item" ]]; then
      rm -rf -- "$item" || true
    fi
  done
}

# 5. register_temp PATH — delete PATH (file or directory) when the script exits.
#    Safe to call inside $( ).
register_temp() {
  _BL_TEMP_ITEMS+=("$1")
  if [[ -n "$_BL_TEMP_REGISTRY" ]]; then
    printf '%s\0' "$1" >> "$_BL_TEMP_REGISTRY"
  fi
}

# 6. make_temp_file [VAR] — create a private temp file that is deleted on exit.
#    tmp="$(make_temp_file)" prints the path; make_temp_file tmp sets $tmp directly.
# shellcheck disable=SC2120  # the variable-name argument is optional
make_temp_file() {
  local _bl_path
  _bl_path="$(mktemp "${TMPDIR:-/tmp}/bashlib.XXXXXX")" || die "mktemp failed"
  register_temp "$_bl_path"
  if [[ -n "${1:-}" ]]; then
    printf -v "$1" '%s' "$_bl_path"
  else
    printf '%s\n' "$_bl_path"
  fi
}

# 7. make_temp_dir [VAR] — the same, for a directory removed whole on exit.
# shellcheck disable=SC2120  # the variable-name argument is optional
make_temp_dir() {
  local _bl_path
  _bl_path="$(mktemp -d "${TMPDIR:-/tmp}/bashlib.XXXXXX")" || die "mktemp -d failed"
  register_temp "$_bl_path"
  if [[ -n "${1:-}" ]]; then
    printf -v "$1" '%s' "$_bl_path"
  else
    printf '%s\n' "$_bl_path"
  fi
}

# 8. acquire_lock [LOCKDIR] — allow one running copy. mkdir is atomic, so two
#    starts can never both win. A lock whose PID is gone is reclaimed; a lock with
#    no PID yet belongs to a copy that is starting right now, so we back off.
acquire_lock() {
  local lockdir="${1:-${TMPDIR:-/tmp}/$(basename -- "$0").lock.d}"
  local owner=""
  if ! mkdir "$lockdir" 2>/dev/null; then
    owner="$(cat "$lockdir/pid" 2>/dev/null || true)"
    if [[ -z "$owner" ]] || ps -p "$owner" >/dev/null 2>&1; then
      die "already running (PID ${owner:-starting}, lock $lockdir)"
    fi
    log WARN "reclaiming stale lock left by PID $owner"
    rm -rf -- "$lockdir"
    mkdir "$lockdir" 2>/dev/null || die "lost the race for $lockdir"
  fi
  printf '%s\n' "$$" > "$lockdir/pid"
  register_temp "$lockdir"
}

# 9. run_with_timeout SECONDS CMD... — kill a hung command instead of letting it
#    hang the script (and hold its lock) forever. Exit 124 means it timed out.
#    CMD must be a program, not a shell function: timeout cannot run functions.
run_with_timeout() {
  local secs="$1"; shift
  local rc=0
  # --kill-after: a command that ignores SIGTERM gets SIGKILL 5 s later.
  timeout --kill-after=5 "$secs" "$@" || rc=$?
  if (( rc == 124 )); then
    log ERROR "timed out after ${secs}s: $*"
  fi
  return "$rc"
}

# 10. retry MAX BASE_SECONDS -- CMD... — rerun a flaky command with exponential
#     backoff (BASE, 2×BASE, 4×BASE...). Returns the last attempt's exit code.
retry() {
  local max="$1" delay="$2" attempt=1 rc
  shift 2
  if [[ "${1:-}" == "--" ]]; then
    shift
  fi
  [[ "$max" =~ ^[1-9][0-9]*$ ]] || die "retry: MAX must be a positive integer, got '$max'"
  [[ "$delay" =~ ^[0-9]+$ ]] || die "retry: BASE_SECONDS must be a whole number, got '$delay'"
  while true; do
    rc=0
    "$@" || rc=$?
    if (( rc == 0 )); then
      return 0
    fi
    if (( attempt >= max )); then
      log ERROR "gave up after ${max} attempts (last exit ${rc}): $*"
      return "$rc"
    fi
    log WARN "attempt ${attempt}/${max} failed (exit ${rc}); retrying in ${delay}s"
    sleep "$delay"
    delay=$(( delay * 2 ))
    attempt=$(( attempt + 1 ))
  done
}
