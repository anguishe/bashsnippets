#!/bin/bash
# Quick System Info Report
# Prints key stats at a glance.
# Alias to 'syscheck' in your .bashrc for fast access.
#
# USAGE: ./syscheck.sh
# REQUIRES: bash, hostname, uptime, free, df (pre-installed everywhere)

echo "=== Quick System Check ==="
echo "Host    : $(hostname)"
echo "Uptime  : $(uptime -p)"
echo "RAM     : $(free -h | awk '/Mem/{print $3"/"$2}')"
echo "Disk /  : $(df -h / | awk 'NR==2{print $3"/"$2}')"
echo "IP      : $(hostname -I | awk '{print $1}')"
echo "========================="
