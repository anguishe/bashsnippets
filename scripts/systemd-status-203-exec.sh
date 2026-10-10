#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/systemd-status-203-exec
# Script: execstart-check.sh
# Purpose: status=203/EXEC has at least five causes and systemctl status shows the same code for all of them; this checks a unit's ExecStart= the way the kernel will, before or after it fails.
# Usage: ./execstart-check.sh [--user] UNIT   (e.g. ./execstart-check.sh myapp.service)
set -euo pipefail

CHECK="✓"
CROSS="✗"

SCOPE=()
if [[ "${1:-}" == "--user" ]]; then SCOPE=(--user); shift; fi
[[ $# -eq 1 ]] || { echo "usage: $0 [--user] UNIT" >&2; exit 2; }
UNIT="$1"
PROBLEMS=0
fail() { echo "$CROSS $*"; PROBLEMS=$((PROBLEMS + 1)); }

# systemctl show prints what systemd actually loaded, which is not the file on disk until daemon-reload has run.
if [[ "$(systemctl "${SCOPE[@]}" show -p NeedDaemonReload --value "$UNIT")" == "yes" ]]; then
  fail "the unit file changed on disk but systemd still runs the old copy: systemctl ${SCOPE[*]} daemon-reload"
fi
LOAD=$(systemctl "${SCOPE[@]}" show -p LoadState --value "$UNIT")
[[ "$LOAD" == "loaded" ]] || { fail "LoadState=$LOAD (not-found: wrong name or file not in a unit directory; masked: systemctl ${SCOPE[*]} unmask $UNIT)"; exit 1; }

EXEC_PROP=$(systemctl "${SCOPE[@]}" show -p ExecStart --value "$UNIT")
EXEC_PATH=$(sed -n 's/.*path=\([^ ;]*\).*/\1/p' <<< "$EXEC_PROP" | head -1)
# A leading ! is the user manager's own default (home, used only if it exists) and - marks a directory optional.
WORKDIR=$(systemctl "${SCOPE[@]}" show -p WorkingDirectory --value "$UNIT")
[[ "$WORKDIR" == '!'* ]] && WORKDIR=""
RUN_USER=$(systemctl "${SCOPE[@]}" show -p User --value "$UNIT")
echo "  $UNIT: ExecStart path=$EXEC_PATH${WORKDIR:+, WorkingDirectory=$WORKDIR}${RUN_USER:+, User=$RUN_USER}"
[[ -n "$EXEC_PATH" ]] || { fail "no ExecStart= found (a oneshot with only ExecStartPre=, or a typo in the key)"; exit 1; }

# 203/EXEC "Unable to locate executable": systemd does not search your shell's PATH for a relative name.
if [[ "$EXEC_PATH" != /* ]]; then
  fail "ExecStart= is not an absolute path; systemd looks it up in its own fixed search path, not yours. Use the full path"
elif [[ ! -e "$EXEC_PATH" ]]; then
  fail "$EXEC_PATH does not exist (typo, a moved venv, or a path inside a mount that is not up yet)"
else
  OPTS=$(findmnt -no OPTIONS --target "$EXEC_PATH" 2>/dev/null || true)
  # 203/EXEC "Permission denied": the execute bit, or a noexec mount, which beats every mode bit.
  if [[ ",$OPTS," == *",noexec,"* ]]; then
    fail "$EXEC_PATH is on a noexec mount ($(findmnt -no TARGET --target "$EXEC_PATH")): ExecStart=/bin/bash $EXEC_PATH, or move it"
  elif [[ ! -x "$EXEC_PATH" ]]; then
    fail "$EXEC_PATH is not executable: chmod +x $EXEC_PATH"
  fi
  # Text files need a #! line; without one, execve() returns ENOEXEC, which systemd logs as "Exec format error".
  if head -c 4 "$EXEC_PATH" | grep -q $'^\x7fELF'; then
    :
  elif ! IFS= read -r FIRST < "$EXEC_PATH"; then
    fail "cannot read $EXEC_PATH as $(id -un)"
  elif [[ "$FIRST" != '#!'* ]]; then
    fail "$EXEC_PATH has no #! line (Exec format error): add #!/bin/bash as line 1"
  else
    # A CRLF line ending makes the interpreter "/bin/bash\r", which does not exist.
    if [[ "$FIRST" == *$'\r' ]]; then fail "the #! line ends in a carriage return (CRLF file): sed -i 's/\\r\$//' $EXEC_PATH"; fi
    INTERP=${FIRST#\#!}; INTERP=${INTERP#"${INTERP%%[! ]*}"}; INTERP=${INTERP%%[ $'\r']*}
    if [[ "$FIRST" != *$'\r' && ! -x "$INTERP" ]]; then fail "interpreter $INTERP from the #! line does not exist or is not executable"; fi
  fi
fi

# 200/CHDIR and 217/USER fail before ExecStart is even tried, so they hide behind the same "failed" state.
if [[ -n "$WORKDIR" && "$WORKDIR" != -* && ! -d "$WORKDIR" ]]; then
  fail "WorkingDirectory=$WORKDIR does not exist (status=200/CHDIR); prefix it with - to make it optional"
fi
if [[ -n "$RUN_USER" ]] && ! getent passwd "$RUN_USER" >/dev/null; then
  fail "User=$RUN_USER does not exist (status=217/USER): create it, or use DynamicUser=yes"
fi

if (( PROBLEMS == 0 )); then
  echo "$CHECK nothing in ExecStart= would stop exec; if it still fails, the program itself exited: journalctl ${SCOPE[*]} -u $UNIT -n 20"
  exit 0
fi
exit 1
