#!/bin/bash
set -e

WAL_USER=${WAL_USER:-postgres}
WAL_GROUP=${WAL_GROUP:-postgres}

# Fix permissions in /wal-archive folder
if [ -d "/wal-archive" ]; then
  echo "Setting proper permissions on /wal-archive folder"
  chown -R $WAL_USER:$WAL_GROUP /wal-archive
  chmod -R 700 /wal-archive
  echo "Permissions updated successfully"
else
  echo "Warning: /wal-archive folder does not exist"
fi

chown -R $WAL_USER:$WAL_GROUP /app

# Execute the command passed to docker run
exec "$@"
