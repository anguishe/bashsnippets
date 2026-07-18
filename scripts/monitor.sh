#!/bin/bash

CHECK="✓"
CROSS="✗"

# --- Configuration ---
THRESHOLD=80                    # Alert when usage exceeds this %
LOG_FILE="/var/log/resource-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# --- CPU Usage ---
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d',' -f1 | xargs printf "%.0f")

# --- RAM Usage ---
RAM=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')

echo "[$DATE] CPU: ${CPU}% | RAM: ${RAM}%"

# --- CPU Alert ---
if [ "$CPU" -gt "$THRESHOLD" ]; then
  echo "$CROSS [$DATE] WARNING: CPU at ${CPU}% (threshold: ${THRESHOLD}%)" | tee -a "$LOG_FILE"
else
  echo "$CHECK CPU OK: ${CPU}%"
fi

# --- RAM Alert ---
if [ "$RAM" -gt "$THRESHOLD" ]; then
  echo "$CROSS [$DATE] WARNING: RAM at ${RAM}% (threshold: ${THRESHOLD}%)" | tee -a "$LOG_FILE"
else
  echo "$CHECK RAM OK: ${RAM}%"
fi
