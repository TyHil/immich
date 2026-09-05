#!/bin/bash
set -e

# Paths
APP_PATH="/home/tyler-hill/immich-app"
UPLOAD_LOCATION="$APP_PATH/library"
DRIVE_PATH="/run/media/tyler-hill/Backup"
BACKUP_PATH="$DRIVE_PATH/immich-backup"
IMMICH_ENV_FILE="$APP_PATH/.env"
ENV_FILE="$APP_PATH/.env.backup"

# Load environment variables if file exists
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
fi

# Backup Immich database
docker exec immich_postgres pg_dumpall --clean --if-exists --username=postgres > "$UPLOAD_LOCATION"/database-backup/immich-database.sql

# Local

## Check and mount drive
if ! mountpoint -q /run/media/tyler-hill/Backup; then
    echo "Backup drive not mounted, attempting to mount..." >&2
    mount /run/media/tyler-hill/Backup || true
fi

## Verify drive access
if ! mountpoint -q /run/media/tyler-hill/Backup; then
    echo "Backup drive failed to mount, aborting" >&2
    exit 1
fi

### Append to local Borg repository
borg create "$BACKUP_PATH/immich-borg::{now}" "$UPLOAD_LOCATION" --exclude "$UPLOAD_LOCATION"/thumbs/ --exclude "$UPLOAD_LOCATION"/encoded-video/
borg prune --keep-weekly=4 --keep-monthly=3 "$BACKUP_PATH"/immich-borg
borg compact "$BACKUP_PATH"/immich-borg

### Copy environment variables
cp "$IMMICH_ENV_FILE" "$BACKUP_PATH"

# Send heartbeat
if [ -n "$KUMA_PUSH_URL" ]; then
  curl -fsS "$KUMA_PUSH_URL?status=up&msg=OK"
fi
