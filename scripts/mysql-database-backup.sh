#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/mysql-database-backup

CHECK="✓"
CROSS="✗"

# --- Configuration ---
DB_USER="root"
DB_PASS="your_password"          # Or use ~/.my.cnf for security
DB_NAME="your_database"          # Change to your DB name
BACKUP_DIR="/var/backups/mysql"
KEEP_DAYS=7                       # Delete backups older than this
DATE=$(date '+%Y-%m-%d_%H-%M-%S')
FILENAME="${DB_NAME}_${DATE}.sql.gz"

# --- Create backup directory if it doesn't exist ---
mkdir -p "$BACKUP_DIR"

# --- Run the backup ---
echo "Backing up database: $DB_NAME..."

if mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "${BACKUP_DIR}/${FILENAME}"; then
  echo "$CHECK Backup created: ${BACKUP_DIR}/${FILENAME}"
  echo "$CHECK Size: $(du -sh "${BACKUP_DIR}/${FILENAME}" | cut -f1)"
else
  echo "$CROSS Backup FAILED for $DB_NAME — check credentials and database name"
  exit 1
fi

# --- Delete old backups ---
echo "Removing backups older than $KEEP_DAYS days..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +"$KEEP_DAYS" -delete
echo "$CHECK Cleanup complete"

# --- Show current backups ---
echo "Current backups:"
ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "No backups found"
