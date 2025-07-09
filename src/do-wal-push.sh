#!/bin/sh

echo "=== WAL-G WAL PUSH START: $(date) ==="

WAL_DIR="/wal-archive"
FAILED_FILES=""

# === NTFY CONFIG ===
NTFY_ENABLED="${NTFY_ENABLED:-false}"
NTFY_TOPIC="${NTFY_TOPIC:-}"
NTFY_TITLE="${NTFY_TITLE:-WAL-G WAL Push}"
NTFY_NOTIFY_ON="${NTFY_NOTIFY_ON:-failure}" # success | failure | both
NTFY_USER="${NTFY_USER:-}"
NTFY_PASS="${NTFY_PASS:-}"
NTFY_AUTH_TOKEN="${NTFY_AUTH_TOKEN:-}"

# === Notification helper ===
ntfy_notify() {
  local TITLE="$1"
  local MESSAGE="$2"
  local TAGS="$3"

  AUTH_ARGS=""
  if [ -n "$NTFY_AUTH_TOKEN" ]; then
    AUTH_ARGS="-H Authorization: Bearer $NTFY_AUTH_TOKEN"
  elif [ -n "$NTFY_USER" ] && [ -n "$NTFY_PASS" ]; then
    AUTH_ARGS="--user $NTFY_USER:$NTFY_PASS"
  fi

  curl -s -X POST "$NTFY_TOPIC" \
    $AUTH_ARGS \
    -H "Title: $TITLE" \
    -H "Tags: $TAGS" \
    -d "$MESSAGE"
}

# === Error handler ===
notify_script_error() {
  if [ "$NTFY_ENABLED" = "true" ] && { [ "$NTFY_NOTIFY_ON" = "failure" ] || [ "$NTFY_NOTIFY_ON" = "both" ]; }; then
    ntfy_notify "❌ $NTFY_TITLE (Script Error)" "Script crashed unexpectedly at $(date)" "x,warning"
  fi
}
trap 'notify_script_error' ERR

# === Check WAL directory exists ===
if [ ! -d "$WAL_DIR" ]; then
  echo "❌ WAL directory not found: $WAL_DIR"
  if [ "$NTFY_ENABLED" = "true" ] && { [ "$NTFY_NOTIFY_ON" = "failure" ] || [ "$NTFY_NOTIFY_ON" = "both" ]; }; then
    ntfy_notify "❌ $NTFY_TITLE" "WAL directory not found at $(date)" "x,warning"
  fi
  exit 1
fi

# === Push WALs ===
find "$WAL_DIR" -maxdepth 1 -type f | while read -r file; do
  filename=$(basename "$file")
  echo "📤 Pushing $filename"

  if wal-g wal-push "$file"; then
    echo "✅ Success: $filename"
    rm -f "$file"
  else
    echo "❌ Failed to push: $filename — keeping for retry"
    FAILED_FILES="$FAILED_FILES\n$filename"
  fi
done

# === Remove trap after successful run ===
trap - ERR

# === Send notification ===
if [ "$NTFY_ENABLED" = "true" ]; then
  if [ -z "$FAILED_FILES" ]; then
    if [ "$NTFY_NOTIFY_ON" = "success" ] || [ "$NTFY_NOTIFY_ON" = "both" ]; then
      ntfy_notify "✅ $NTFY_TITLE" "All WAL files pushed successfully at $(date)" "white_check_mark,floppy_disk"
    fi
  else
    if [ "$NTFY_NOTIFY_ON" = "failure" ] || [ "$NTFY_NOTIFY_ON" = "both" ]; then
      ntfy_notify "❌ $NTFY_TITLE" "Some WAL files failed to push:\n$FAILED_FILES" "x,warning"
    fi
  fi
fi

echo "=== WAL-G WAL PUSH END: $(date) ==="
