#!/usr/bin/env python
import argparse
import json
import logging
import logging.handlers
import os
import shutil
import subprocess
from collections import defaultdict
from dataclasses import dataclass
from enum import Enum

log = logging.getLogger(__name__)
COMPLETE_DIR = "/mnt/storage/complete"
ARCHIVE_DIR = "/mnt/storage/archive"
PENDING_DIR = "/mnt/storage/pending"

class TorrentActivity(Enum):
    STOPPED = 0 # Torrent is stopped
    CHECK_WAIT = 1 # Queued to check files
    CHECK = 2 # Checking files
    DOWNLOAD_WAIT = 3 # Queued to download
    DOWNLOAD = 4 # Downloading
    SEED_WAIT = 5 # Queued to seed
    SEED = 6 # Seeding

class TorrentStatus(Enum):
    UNFINISHED = 1
    COMPLETED = 2
    ARCHIVED = 3
    UNKNOWN = 4


@dataclass
class Torrent:
    error: int
    errorString: str
    eta: int
    id: int
    isFinished: bool
    leftUntilDone: int
    name: str
    peersGettingFromUs: int
    peersSendingToUs: int
    rateDownload: int
    rateUpload: int
    sizeWhenDone: int
    status: TorrentActivity
    uploadRatio: int

    @property
    def activity(self) -> TorrentActivity:
        return TorrentActivity(self.status)

    @property
    def complete_path(self) -> str:
        return os.path.join(COMPLETE_DIR, self.name)

    @property
    def archive_path(self) -> str:
        return os.path.join(ARCHIVE_DIR, self.name)

    @property
    def pending_path(self) -> str:
        return os.path.join(PENDING_DIR, self.name)

    @property
    def is_seeding(self) -> bool:
        return self.activity == TorrentActivity.SEED_WAIT or self.activity == TorrentActivity.SEED

    @property
    def file_status(self) -> TorrentStatus:
        if not self.is_seeding:
            return TorrentStatus.UNFINISHED
        elif os.path.exists(self.complete_path):
            return TorrentStatus.COMPLETED
        elif os.path.exists(self.archive_path):
            return TorrentStatus.ARCHIVED
        else:
            return TorrentStatus.UNKNOWN


def _setup_logging(args: argparse.Namespace) -> None:
    logfile = os.path.join(
        os.getenv("HOME") or "/home/stevearc", ".cache", "transmission-done-script.log"
    )
    handler = logging.handlers.RotatingFileHandler(
        logfile, maxBytes=1024 * 1000 * 4, backupCount=1
    )
    formatter = logging.Formatter("%(levelname)s %(asctime)s [%(name)s] %(message)s")
    handler.setFormatter(formatter)
    logging.root.addHandler(handler)
    level = logging.getLevelName(args.log_level)
    logging.root.setLevel(level)


def run():
    os.makedirs(COMPLETE_DIR, exist_ok=True)
    os.makedirs(ARCHIVE_DIR, exist_ok=True)
    os.makedirs(PENDING_DIR, exist_ok=True)
    result = subprocess.run(["transmission-remote", "--json", "--list"], capture_output=True, check=True)
    data = json.loads(result.stdout)
    torrents = [Torrent(**status) for status in data["arguments"]["torrents"]]
    log.info("%d torrents found", len(torrents))
    sorted_torrents = defaultdict(list)
    for torrent in torrents:
        sorted_torrents[torrent.file_status].append(torrent)
    log.info(
        "%d unfinished, %d completed, %d archived, %d unknown",
        len(sorted_torrents[TorrentStatus.UNFINISHED]),
        len(sorted_torrents[TorrentStatus.COMPLETED]),
        len(sorted_torrents[TorrentStatus.ARCHIVED]),
        len(sorted_torrents[TorrentStatus.UNKNOWN]),
    )
    for torrent in sorted_torrents[TorrentStatus.UNKNOWN]:
        log.info("Moving unknown torrent %d %s to completed", torrent.id, torrent.name)
        subprocess.run(['transmission-remote', '-t', str(torrent.id), '--move', COMPLETE_DIR], check=True)
    for torrent in sorted_torrents[TorrentStatus.COMPLETED]:
        log.info("Hard copying torrent %s", torrent.name)
        if os.path.isfile(torrent.complete_path):
            os.link(torrent.complete_path, torrent.pending_path)
        else:
            shutil.copytree(torrent.complete_path, torrent.pending_path, copy_function=os.link)
        log.info("Moving torrent %d %s to archive", torrent.id, torrent.name)
        subprocess.run(['transmission-remote', '-t', str(torrent.id), '--move', ARCHIVE_DIR], check=True)


def main() -> None:
    """Main method"""
    parser = argparse.ArgumentParser(description=main.__doc__)

    parser.add_argument(
        "--log-level",
        type=lambda l: logging.getLevelName(l.upper()),
        default=logging.INFO,
        help="Stdout logging level (default 'info')",
    )
    args = parser.parse_args()
    _setup_logging(args)
    log.info("Starting script")
    try:
        run()
    except Exception:
        log.exception("Error in script")
    log.info("Script complete")


if __name__ == "__main__":
    main()
