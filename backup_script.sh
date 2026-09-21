#!/bin/bash
set -e

# Paths
## Immich
APP_PATH="/home/tyler-hill/immich-app"
UPLOAD_LOCATION="$APP_PATH/library"
IMMICH_ENV_FILE="$APP_PATH/.env"

## Script environment variables
ENV_FILE="$APP_PATH/.env.backup"

## Local backup
DRIVE_PATH="/mnt/Backup"
BACKUP_PATH="$DRIVE_PATH/immich-backup"

## Remote backup
REMOTE_HOST="tyler-hill@tyler-hill-mimi-laptop.reedfish-triceratops.ts.net"
REMOTE_BACKUP_PATH="/home/tyler-hill/immich-backup"

# Load script environment variables if file exists
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
fi

# Backup Immich database
docker exec immich_postgres pg_dumpall --clean --if-exists --username=postgres > "$UPLOAD_LOCATION"/database-backup/immich-database.sql

# Local backup
## Check drive mount, trigger automount if configured
if ! mountpoint -q "$DRIVE_PATH"; then
    echo "Local: Backup drive not mounted, aborting" >&2
    exit 1
fi

## Append to local Borg repository
### Borg exits with 1 for warnings so remember but don't exit if that happens
set +e
borg create "$BACKUP_PATH/immich-borg::{now}" "$UPLOAD_LOCATION" --exclude "$UPLOAD_LOCATION"/thumbs/ --exclude "$UPLOAD_LOCATION"/encoded-video/
borg_status_local=$?
set -e
if [ "$borg_status_local" -ge 2 ]; then
  echo "Local: Borg create failed with exit code $borg_status_local" >&2
  exit 1
elif [ "$borg_status_local" -eq 1 ]; then
  echo "Local: Borg create completed with warnings" >&2
  KUMA_STATUS_LOCAL="down"
  KUMA_MSG_LOCAL="OK (borg warnings)"
else
  KUMA_STATUS_LOCAL="up"
  KUMA_MSG_LOCAL="OK"
fi
borg prune --keep-weekly=4 --keep-monthly=3 "$BACKUP_PATH"/immich-borg
borg compact "$BACKUP_PATH"/immich-borg

## Copy Immich environment variables
cp "$IMMICH_ENV_FILE" "$BACKUP_PATH"

## Send heartbeat
if [ -n "$KUMA_PUSH_URL_LOCAL" ]; then
  curl -fsS "$KUMA_PUSH_URL_LOCAL?status=$(printf '%s' "${KUMA_STATUS_LOCAL:-up}" | jq -sRr @uri)&msg=$(printf '%s' "${KUMA_MSG_LOCAL:-OK}" | jq -sRr @uri)"
fi

# Remote backup
## Append to local Borg repository
### Borg exits with 1 for warnings so remember but don't exit if that happens
set +e
borg create "$REMOTE_HOST:$REMOTE_BACKUP_PATH/immich-borg::{now}" "$UPLOAD_LOCATION" --exclude "$UPLOAD_LOCATION"/thumbs/ --exclude "$UPLOAD_LOCATION"/encoded-video/
borg_status_remote=$?
set -e
if [ "$borg_status_remote" -ge 2 ]; then
  echo "Remote: Borg create failed with exit code $borg_status_remote" >&2
  exit 1
elif [ "$borg_status_remote" -eq 1 ]; then
  echo "Remote: Borg create completed with warnings" >&2
  KUMA_STATUS_REMOTE="down"
  KUMA_MSG_REMOTE="OK (borg warnings)"
else
  KUMA_STATUS_REMOTE="up"
  KUMA_MSG_REMOTE="OK"
fi
borg prune --keep-weekly=4 --keep-monthly=3 "$REMOTE_HOST:$REMOTE_BACKUP_PATH"/immich-borg
borg compact "$REMOTE_HOST:$REMOTE_BACKUP_PATH"/immich-borg

## Copy Immich environment variables
scp "$IMMICH_ENV_FILE" "$REMOTE_HOST:$REMOTE_BACKUP_PATH/"

## Send heartbeat
if [ -n "$KUMA_PUSH_URL_REMOTE" ]; then
  curl -fsS "$KUMA_PUSH_URL_REMOTE?status=$(printf '%s' "${KUMA_STATUS_REMOTE:-up}" | jq -sRr @uri)&msg=$(printf '%s' "${KUMA_MSG_REMOTE:-OK}" | jq -sRr @uri)"
fi

