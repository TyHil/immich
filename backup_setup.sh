#!/bin/sh
set -eu

# Paths
## Immich
APP_PATH="/home/tyler-hill/immich-app"
UPLOAD_LOCATION="$APP_PATH/library"

## Local backup
DRIVE_PATH="/mnt/Backup"
BACKUP_PATH="$DRIVE_PATH/immich-backup"

## Remote backup
REMOTE_HOST="tyler-hill@tyler-hill-mimi-laptop.reedfish-triceratops.ts.net"
REMOTE_BACKUP_PATH="/home/tyler-hill/immich-backup"

# Make Immich database backup folder
mkdir "$UPLOAD_LOCATION/database-backup"

# Local backup
## Check drive mount, trigger automount if configured
if ! mountpoint -q "$DRIVE_PATH"; then
    echo "Backup drive not mounted, aborting" >&2
    exit 1
fi

## Create a local Borg repository
borg init --encryption=none "$BACKUP_PATH/immich-borg"

# Remote backup
borg init --encryption=none "$REMOTE_HOST:$REMOTE_BACKUP_PATH/immich-borg"

