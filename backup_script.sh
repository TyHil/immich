#!/bin/sh
set -eu

# Paths
UPLOAD_LOCATION="/home/tyler-hill/immich-app/library"
DRIVE_PATH="/run/media/tyler-hill/Backup"
BACKUP_PATH="$DRIVE_PATH/immich-backup"
ENV_FILE="/home/tyler-hill/immich-app/.env"

# Backup Immich database
docker exec -t immich_postgres pg_dumpall --clean --if-exists --username=postgres > "$UPLOAD_LOCATION"/database-backup/immich-database.sql

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
cp "$ENV_FILE" "$BACKUP_PATH"
