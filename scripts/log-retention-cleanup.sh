#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/log-retention-cleanup
# Script: log-retention-cleanup.sh
# Purpose: An app directory that logrotate does not own grows until the disk fills and every write on the box fails at once — this keeps the newest N dated entries, deletes the rest once they are older than D days, and refuses to run when the pattern matches nothing so a wrong path can neither wipe a tree nor skip one silently.
# Usage: ./log-retention-cleanup.sh <dir> [--pattern GLOB] [--keep N] [--days D] [--apply]
#   dry run (default): ./log-retention-cleanup.sh /var/backups/myapp --keep 7 --days 30
#   delete:            ./log-retention-cleanup.sh /var/backups/myapp --keep 7 --days 30 --apply
#   cron: 15 3 * * * /usr/local/sbin/log-retention-cleanup.sh /var/backups/myapp --keep 7 --days 30 --apply >> /var/log/log-retention.log 2>&1
set -euo pipefail
export LC_ALL=C                     # byte-order sort, whatever the locale

CHECK="✓"
CROSS="✗"

TARGET_DIR="${1:?usage: $0 <dir> [--pattern GLOB] [--keep N] [--days D] [--apply]}"
shift
PATTERN="*"                         # glob matched against names directly inside TARGET_DIR
KEEP=7                              # the newest N entries are never touched, however old
DAYS=30                             # everything else is a candidate once older than this
APPLY=0                             # 0 = print what would go; 1 = delete it
SECONDS_PER_DAY=86400

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pattern) PATTERN="$2"; shift 2 ;;
    --keep)    KEEP="$2";    shift 2 ;;
    --days)    DAYS="$2";    shift 2 ;;
    --apply)   APPLY=1;      shift ;;
    *) echo "$CROSS unknown option: $1" >&2; exit 2 ;;
  esac
done

[[ -d "$TARGET_DIR" ]] || { echo "$CROSS $TARGET_DIR is not a directory" >&2; exit 2; }
# rm -rf on a child of / is one typo away from rm -rf /var. Refuse the root entirely.
[[ "$(realpath "$TARGET_DIR")" == "/" ]] && { echo "$CROSS refusing to manage / itself" >&2; exit 2; }

# Newest first by modification time. -maxdepth 1 keeps this to direct children, so
# every path deleted below is one level under TARGET_DIR and nothing deeper is walked.
mapfile -d '' -t ENTRIES < <(
  find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -name "$PATTERN" -printf '%T@ %p\0' | sort -z -rn
)

# Zero matches is the dangerous case, not the safe one: it means the path or the
# pattern is wrong, and a cron job that "cleaned" nothing for a month is what fills the disk.
if [[ ${#ENTRIES[@]} -eq 0 ]]; then
  echo "$CROSS nothing in $TARGET_DIR matches '$PATTERN' — wrong path or pattern? Refusing to continue." >&2
  exit 1
fi

CUTOFF=$(( $(date +%s) - DAYS * SECONDS_PER_DAY ))
CANDIDATES=()
for (( i = KEEP; i < ${#ENTRIES[@]}; i++ )); do        # the first KEEP are protected by position
  mtime="${ENTRIES[i]%% *}"
  path="${ENTRIES[i]#* }"
  (( ${mtime%.*} < CUTOFF )) && CANDIDATES+=("$path")
done

echo "$CHECK ${#ENTRIES[@]} entries match '$PATTERN' in $TARGET_DIR — the newest $KEEP are kept regardless of age"

if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
  echo "$CHECK nothing beyond the newest $KEEP is older than $DAYS days; nothing to remove"
  exit 0
fi

MODE="DRY RUN — would remove"
(( APPLY )) && MODE="Removing"
echo "$MODE ${#CANDIDATES[@]} entries older than $DAYS days:"
for path in "${CANDIDATES[@]}"; do
  printf '  %s  %6s  %s\n' "$(date -r "$path" +%F)" "$(du -sh "$path" | cut -f1)" "$path"
done
echo "  $(du -shc "${CANDIDATES[@]}" | tail -1 | cut -f1) total"

if (( ! APPLY )); then
  echo "$CHECK dry run only — re-run with --apply to delete"
  exit 0
fi

for path in "${CANDIDATES[@]}"; do
  rm -rf -- "$path"
done
echo "$CHECK removed ${#CANDIDATES[@]} entries from $TARGET_DIR; ${#ENTRIES[@]} matched, $(( ${#ENTRIES[@]} - ${#CANDIDATES[@]} )) remain"
