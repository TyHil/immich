#!/bin/bash
set -e

# Paths
APP_PATH="/home/tyler-hill/immich-app"
UPLOAD_LOCATION="$APP_PATH/library"
DRIVE_PATH="/mnt/Backup"
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

## Check drive mount, trigger automount if configured
if ! mountpoint -q "$DRIVE_PATH"; then
    echo "Backup drive not mounted, aborting" >&2
    exit 1
fi

### Append to local Borg repository
#### Borg exits with 1 for warnings so remember but don't exit if that happens
set +e
borg create "$BACKUP_PATH/immich-borg::{now}" "$UPLOAD_LOCATION" --exclude "$UPLOAD_LOCATION"/thumbs/ --exclude "$UPLOAD_LOCATION"/encoded-video/
borg_status=$?
set -e
if [ "$borg_status" -ge 2 ]; then
  echo "Borg create failed with exit code $borg_status" >&2
  exit 1
elif [ "$borg_status" -eq 1 ]; then
  echo "Borg create completed with warnings" >&2
  KUMA_STATUS="down"
  KUMA_MSG="OK (borg warnings)"
else
  KUMA_STATUS="up"
  KUMA_MSG="OK"
fi
borg prune --keep-weekly=4 --keep-monthly=3 "$BACKUP_PATH"/immich-borg
borg compact "$BACKUP_PATH"/immich-borg

### Copy environment variables
cp "$IMMICH_ENV_FILE" "$BACKUP_PATH"

# Send heartbeat
if [ -n "$KUMA_PUSH_URL" ]; then
  curl -fsS "$KUMA_PUSH_URL?status=$(printf '%s' "${KUMA_STATUS:-up}" | jq -sRr @uri)&msg=$(printf '%s' "${KUMA_MSG:-OK}" | jq -sRr @uri)"
fi
