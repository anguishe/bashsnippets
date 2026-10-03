#!/bin/bash
# Script: why-command-not-found.sh
# Purpose: "command not found" has six different causes and the message is identical for all of them — this names the one that applies.
# Usage: ./why-command-not-found.sh COMMAND
set -euo pipefail

CHECK="✓"
CROSS="✗"

# Where installers drop binaries that are often NOT on PATH (pip --user, cargo, go, snap, /opt bundles, sbin for non-root).
EXTRA_DIRS=("$HOME/.local/bin" "$HOME/bin" "$HOME/.cargo/bin" "$HOME/go/bin" /usr/local/bin /usr/local/sbin /usr/sbin /sbin /snap/bin)
# cron runs jobs with this PATH unless the crontab sets its own.
CRON_PATH="/usr/bin:/bin"

[[ $# -eq 1 ]] || { echo "usage: $0 COMMAND" >&2; exit 2; }
NAME="$1"

# 1. Resolvable from this script's PATH? An alias or function in your interactive shell is invisible here, which is the point: scripts don't see them either.
if FOUND=$(type -P -- "$NAME"); then
  echo "$CHECK $NAME resolves to $FOUND"
  # A CRLF shebang makes an existing file fail with exit 127 ("env: 'bash\r'") or 126 ("bad interpreter").
  if head -c 200 -- "$FOUND" | head -n 1 | grep -q $'\r'; then
    printf '%s\n' "$CROSS its first line ends in a carriage return (CRLF): fix with sed -i 's/\\r\$//' $FOUND"
    exit 1
  fi
  # Found by an interactive shell but missing from cron's PATH: the classic "works in terminal, 127 in cron".
  CRON_HIT=$(PATH="$CRON_PATH" type -P -- "$NAME" || true)
  if [[ -z "$CRON_HIT" ]]; then
    echo "$CROSS cron's default PATH ($CRON_PATH) will NOT find it: use $FOUND in the crontab, or set PATH= at its top"
  else
    echo "$CHECK cron's default PATH finds it too ($CRON_HIT)"
  fi
  echo "  if your terminal still says 'not found' or 'No such file', its hash table is stale: run hash -r"
  exit 0
fi

echo "$CROSS $NAME is not on PATH"

# 2. Present in the current directory: bash never searches . unless PATH says so.
if [[ -x "./$NAME" && ! -d "./$NAME" ]]; then
  echo "  it is in the current directory: run it as ./$NAME"
  exit 1
fi

# 3. Installed somewhere PATH doesn't cover.
for dir in "${EXTRA_DIRS[@]}" /opt/*/bin; do
  [[ -d "$dir" ]] || continue
  if [[ -e "$dir/$NAME" ]]; then
    if [[ -x "$dir/$NAME" ]]; then
      echo "  found at $dir/$NAME, which is not on PATH: export PATH=\"$dir:\$PATH\" (add to ~/.bashrc to keep it)"
    else
      echo "  found at $dir/$NAME but it is not executable: chmod +x $dir/$NAME"
    fi
    exit 1
  fi
done

# 4. Nothing anywhere: typo or not installed. Two swapped neighbours (gti, sl, pyhton) is the commonest typo, so try each swap.
for (( i = 0; i < ${#NAME} - 1; i++ )); do
  SWAP="${NAME:0:i}${NAME:i+1:1}${NAME:i:1}${NAME:i+2}"
  if type -P -- "$SWAP" >/dev/null; then
    echo "  did you mean $SWAP? ($(type -P -- "$SWAP"))"
    exit 1
  fi
done
echo "  not installed in any directory checked: check the spelling or install the package"
exit 1
