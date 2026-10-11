#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/uutils-vs-gnu-coreutils
# Script: coreutils-diff.sh
# Purpose: A script that passed on GNU coreutils can change exit codes, stderr text or output under Ubuntu 26.04's Rust coreutils without failing loudly; this runs it under both and shows every difference.
# Usage: ./coreutils-diff.sh 'COMMAND LINE'   (runs it twice, each time in a fresh copy of the current directory)
set -euo pipefail

CHECK="✓"
CROSS="✗"

UU_DIR="${UU_DIR:-/usr/lib/cargo/bin/coreutils}"   # where Ubuntu's rust-coreutils keeps one link per command
GNU_PREFIX="${GNU_PREFIX:-/usr/bin/gnu}"           # gnu-coreutils installs GNU as gnuls, gnusort, ...
MAX_COPY_KB=51200                                   # copying a huge directory twice is a mistake, not a test

[[ $# -eq 1 ]] || { echo "usage: $0 'COMMAND LINE'" >&2; exit 2; }
CMDLINE="$1"
[[ -d "$UU_DIR" ]] || { echo "$CROSS no uutils at $UU_DIR (set UU_DIR)" >&2; exit 2; }
[[ -x "${GNU_PREFIX}ls" ]] || { echo "$CROSS no GNU coreutils at ${GNU_PREFIX}ls (apt install gnu-coreutils, or set GNU_PREFIX)" >&2; exit 2; }

SIZE_KB=$(du -sk . | cut -f1)
(( SIZE_KB <= MAX_COPY_KB )) || { echo "$CROSS current directory is ${SIZE_KB} KB; run this in a small scratch copy" >&2; exit 2; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Each implementation gets a bin dir of links named ls, sort, ... so the command line and every script it calls
# resolve coreutils there first, and error messages carry the plain name (ls:, not gnuls:) on both sides.
mkdir -p "$WORK/bin-gnu" "$WORK/bin-uutils"
for uu in "$UU_DIR"/*; do
  name=${uu##*/}
  ln -s "$uu" "$WORK/bin-uutils/$name"
  [[ -x "${GNU_PREFIX}${name}" ]] && ln -s "${GNU_PREFIX}${name}" "$WORK/bin-gnu/$name"
done

run_as() { # impl
  local impl=$1
  mkdir -p "$WORK/run-$impl"
  # Side effects (rm, mv, a log append) land in a private copy, so the second run starts from the same state.
  cp -a . "$WORK/run-$impl/dir"
  ( cd "$WORK/run-$impl/dir" && PATH="$WORK/bin-$impl:$PATH" \
      bash -c "$CMDLINE" > "$WORK/run-$impl/out" 2> "$WORK/run-$impl/err" ) && rc=0 || rc=$?
  echo "$rc" > "$WORK/run-$impl/rc"
}
run_as gnu
run_as uutils

DIFFS=0
compare() { # label file
  if ! cmp -s "$WORK/run-gnu/$2" "$WORK/run-uutils/$2"; then
    echo "$CROSS $1 differs (< GNU, > uutils):"
    # diff exits 1 when files differ, which is the expected case here, not an error for set -e/pipefail.
    { diff "$WORK/run-gnu/$2" "$WORK/run-uutils/$2" || true; } | grep '^[<>]' | head -20 | sed 's/^/    /'
    DIFFS=$((DIFFS + 1))
  fi
}
compare "exit status" rc
compare "stdout" out
compare "stderr" err
# Files the command left behind are output too: a report it wrote, or a log it appended to.
if ! diff -rq "$WORK/run-gnu/dir" "$WORK/run-uutils/dir" >/dev/null 2>&1; then
  echo "$CROSS files left behind differ:"
  { diff -rq "$WORK/run-gnu/dir" "$WORK/run-uutils/dir" || true; } | sed "s#$WORK/run-##g; s/^/    /" | head -20
  DIFFS=$((DIFFS + 1))
fi

if (( DIFFS == 0 )); then
  echo "$CHECK identical under GNU $("${GNU_PREFIX}ls" --version | head -1 | awk '{print $NF}') and uutils $("$UU_DIR/ls" --version | head -1 | awk '{print $NF}'): exit $(cat "$WORK/run-gnu/rc"), same stdout, stderr and files"
  exit 0
fi
exit 1
