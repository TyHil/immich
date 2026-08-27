#!/bin/sh
set -eu

# Paths
UPLOAD_LOCATION="/home/tyler-hill/immich-app/library"
BACKUP_PATH="/run/media/tyler-hill/Backup/immich-backup"
ENV_FILE="/home/tyler-hill/immich-app/.env"

# Backup Immich database
docker exec -t immich_postgres pg_dumpall --clean --if-exists --username=postgres > "$UPLOAD_LOCATION"/database-backup/immich-database.sql

# Local

## Make sure the backup drive is actually mounted
if ! mountpoint -q /run/media/tyler-hill/Backup; then
    echo "Backup drive not mounted, aborting" >&2
    exit 1
else
    ### Append to local Borg repository
    borg create "$BACKUP_PATH/immich-borg::{now}" "$UPLOAD_LOCATION" --exclude "$UPLOAD_LOCATION"/thumbs/ --exclude "$UPLOAD_LOCATION"/encoded-video/
    borg prune --keep-weekly=4 --keep-monthly=3 "$BACKUP_PATH"/immich-borg
    borg compact "$BACKUP_PATH"/immich-borg

    ### Copy environment variables
    cp "$ENV_FILE" "$BACKUP_PATH"
fi
