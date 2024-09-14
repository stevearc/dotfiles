#!/bin/bash
set -e

cd /mnt/storage/torrents_archive/
for t in *.torrent; do
  transmission-remote -a "$t" --find /mnt/storage/archive
done
