[![Build Docker Image](https://github.com/Umami-Creative-GmbH/wal-g-ntfy-env/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Umami-Creative-GmbH/wal-g-ntfy-env/actions/workflows/docker-publish.yml)

# WAL-G with NTFY Support and Env Options

A Docker container for [WAL-G](https://github.com/wal-g/wal-g) with [ntfy](https://ntfy.sh/) notification support and flexible configuration via environment variables. Based on [apecloud/wal-g](https://github.com/apecloud/wal-g).

## Features

- Automated PostgreSQL backup and restore with WAL-G
- ntfy notifications for backup success/failure
- Highly configurable via environment variables
- Supports S3 and SSH backup targets
- Example `docker-compose.yml` for easy orchestration

## Quick Start

1. Copy `.env.template` to `.env` and edit your configuration:
   ```sh
   cp .env.template .env
   # Edit .env with your preferred values
   ```
2. Build and run the container:
   ```sh
   docker build -t wal-g-ntfy-env .
   docker run --env-file .env wal-g-ntfy-env
   ```
3. Or use the provided `docker-compose.yml` for easier setup:
   ```sh
   docker compose up
   ```

## Scheduling Backups

To automate backups, set up a cronjob on your host system. Example entries:

```cron
# Basebackups (daily at 2:00 AM)
0 2 * * * docker compose exec -T wal-g do-backup.sh
# WAL Files Push (every 15 minutes)
*/15 * * * * docker compose exec -T wal-g push-wal-queue.sh
```

## Environment Variables

All configuration is done via environment variables. See [.env.template](./.env.template) for full details. Key variables include:

### General

- `USER` - Default user (default: `root`)
- `WAL_USER` - PostgreSQL WAL user (default: `postgres`)
- `WAL_GROUP` - PostgreSQL WAL group (default: `postgres`)
- `WALG_COMPRESSION_METHOD` - Compression method (`lz4`, `zstd`, `brotli`)
- `WALG_RETAIN_DAYS` - Days to retain backups
- `WALG_RETAIN_COUNT` - Number of backups to retain

### S3 Target

- `AWS_ACCESS_KEY_ID` - AWS access key ID
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key
- `AWS_REGION` - AWS region
- `AWS_ENDPOINT` - AWS endpoint (optional, e.g. for MinIO)
- `WALG_S3_PREFIX` - S3 bucket and path (e.g. `s3://your-bucket-name/path/to/backups/`)

### SSH Target

- `SSH_PORT` - SSH port (default: `22`)
- `SSH_USERNAME` - SSH username
- `SSH_PASSWORD` - SSH password
- `WALG_SSH_PREFIX` - SSH backup target (e.g. `ssh://$SSH_USERNAME:$SSH_PASSWORD@$SSH_HOST:$SSH_PORT/backup`)

### PostgreSQL

- `PGUSER` - PostgreSQL user (default: `postgres`)
- `PGPASSWORD` - PostgreSQL password
- `PGHOST` - PostgreSQL host (default: `localhost`)
- `PGPORT` - PostgreSQL port (default: `5432`)
- `PGDATABASE` - PostgreSQL database name

### ntfy Notifications

- `NTFY_ENABLED` - Enable ntfy notifications (`true`/`false`)
- `NTFY_TOPIC` - ntfy topic URL (e.g. `https://ntfy.sh/your-topic-name`)
- `NTFY_NOTIFY_ON` - When to notify (`success`, `failure`, `both`)
- `NTFY_TITLE` - Notification title
- `NTFY_USER` - ntfy username (optional)
- `NTFY_PASS` - ntfy password (optional)
- `NTFY_AUTH_TOKEN` - ntfy auth token (optional)

## License

See [LICENSE](./LICENSE).
