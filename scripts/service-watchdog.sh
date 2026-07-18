#!/bin/bash

CHECK="✓"
CROSS="✗"

# --- Configuration ---
SERVICE="nginx"                              # Change to your service name
LOG_FILE="/var/log/service-watchdog.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
NOTIFY_EMAIL=""                              # Optional: you@example.com

# --- Check if service is running ---
if systemctl is-active --quiet "$SERVICE"; then
  echo "$CHECK [$DATE] $SERVICE is running"
else
  echo "$CROSS [$DATE] $SERVICE is NOT running — attempting restart..."
  echo "$CROSS [$DATE] $SERVICE DOWN — restarting" >> "$LOG_FILE"

  # --- Attempt restart ---
  if sudo systemctl start "$SERVICE"; then
    echo "$CHECK [$DATE] $SERVICE restarted successfully" | tee -a "$LOG_FILE"

    # --- Optional: send email notification ---
    if [ -n "$NOTIFY_EMAIL" ]; then
      echo "$SERVICE was down and has been restarted on $(hostname) at $DATE" \
        | mail -s "[RECOVERED] $SERVICE restarted" "$NOTIFY_EMAIL"
    fi
  else
    echo "$CROSS [$DATE] $SERVICE FAILED to restart — manual intervention needed" \
      | tee -a "$LOG_FILE"

    if [ -n "$NOTIFY_EMAIL" ]; then
      echo "$SERVICE failed to restart on $(hostname) at $DATE. Check: journalctl -u $SERVICE" \
        | mail -s "[CRITICAL] $SERVICE restart failed" "$NOTIFY_EMAIL"
    fi
  fi
fi
