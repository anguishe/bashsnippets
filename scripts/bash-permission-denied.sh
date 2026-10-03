#!/bin/bash
# Script: why-permission-denied.sh
# Purpose: "Permission denied" comes from at least five different checks and chmod +x fixes only one — this names the one blocking you.
# Usage: ./why-permission-denied.sh FILE [exec|read|write]   (default: exec)
set -euo pipefail

CHECK="✓"
CROSS="✗"

[[ $# -ge 1 && $# -le 2 ]] || { echo "usage: $0 FILE [exec|read|write]" >&2; exit 2; }
TARGET="$1"
MODE="${2:-exec}"
PROBLEMS=0

fail() { echo "$CROSS $*"; PROBLEMS=$((PROBLEMS + 1)); }

# 1. Every parent directory needs the x (search) bit for you, or nothing inside it is reachable, whatever the file's own mode says.
ABS=$(realpath -m -- "$TARGET")
DIR="/"
IFS='/' read -ra PARTS <<< "${ABS#/}"
for part in "${PARTS[@]:0:${#PARTS[@]}-1}"; do
  DIR="${DIR%/}/$part"
  if [[ -d "$DIR" && ! -x "$DIR" ]]; then
    fail "directory $DIR has no search (x) permission for you: $(stat -c '%A %U:%G' -- "$DIR")"
  fi
done

if [[ ! -e "$TARGET" ]]; then
  # Creating a file needs write+search on the directory, not on a file that doesn't exist yet.
  PARENT=$(dirname -- "$ABS")
  if [[ "$MODE" == "write" && -d "$PARENT" && ! ( -w "$PARENT" && -x "$PARENT" ) ]]; then
    fail "cannot create files in $PARENT: $(stat -c '%A %U:%G' -- "$PARENT")"
  fi
  (( PROBLEMS )) || echo "$CROSS $TARGET does not exist (that is \"No such file\", not a permission problem)"
  exit 1
fi

# Which of the three permission triplets applies depends on owner and group membership, so say which one you fall into.
FILE_GROUP=$(stat -c %G -- "$TARGET")
if [[ " $(id -Gn) " == *" $FILE_GROUP "* ]]; then IN_GROUP="in"; else IN_GROUP="not in"; fi
echo "  $TARGET: $(stat -c '%A owner=%U group=%G' -- "$TARGET"); you are $(id -un), $IN_GROUP group $FILE_GROUP"

# An ACL adds rules the mode bits above don't show; getfacl -s prints only files that have one.
if command -v getfacl >/dev/null && [[ -n "$(getfacl -s -p -- "$TARGET" 2>/dev/null)" ]]; then
  echo "  ACL present: getfacl $TARGET shows rules beyond the mode bits"
fi

case "$MODE" in
  exec)
    # noexec on the mount beats every mode bit, including root's, and makes [[ -x ]] false too, so check it first.
    OPTS=$(findmnt -no OPTIONS --target "$TARGET" 2>/dev/null || true)
    if [[ ",$OPTS," == *",noexec,"* ]]; then
      fail "filesystem is mounted noexec ($(findmnt -no TARGET --target "$TARGET")): run bash $TARGET, or move it to a mount without noexec"
    elif [[ ! -x "$TARGET" ]]; then
      fail "no execute permission for you: chmod +x $TARGET (if you own it) or run it as bash $TARGET"
    fi
    # A shebang interpreter that exists but isn't executable also surfaces as Permission denied.
    if IFS= read -r FIRST < "$TARGET" 2>/dev/null && [[ "$FIRST" == '#!'* ]]; then
      INTERP=${FIRST#\#!}; INTERP=${INTERP%% *}
      if [[ -e "$INTERP" && ! -x "$INTERP" ]]; then fail "shebang interpreter $INTERP is not executable"; fi
    fi
    ;;
  read)  [[ -r "$TARGET" ]] || fail "no read permission for you: the owner ($(stat -c %U -- "$TARGET")) has to grant it, or use sudo if you are meant to have access" ;;
  write)
    [[ -w "$TARGET" ]] || fail "no write permission for you on the file"
    # The immutable attribute blocks writes even for root, and the error then says "Operation not permitted".
    if lsattr -d -- "$TARGET" 2>/dev/null | cut -d' ' -f1 | grep -q i; then
      fail "file is immutable (chattr +i): root must run chattr -i $TARGET first"
    fi
    ;;
  *) echo "unknown mode: $MODE (use exec, read or write)" >&2; exit 2 ;;
esac

if (( PROBLEMS == 0 )); then
  echo "$CHECK nothing blocks $MODE on $TARGET for $(id -un)"
  exit 0
fi
exit 1
