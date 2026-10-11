#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/sudo-rs-wildcards-not-allowed
# Script: sudoers-rs-check.sh
# Purpose: sudo-rs (default sudo on Ubuntu 26.04) silently drops sudoers rules it cannot parse, so a nightly job that ran under sudo for years fails after the upgrade; this finds those rules before you upgrade.
# Usage: sudo ./sudoers-rs-check.sh [SUDOERS_FILE ...]   (default: /etc/sudoers and /etc/sudoers.d/*)
set -euo pipefail

CHECK="✓"
CROSS="✗"

DEFAULT_FILES=(/etc/sudoers)
SUDOERS_DIR="/etc/sudoers.d"
FINDINGS=0

# sudo's includedir skips names containing a dot or ending in ~, so editor backups are never read; mirror that.
if [[ $# -eq 0 && -d "$SUDOERS_DIR" ]]; then
  for f in "$SUDOERS_DIR"/*; do
    name=${f##*/}
    [[ -f "$f" && "$name" != *.* && "$name" != *~ ]] && DEFAULT_FILES+=("$f")
  done
fi
FILES=("$@")
[[ $# -gt 0 ]] || FILES=("${DEFAULT_FILES[@]}")

report() { # file line command reason fix
  echo "$CROSS $1:$2"
  echo "    rule:   $3"
  echo "    why:    $4"
  echo "    fix:    $5"
  FINDINGS=$((FINDINGS + 1))
}

check_command() { # file line command
  local file=$1 line=$2 cmd=$3 args last
  # A digest prefix (sha256:...) pins the binary's hash; sudo-rs rejects the whole rule.
  if [[ "$cmd" =~ ^sha(224|256|384|512): ]]; then
    report "$file" "$line" "$cmd" "digest specifications are not supported by sudo-rs" "drop the sha256:... prefix and make the binary root-owned and not writable by anyone else"
    return
  fi
  read -r _ args <<< "$cmd"
  [[ -n "${args:-}" ]] || return 0
  # ^...$ turns the argument list into a regular expression in sudo 1.9.10+; sudo-rs has no regex support.
  if [[ "$args" == ^*\$ ]]; then
    report "$file" "$line" "$cmd" "regular expressions are not supported by sudo-rs" "list the exact argument lists, or call a root-owned wrapper script that validates its arguments"
    return
  fi
  # sudo-rs accepts \, \: \= \\ and an escaped space; any other backslash (classically \*) is a syntax error.
  if [[ "$args" =~ \\[^,:=\\\ ] ]]; then
    report "$file" "$line" "$cmd" "illegal escape sequence (sudo-rs only accepts \\, \\: \\= \\\\ and an escaped space)" "a literal * argument needs no backslash in sudo-rs; to allow any arguments end the rule with a lone *"
    return
  fi
  # A lone * as the LAST argument means "any further arguments" and is allowed; every other glob character is not.
  last=${args##* }
  local rest=$args
  [[ "$last" == "*" ]] && rest=${args% \*}
  [[ "$rest" == "*" ]] && rest=""
  if [[ "$rest" == *[\*\?\[]* ]]; then
    report "$file" "$line" "$cmd" "wildcards are not allowed in command arguments (only a lone trailing * is)" "end the rule at the fixed arguments with a lone * (e.g. ... add blocklist *) and validate the value inside a wrapper script"
  fi
}

check_line() { # line text  (file is $CURRENT_FILE)
  local file=$CURRENT_FILE line=$1 text=$2 cmds seg
  # Only user specs and Cmnd_Alias lines carry commands; Defaults and the other aliases cannot trigger these errors.
  [[ "$text" =~ ^[[:space:]]*(Defaults|User_Alias|Runas_Alias|Host_Alias|@include|#include) ]] && return 0
  [[ "$text" == *=* ]] || return 0
  cmds=${text#*=}
  # Split on commas that are not backslash-escaped, then strip the (runas) and TAG: prefixes from each command.
  while IFS= read -r seg; do
    seg=${seg#"${seg%%[![:space:]]*}"}
    seg=$(sed -E 's/^\([^)]*\)[[:space:]]*//; s/^([A-Z_]+:[[:space:]]*)+//' <<< "$seg")
    [[ -z "$seg" || "$seg" == "ALL" || "$seg" =~ ^[A-Z][A-Z0-9_]*$ ]] && continue
    check_command "$file" "$line" "$seg"
  done < <(sed -E 's/\\,/\x01/g; s/,/\n/g; s/\x01/\\,/g' <<< "$cmds")
}

for file in "${FILES[@]}"; do
  if [[ ! -r "$file" ]]; then
    echo "$CROSS cannot read $file (sudoers files are root-only: run this with sudo)" >&2
    exit 2
  fi
  CURRENT_FILE=$file
  start=0 buf=""
  lineno=0
  while IFS= read -r raw || [[ -n "$raw" ]]; do
    lineno=$((lineno + 1))
    [[ "$raw" =~ ^[[:space:]]*# ]] && continue
    # A trailing backslash continues the rule on the next line, and the error is reported against the first one.
    if [[ -z "$buf" ]]; then start=$lineno; fi
    if [[ "$raw" == *\\ ]]; then buf+="${raw%\\} "; continue; fi
    buf+="$raw"
    check_line "$start" "$buf"
    buf=""
  done < "$file"
done

# On a box that already runs sudo-rs, its own visudo is the final authority on what it will load.
if command -v visudo >/dev/null && visudo --version 2>/dev/null | grep -q 'sudo-rs'; then
  if visudo -c >/dev/null 2>&1; then
    echo "$CHECK sudo-rs visudo -c accepts every file"
  else
    echo "$CROSS sudo-rs visudo -c reports:"
    visudo -c 2>&1 | sed 's/^/    /' || true
    FINDINGS=$((FINDINGS + 1))
  fi
fi

if (( FINDINGS == 0 )); then
  echo "$CHECK ${#FILES[@]} file(s) checked: nothing sudo-rs would reject"
  exit 0
fi
echo "$CROSS $FINDINGS problem(s): sudo-rs ignores each rule above, and every sudo call prints the parse error"
exit 1
