#!/bin/sh

echo "=== ntfy PUSH TEST START ==="

# === NTFY CONFIG ===
NTFY_TOPIC="${NTFY_TOPIC:-}"
NTFY_TITLE="${NTFY_TITLE:-NTFY Push Test}"
NTFY_USER="${NTFY_USER:-}"
NTFY_PASS="${NTFY_PASS:-}"
NTFY_AUTH_TOKEN="${NTFY_AUTH_TOKEN:-}"

# === Notification helper ===
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

# === Send notification ===
ntfy_notify "✅ $NTFY_TITLE" "Push test successful at $(date)" "check,success"

echo "=== ntfy PUSH TEST END ==="
