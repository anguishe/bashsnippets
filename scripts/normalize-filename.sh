#!/bin/bash
# Script: normalize-filename.sh
# Purpose: Inconsistent filenames (spaces, mixed case, date suffixes) break downstream globbing and sorting.
# Usage: ./normalize-filename.sh "/path/to/My Report_20240310.TXT"
set -euo pipefail

CHECK="✓"
CROSS="✗"

raw="${1:?Usage: normalize-filename.sh <path>}"

# 1. Strip the directory: longest */ prefix → basename only.
name="${raw##*/}"

# A name with no dot would make stem and ext identical below; reject it early.
if [[ "$name" != *.* ]]; then
  echo "$CROSS no file extension in: $name" >&2
  exit 1
fi

# 2. Lowercase the whole thing (bash 4+).
name="${name,,}"

# 3. Replace every space with an underscore so globbing/sorting behave.
name="${name// /_}"

# 4. Split extension off, normalize the stem, then reattach.
ext="${name##*.}"      # text after the last dot
stem="${name%.*}"      # everything before the last dot

# 5. Drop a trailing _YYYYMMDD (8 digits) date suffix if present.
#    %_* removes the shortest _<anything> suffix; guard so we only strip real dates.
if [[ "$stem" =~ _[0-9]{8}$ ]]; then
  stem="${stem%_*}"
fi

normalized="${stem}.${ext}"
echo "$CHECK ${raw} → ${normalized}"
