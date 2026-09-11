#!/bin/bash
# Script: bashlib-starter.test.sh
# Purpose: Prove every function in bashlib-starter.sh does what its comment says —
#          on the failure paths, not only the happy one
# Usage: bash lib/bashlib-starter.test.sh
set -euo pipefail

CHECK="✓"
CROSS="✗"

LIB="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/bashlib-starter.sh"
WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
FAILS=0

# check NAME CONDITION... — run the condition, print ✓/✗, count failures.
check() {
  local name="$1"; shift
  if "$@"; then
    echo "$CHECK $name"
  else
    echo "$CROSS $name"
    FAILS=$(( FAILS + 1 ))
  fi
}

# run_case NAME BODY — write a script that sources the library, run it, and keep
# its exit code in RC and its stderr in ERR_OUT.
run_case() {
  local name="$1" body="$2"
  printf '#!/bin/bash\nsource "%s"\n%s\n' "$LIB" "$body" > "$WORK/$name.sh"
  RC=0
  bash "$WORK/$name.sh" > "$WORK/$name.out" 2> "$WORK/$name.err" || RC=$?
  ERR_OUT="$(cat "$WORK/$name.err")"
}

has() { [[ "$ERR_OUT" == *"$1"* ]]; }
gone() { [[ ! -e "$1" ]]; }

# 1–4: an ERR trap that names the failing command inside a function
run_case err 'enable_strict_traps
helper() {
  ls /nonexistent-bashlib-test
}
helper
echo unreachable'
check "ERR trap names the failing command inside a function" has "at line 5: ls /nonexistent-bashlib-test"
check "set -e stopped the script (exit 2 from ls)" test "$RC" -eq 2

# 5–6: temp files are removed on an error exit
run_case tmp_err "enable_strict_traps
make_temp_file t
make_temp_dir d
echo \"\$t \$d\" > '$WORK/tmp_err.paths'
false"
read -r T D < "$WORK/tmp_err.paths"
check "temp file removed after a set -e abort" gone "$T"
check "temp dir removed after a set -e abort" gone "$D"
check "exit status of the failure preserved (1)" test "$RC" -eq 1

# exit status of an explicit exit passes through the cleanup trap
run_case tmp_exit "enable_strict_traps
make_temp_file t
exit 3"
check "explicit exit 3 still exits 3 with cleanup registered" test "$RC" -eq 3

# cleanup on SIGTERM
# shellcheck disable=SC2016  # $d expands in the generated script, not here
printf '#!/bin/bash\nsource "%s"\nenable_strict_traps\nmake_temp_dir d\necho "$d" > "%s"\nsleep 30\n' \
  "$LIB" "$WORK/term.path" > "$WORK/term.sh"
bash "$WORK/term.sh" & PID=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -s "$WORK/term.path" ]] && break; sleep 0.2; done
kill -TERM "$PID"
RC=0; wait "$PID" || RC=$?
check "SIGTERM exits 143" test "$RC" -eq 143
check "temp dir removed after SIGTERM" gone "$(cat "$WORK/term.path")"

# 8: acquire_lock — second copy refused, lock released on exit, stale lock reclaimed
LOCK="$WORK/job.lock.d"
printf '#!/bin/bash\nsource "%s"\nenable_strict_traps\nacquire_lock "%s"\nsleep 3\n' \
  "$LIB" "$LOCK" > "$WORK/holder.sh"
bash "$WORK/holder.sh" & HOLDER=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -s "$LOCK/pid" ]] && break; sleep 0.2; done
run_case second "enable_strict_traps
acquire_lock '$LOCK'"
check "second copy refused while the first holds the lock" has "already running (PID $HOLDER"
check "refused copy exits 1" test "$RC" -eq 1
wait "$HOLDER"
check "lock released when the holder exits" gone "$LOCK"

bash -c 'exit 0' & DEAD=$!; wait "$DEAD"
mkdir "$LOCK"; echo "$DEAD" > "$LOCK/pid"
run_case stale "enable_strict_traps
acquire_lock '$LOCK'
echo got-it"
check "stale lock from a dead PID is reclaimed" has "reclaiming stale lock left by PID $DEAD"
check "reclaiming copy runs to completion" test "$(cat "$WORK/stale.out")" = "got-it"

# 9: run_with_timeout
# shellcheck disable=SC2016  # $rc belongs to the generated script
run_case timeout 'rc=0
run_with_timeout 1 sleep 5 || rc=$?
echo "$rc"'
check "a hung command is killed and returns 124" test "$(cat "$WORK/timeout.out")" = "124"
check "the timeout is logged" has "timed out after 1s: sleep 5"

# 10: retry — succeeds on the third attempt, gives up with the last exit code
run_case retry_ok "n=0
flaky() { n=\$(( n + 1 )); [ \"\$n\" -ge 3 ]; }
retry 5 0 -- flaky
echo \"\$n\""
check "retry succeeds on the third attempt" test "$(cat "$WORK/retry_ok.out")" = "3"
check "retry logs each failed attempt" has "attempt 2/5 failed"
# shellcheck disable=SC2016  # $rc belongs to the generated script
run_case retry_fail 'rc=0
retry 2 0 -- bash -c "exit 7" || rc=$?
echo "$rc"'
check "retry returns the last exit code after giving up" test "$(cat "$WORK/retry_fail.out")" = "7"
run_case retry_bad 'retry abc 1 -- true'
check "retry rejects a non-numeric MAX" has "MAX must be a positive integer"

# 1–3: log, die, require_cmd
run_case die 'die 7 "disk is full"'
check "die exits with the given code" test "$RC" -eq 7
check "die logs the message at ERROR" has "[ERROR] disk is full"
run_case req 'require_cmd bash no-such-tool-bashlib'
check "require_cmd names the missing tool" has "required command not found: no-such-tool-bashlib"
check "require_cmd exits 1" test "$RC" -eq 1
run_case logfile "LOG_FILE='$WORK/app.log'
log INFO 'written to both'"
check "log also appends to \$LOG_FILE" grep -q "\[INFO\] written to both" "$WORK/app.log"

# library guards
RC=0; bash "$LIB" 2> "$WORK/direct.err" || RC=$?
ERR_OUT="$(cat "$WORK/direct.err")"
check "running the library directly is refused" has "source it from your script"
run_case twice "source '$LIB'
echo ok"
check "sourcing twice is harmless" test "$(cat "$WORK/twice.out")" = "ok"
run_case no_strict 'false
echo "still running"'
check "sourcing alone does not turn on set -e" test "$(cat "$WORK/no_strict.out")" = "still running"

echo
if (( FAILS )); then
  echo "$CROSS $FAILS check(s) failed"
  exit 1
fi
echo "$CHECK all checks passed"
