#!/bin/bash
# Script: bash-environment-variables.sh
# Purpose: A variable that was set but never exported is invisible to every
#          child process — the deploy script reads an empty API_TOKEN and runs
#          against production anyway. This shows each inheritance rule with
#          live output so you meet the trap here instead of in an outage.
# Usage: ./bash-environment-variables.sh
# Tested: Kali 2026.3 (bash 5.3), Ubuntu 22.04 LTS, Fedora 39
set -euo pipefail

CHECK="✓"
CROSS="✗"

# ── CONFIGURATION ──────────────────────────────────────────────
SHOWN_VALUE="from-parent"     # the value every test below tries to read back

# child_sees NAME — what a freshly started bash (a real child process, like
# a script you execute) sees for NAME. ${!1} is indirect expansion: the
# variable whose name is in $1. Unset is reported as text, never fatal.
child_sees() {
  bash -c 'printf "%s" "${!1:-<unset>}"' _ "$1"
}

# empty_env_sees NAME — the same, but the child starts with NO environment.
# env -i empties it first: the closest thing to how cron launches a job.
empty_env_sees() {
  env -i bash -c "printf '%s' \"\${!1:-<unset>}\"" _ "$1"
}

section() { printf '\n── %s ──\n' "$1"; }

section "1. Shell variable vs exported variable"
PLAIN="$SHOWN_VALUE"            # shell variable: lives in this process only
export EXPORTED="$SHOWN_VALUE"  # environment variable: copied into every child
printf '%-22s parent=%-12s child=%s\n' "PLAIN (not exported)" "$PLAIN" "$(child_sees PLAIN)"
printf '%-22s parent=%-12s child=%s\n' "EXPORTED" "$EXPORTED" "$(child_sees EXPORTED)"

section "2. Subshell ( ) vs child process"
# A ( ) subshell is a fork of THIS shell, so it inherits everything, exported
# or not. A separately executed script is a new program: exports only.
( printf '%-22s %s\n' "subshell sees PLAIN:" "${PLAIN:-<unset>}" )
printf '%-22s %s\n' "bash -c sees PLAIN:" "$(child_sees PLAIN)"

section "3. Running a file vs sourcing it"
SETTER=$(mktemp)
trap 'rm -f "$SETTER"' EXIT
echo 'FROM_FILE="set-inside-file"' > "$SETTER"
bash "$SETTER"                      # child process: sets FROM_FILE, then exits with it
printf '%-22s %s\n' "after bash file:" "${FROM_FILE:-<unset>}"
# shellcheck source=/dev/null
source "$SETTER"                    # same process: the assignment survives
printf '%-22s %s\n' "after source file:" "${FROM_FILE:-<unset>}"

section "4. env -i: the environment cron starts your job with"
# PATH survives only because bash sets a built-in default when none is given.
# Everything you exported in .bashrc, and HOME itself, is gone.
printf '%-22s %s\n' "PATH under env -i:" "$(empty_env_sees PATH)"
printf '%-22s %s\n' "HOME under env -i:" "$(empty_env_sees HOME)"
printf '%-22s %s\n' "EXPORTED under env -i:" "$(empty_env_sees EXPORTED)"

section "5. Defaults and required variables"
printf '%-22s %s\n' "\${PORT:-8080}:" "${PORT:-8080}"
# :? aborts the shell with the message when the variable is unset or empty.
# Run in a child so this demo survives; in a real script the abort is the point.
API_CHECK_EXIT=0
API_CHECK_MSG=$(bash -c ': "${API_TOKEN:?must be set before deploy}"' 2>&1) || API_CHECK_EXIT=$?
if [ "$API_CHECK_EXIT" -eq 0 ]; then
  echo "$CHECK API_TOKEN is set"
else
  echo "$CROSS \${API_TOKEN:?...} aborted with exit $API_CHECK_EXIT:"
  echo "    $API_CHECK_MSG"
fi

section "6. unset vs empty — not the same thing"
export EMPTY=""
unset EXPORTED
# ${VAR-x} (no colon) substitutes only when unset; ${VAR:-x} also when empty.
printf '%-22s %s\n' "EMPTY, \${EMPTY-x}:" "$(bash -c 'printf "%s" "${EMPTY-<unset>}"')"
printf '%-22s %s\n' "EMPTY, \${EMPTY:-x}:" "$(bash -c 'printf "%s" "${EMPTY:-<empty>}"')"
printf '%-22s %s\n' "EXPORTED after unset:" "$(child_sees EXPORTED)"

section "7. printenv shows the environment, not shell variables"
if printenv PLAIN; then
  echo "$CHECK PLAIN is in the environment"
else
  echo "$CROSS printenv PLAIN found nothing (exit $?) — PLAIN is a shell variable, not environment"
fi
