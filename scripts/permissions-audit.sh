#!/bin/bash
# permissions-audit.sh — BashSnippets.xyz
# Audit and report dangerous file permissions

set -euo pipefail

CHECK="✓"
CROSS="✗"

SCAN_DIR="${1:-/var/www}"
DANGEROUS_PERMS="777"
REPORT_FILE="/tmp/perms-audit-$(date +%Y%m%d).txt"

echo "Scanning: $SCAN_DIR"
echo "Looking for world-writable files ($DANGEROUS_PERMS)..."
echo ""

FOUND=$(find "$SCAN_DIR" -perm "$DANGEROUS_PERMS" -type f 2>/dev/null)

if [ -z "$FOUND" ]; then
  echo "$CHECK No $DANGEROUS_PERMS files found in $SCAN_DIR"
else
  echo "$CROSS DANGER: World-writable files found:"
  echo "$FOUND"
  echo "$FOUND" > "$REPORT_FILE"
  echo ""
  echo "Report saved to: $REPORT_FILE"
fi

echo ""
echo "--- Recommended Permissions ---"
echo "Files:       chmod 644 (rw-r--r--)"
echo "Directories: chmod 755 (rwxr-xr-x)"
echo "Executables: chmod 755 (rwxr-xr-x)"
echo "SSH keys:    chmod 600 (rw-------)"
echo "Private dirs: chmod 700 (rwx------)"
