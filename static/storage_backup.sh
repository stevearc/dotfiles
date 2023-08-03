#!/bin/bash
set -e
echo "START BACKUP"
if [ ! -e /mnt/storage/torrents_archive ] || [ ! -e /mnt/storage/Library ] || [ ! -e /mnt/storage/jellyfin ] || [ ! -e /mnt/storage/games ] || [ ! -e /mnt/storage/symbolic_archive ]; then
  echo "Cannot back up /mnt/storage; files missing"
  exit 1
fi
rclone sync -v /mnt/storage/torrents_archive s3:pibox-backups/torrents_archive/
rclone sync -v /mnt/storage/Library s3:pibox-backups/Library/
rclone sync -v /mnt/storage/pending s3:pibox-backups/pending/
rclone sync -v /mnt/storage/games s3:pibox-backups/games/
rclone sync -v /mnt/storage/symbolic_archive s3:pibox-backups/symbolic_archive --links
rclone sync -v /mnt/storage/jellyfin s3:pibox-backups/jellyfin/ --exclude "/data/**" --exclude "/cache/**"
