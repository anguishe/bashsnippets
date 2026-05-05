#!/bin/bash
# ─────────────────────────────────────────────────────────────
# sysinfo.sh — Quick System Info Report
# Prints hostname, uptime, RAM usage, disk usage, and IP.
# Run this first thing after SSH-ing into any new server.
#
# Usage:    ./sysinfo.sh
# Author:   BashSnippets.xyz
# Full reference + explanation:
#           https://bashsnippets.xyz/snippets/quick-system-info-report.html
# ─────────────────────────────────────────────────────────────

echo "=============================="
echo " System Info — $(date)"
echo "=============================="
echo "Hostname  : $(hostname)"
echo "Uptime    : $(uptime -p)"
echo "RAM       : $(free -h | awk '/^Mem:/ {print $3 " used / " $2 " total"}')"
echo "Disk      : $(df -h / | awk 'NR==2 {print $3 " used / " $2 " total (" $5 ")"}')"
echo "IP        : $(hostname -I | awk '{print $1}')"
echo "=============================="
