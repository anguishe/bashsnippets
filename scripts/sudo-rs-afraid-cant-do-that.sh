#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/sudo-rs-afraid-cant-do-that
# Script: why-sudo-denied.sh
# Purpose: sudo-rs answers "I'm afraid I can't do that" for a missing rule, a rule it dropped as unparseable and a one-character argument mismatch alike; this says which one it is.
# Usage: ./why-sudo-denied.sh COMMAND [ARGS...]   (run as the user who was denied, without sudo)
set -euo pipefail

CHECK="✓"
CROSS="✗"

[[ $# -ge 1 ]] || { echo "usage: $0 COMMAND [ARGS...]" >&2; exit 2; }
[[ $EUID -ne 0 ]] || { echo "$CROSS run this as the user who was denied, not as root" >&2; exit 2; }

SUDO_BIN=$(command -v sudo) || { echo "$CROSS sudo is not installed"; exit 1; }
# Ubuntu 26.04 points /usr/bin/sudo at sudo-rs through update-alternatives; sudo.ws is the classic sudo.
echo "  sudo: $(readlink -f "$SUDO_BIN") ($("$SUDO_BIN" --version 2>/dev/null | head -1))"
echo "  you:  $(id -un), groups: $(id -nG)"

# -n never prompts, so this cannot hang a script; stderr carries any sudoers lines the parser threw away.
LIST_ERR=$(mktemp)
trap 'rm -f "$LIST_ERR"' EXIT
LIST_OUT=$("$SUDO_BIN" -n -l 2>"$LIST_ERR") && LIST_RC=0 || LIST_RC=$?

if grep -q 'syntax error\|not allowed\|not supported\|illegal' "$LIST_ERR"; then
  echo "$CROSS sudoers has lines sudo-rs could not parse; those rules are ignored:"
  grep -E '^/etc/sudoers' "$LIST_ERR" | sed 's/^/    /'
  echo "    fix them (sudoers-rs-check.sh lists each one); classic sudo, if installed, is sudo.ws"
fi

if (( LIST_RC != 0 )); then
  if grep -qi 'authenticat\|password is required' "$LIST_ERR"; then
    # Not a denial: a rule matches you but wants a password, and -n (or cron, or ansible) cannot type one.
    echo "  you have rules, but they need your password, so -n cannot check them."
    echo "  'interactive authentication is required' from a script means exactly this: add NOPASSWD"
    echo "  for that one command, or run: sudo -l $*   (it prompts, then prints the match or nothing)"
    exit 3
  else
    echo "$CROSS sudo -l failed: $(tail -1 "$LIST_ERR")"
    echo "    no rule names you or your groups: an admin has to add one (visudo -f /etc/sudoers.d/$(id -un))"
    exit 1
  fi
else
  echo "  rules for you:"
  grep -E '^[[:space:]]+\(' <<< "$LIST_OUT" | sed 's/^[[:space:]]*/    /'
fi

# sudo -l COMMAND ARGS answers "would this exact command line be allowed?" with exit 0 and the resolved path.
if MATCH=$("$SUDO_BIN" -n -l "$@" 2>/dev/null); then
  echo "$CHECK allowed: $MATCH"
  if ! grep -q 'NOPASSWD' <<< "$LIST_OUT"; then
    echo "    it needs your password: in a script without a terminal sudo -n stops with 'interactive authentication is required'"
  fi
  exit 0
fi

echo "$CROSS not allowed: $*"
RESOLVED=$(PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" command -v "$1" || true)
if [[ -z "$RESOLVED" ]]; then
  # secure_path replaces your PATH, so a tool in ~/bin or a venv is invisible to sudo.
  echo "    $1 is not on sudo's secure_path; call it by its full path, and the rule must name that path"
elif grep -qF "$RESOLVED" <<< "$LIST_OUT"; then
  echo "    a rule names $RESOLVED, but not with these arguments. Arguments must match exactly"
  echo "    (a trailing slash or a different order counts). Rules for it:"
  grep -F "$RESOLVED" <<< "$LIST_OUT" | sed 's/^[[:space:]]*/      /'
else
  echo "    no rule mentions $RESOLVED"
fi
exit 1
