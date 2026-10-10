#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/rust-coreutils-ubuntu
# Script: which-coreutils.sh
# Purpose: After an upgrade to Ubuntu 26.04 ls, sort, date and timeout are Rust (uutils) while cp, mv and rm may still be GNU, and nothing tells you which one a script just ran; this lists it per command.
# Usage: ./which-coreutils.sh [COMMAND ...]   (default: every command coreutils ships)
set -euo pipefail

CHECK="✓"
CROSS="✗"

COREUTILS=(arch b2sum base32 base64 basename basenc cat chcon chgrp chmod chown chroot cksum comm cp csplit cut
  date dd df dir dircolors dirname du echo env expand expr factor false fmt fold groups head hostid id install
  join link ln logname ls md5sum mkdir mkfifo mknod mktemp mv nice nl nohup nproc numfmt od paste pathchk pinky
  pr printenv printf ptx pwd readlink realpath rm rmdir runcon seq sha1sum sha224sum sha256sum sha384sum sha512sum
  shred shuf sleep sort split stat stdbuf stty sum sync tac tail tee test timeout touch tr true truncate tsort
  tty uname unexpand uniq unlink users vdir wc who whoami yes)
CMDS=("$@")
[[ $# -gt 0 ]] || CMDS=("${COREUTILS[@]}")

declare -A BY_IMPL=()
for cmd in "${CMDS[@]}"; do
  # type -P skips aliases and builtins: echo, printf, test and pwd are bash builtins, and scripts that call
  # them by name never reach the binary at all, so what matters is the file on disk.
  bin=$(type -P "$cmd" || true)
  if [[ -z "$bin" ]]; then BY_IMPL["missing"]+=" $cmd"; continue; fi
  real=$(readlink -f "$bin")
  case "$real" in
    */cargo/bin/coreutils/*|*/coreutils/uutils*) impl="uutils (Rust)" ;;
    */busybox) impl="busybox" ;;
    */gnu"$cmd") impl="GNU" ;;
    *)
      # Elsewhere ask the binary itself; GNU test ignores --version, so ask its twin [ instead.
      probe=$real
      [[ "$cmd" == test && -x "${real%/*}/[" ]] && probe="${real%/*}/["
      ver=$(timeout 2 "$probe" --version 2>/dev/null | head -1 || true)
      case "$ver" in
        *uutils*) impl="uutils (Rust)" ;;
        *GNU*|*"(coreutils)"*) impl="GNU" ;;   # Debian's dd says "dd (coreutils) 9.7", without GNU
        *) impl="other" ;;
      esac ;;
  esac
  BY_IMPL["$impl"]+=" $cmd"
done

for impl in "uutils (Rust)" "GNU" "busybox" "other" "missing"; do
  [[ -n "${BY_IMPL[$impl]:-}" ]] || continue
  read -ra list <<< "${BY_IMPL[$impl]}"
  printf '%s %-14s %3d: %s\n' "$([[ $impl == missing ]] && echo "$CROSS" || echo "$CHECK")" "$impl" "${#list[@]}" "${list[*]}" | fold -s -w 110
done

for probe in ls cp; do
  if bin=$(type -P "$probe"); then echo "  $probe --version: $("$bin" --version 2>/dev/null | head -1)"; fi
done

# The switch is a package choice, not per command: coreutils-from-uutils and coreutils-from-gnu conflict.
if command -v dpkg-query >/dev/null; then
  echo "  packages:"
  dpkg-query -W -f='    ${db:Status-Abbrev} ${Package} ${Version}\n' \
    coreutils coreutils-from-uutils coreutils-from-gnu rust-coreutils gnu-coreutils 2>/dev/null | grep '^    ii' || true
  if dpkg-query -W -f='${db:Status-Abbrev}' coreutils-from-uutils 2>/dev/null | grep -q '^ii'; then
    echo "  back to GNU: sudo apt install coreutils-from-gnu coreutils-from-uutils- --allow-remove-essential"
  elif dpkg-query -W -f='${db:Status-Abbrev}' coreutils-from-gnu 2>/dev/null | grep -q '^ii'; then
    echo "  back to uutils: sudo apt install coreutils-from-uutils coreutils-from-gnu- --allow-remove-essential"
  fi
fi
if [[ -x /usr/bin/gnuls ]]; then
  echo "  GNU copies stay installed as gnu<name> (gnuls, gnusort, gnudate...) for one-off comparisons"
fi
