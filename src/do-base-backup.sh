#!/bin/sh

# === CONFIGURATION ===
LOG_DIR="/tmp/wal-logs"
LOG_FILE="$LOG_DIR/walg-backup.log"
ROTATE_TIMESTAMP=$(date +%F_%H-%M-%S)

# === NTFY CONFIG ===
NTFY_ENABLED="${NTFY_ENABLED:-false}"
NTFY_TOPIC="${NTFY_TOPIC:-}"
NTFY_NOTIFY_ON="${NTFY_NOTIFY_ON:-failure}"  # success | failure | both
NTFY_TITLE="${NTFY_TITLE:-TimescaleDB Backup}"
RETAIN_DAYS="${WALG_RETAIN_DAYS:-7}"
RETAIN_COUNT="${WALG_RETAIN_COUNT:-3}"

# Calculate timestamp N days ago
RETAIN_AFTER_DATE=$(date -u -d "${RETAIN_DAYS} days ago" +"%Y-%m-%dT%H:%M:%S")

# === PREPARE LOG DIR ===
mkdir -p "$LOG_DIR"

# === Error handler ===
notify_failure() {
  if [ "$NTFY_ENABLED" = "true" ] && { [ "$NTFY_NOTIFY_ON" = "failure" ] || [ "$NTFY_NOTIFY_ON" = "both" ]; }; then
    ntfy_notify "❌ $NTFY_BACKUP_NAME (Script Error)" "Backup script failed unexpectedly at $(date)." "x,warning"
  fi
}
trap 'notify_failure' ERR

ntfy_notify() {
  local TITLE="$1"
  local MESSAGE="$2"
  local TAGS="$3"

  if [ -n "$NTFY_AUTH_TOKEN" ]; then
    curl -s -X POST "$NTFY_TOPIC" \
      -H "Authorization: Bearer $NTFY_AUTH_TOKEN" \
      -H "Title: $TITLE" \
      -H "Tags: $TAGS" \
      -d "$MESSAGE"
  elif [ -n "$NTFY_USER" ] && [ -n "$NTFY_PASS" ]; then
    curl -s -X POST "$NTFY_TOPIC" \
      --user "$NTFY_USER:$NTFY_PASS" \
      -H "Title: $TITLE" \
      -H "Tags: $TAGS" \
      -d "$MESSAGE"
  else
    curl -s -X POST "$NTFY_TOPIC" \
      -H "Title: $TITLE" \
      -H "Tags: $TAGS" \
      -d "$MESSAGE"
  fi
}

# === DELETE LOG FILES OLDER THAN 7 DAYS ===
find "$LOG_DIR" -type f -name "walg-backup.log.*" -mtime +7 -delete

# === ROTATE OLD LOG ===
if [ -f "$LOG_FILE" ]; then
  mv "$LOG_FILE" "$LOG_FILE.$ROTATE_TIMESTAMP"
fi

# === START BACKUP AND LOG TO CONSOLE + FILE ===
{
  echo "=== WAL-G BACKUP START: $(date) ==="

  if wal-g backup-push /var/lib/postgresql/data; then
    echo "✅ Backup successful"
    echo "🧹 Cleaning up backups: keeping last $RETAIN_COUNT and all newer than $RETAIN_AFTER_DATE"
    # fallback: try retain with --after, if it crashes, fall back to just retain N
    if ! wal-g delete retain "$RETAIN_COUNT" --after "$RETAIN_AFTER_DATE" --confirm 2>/dev/null; then
      echo "⚠️  Retain with --after failed, falling back to retain $RETAIN_COUNT only"
      wal-g delete retain "$RETAIN_COUNT" --confirm
    fi

    if [ "$NTFY_ENABLED" = "true" ] && { [ "$NTFY_NOTIFY_ON" = "success" ] || [ "$NTFY_NOTIFY_ON" = "both" ]; }; then
      ntfy_notify "✅ $NTFY_BACKUP_NAME" "Backup completed successfully at $(date)." "white_check_mark,floppy_disk"
    fi
  else
    echo "❌ Backup failed — skipping cleanup."

    if [ "$NTFY_ENABLED" = "true" ] && { [ "$NTFY_NOTIFY_ON" = "failure" ] || [ "$NTFY_NOTIFY_ON" = "both" ]; }; then
      ntfy_notify "❌ $NTFY_BACKUP_NAME" "Backup failed at $(date)." "x,warning"
    fi

    exit 1
  fi

  echo "=== WAL-G BACKUP END: $(date) ==="
} 2>&1 | tee "$LOG_FILE"

# === Disable trap on success ===
trap - ERR
