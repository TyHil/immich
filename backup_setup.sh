#!/bin/sh
set -eu

# Paths
UPLOAD_LOCATION="/home/tyler-hill/immich-app/library"
BACKUP_PATH="/run/media/tyler-hill/Backup/immich-backup"

# Make Immich database backup folder
mkdir "$UPLOAD_LOCATION/database-backup"

# Local

## Make sure the backup drive is actually mounted
if ! mountpoint -q /run/media/tyler-hill/Backup; then
    echo "Backup drive not mounted, aborting" >&2
    exit 1
else
    ### Create a local Borg repository
    borg init --encryption=none "$BACKUP_PATH/immich-borg"
fi

