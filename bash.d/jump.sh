#!/bin/bash
# vi:ft=python:syntax=python

""":"

if [ -n "$BASH_SOURCE" ]; then
    export _JUMP_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
    complete -C "$_JUMP_SCRIPT" j
    export PS1="$PS1"'$(j _record)'
fi
if [ -n "$COMP_LINE" ]; then
    # The script will be called directly to handle tab completion
    python "$_JUMP_SCRIPT" "$@"
    exit
fi
j() {
    if [ "${1:0:1}" == "_" ]; then
        python "$_JUMP_SCRIPT" "$@"
        return
    fi
    local target
    target="$(python "$_JUMP_SCRIPT" "$@")" || return
    if [ -z "$target" ]; then
        echo "No jump target found for $*"
    else
        cd "$target"
    fi
}

return

":"""

import argparse
import json
import logging
import logging.handlers
import os
import sqlite3
import sys
from typing import Any, Dict

logger = logging.getLogger('jump')
CONFIG_DIR = os.environ.get('XDG_CONFIG_HOME', '')
if not CONFIG_DIR:
    CONFIG_DIR = os.path.join(os.environ['HOME'], '.config')
CACHE_DIR = os.environ.get('XDG_CACHE_HOME', '')
if not CACHE_DIR:
    CACHE_DIR = os.path.join(os.environ['HOME'], '.cache')

CONFIG_FILE = os.path.join(CONFIG_DIR, 'jump.json')
DB_FILE = os.path.join(CACHE_DIR, 'jump.db')

class Config:
    def __init__(self, log_level: str = 'info', decay_every: int = 100, decay_factor: float = 0.5, min_threshold: int = 8, bookmarks: Dict[str, str] = None, **kwargs: Any):
        self.log_level = logging.getLevelName(log_level.upper())
        self.decay_every = decay_every
        self.decay_factor = decay_factor
        self.min_threshold = min_threshold
        self.bookmarks = bookmarks or {}
        self.extra_kwargs = kwargs

    @classmethod
    def load(cls) -> 'Config':
        if not os.path.exists(CONFIG_FILE):
            return cls()
        with open(CONFIG_FILE, 'r') as ifile:
            try:
                data = json.load(ifile)
            except json.JSONDecodeError:
                return cls()
        return cls(**data)


def create_table(con: sqlite3.Connection) -> None:
    with con:
        cur = con.cursor()
        cur.execute('CREATE TABLE IF NOT EXISTS jumps (path TEXT PRIMARY KEY, dir TEXT, count INT)')
        cur.execute('CREATE TABLE IF NOT EXISTS meta_int (key TEXT PRIMARY KEY, value INT)')

def completion(con: sqlite3.Connection, config: Config):
    line = os.environ['COMP_LINE']
    point = int(os.environ['COMP_POINT'])
    pieces = line[0:point].split()
    if len(pieces) == 1:
        word = ''
    else:
        word = pieces[-1]
    with con:
        cur = con.cursor()
        rows = cur.execute('SELECT dir FROM jumps WHERE dir LIKE ? AND count >= ?', [word + '%', config.min_threshold])
        shortcuts = {row[0] for row in rows}
        for key in config.bookmarks:
            if key.startswith(word):
                shortcuts.add(key)
        for name in sorted(shortcuts):
            print(name)


def _setup_logging(config: Config) -> None:
    logfile = os.path.join(CACHE_DIR, "jump.log")
    handler = logging.handlers.RotatingFileHandler(
        logfile, delay=True, backupCount=1, maxBytes=1024 * 1024
    )
    formatter = logging.Formatter("%(levelname)s %(asctime)s [%(name)s] %(message)s")
    handler.setFormatter(formatter)
    logging.root.addHandler(handler)
    logging.root.setLevel(config.log_level)

def bootstrap():
    config = Config.load()
    _setup_logging(config)
    for key in config.extra_kwargs:
        logger.warn("Unrecognized config key: %r", key)
    try:
        code = main(config)
    except:
        logger.exception("Error")
        sys.exit(1)
    else:
        sys.exit(code)

def main(config: Config) -> int:
    """Jump to frequently-accessed directories"""
    parser = argparse.ArgumentParser(description=main.__doc__, add_help=False)
    parser.add_argument('-h', '--help', action='store_true', help="Print this help and exit")
    parser.add_argument("path")
    if 'COMP_LINE' in os.environ:
        parser.add_argument('line', nargs='*')
    args = parser.parse_args()
    if args.help:
        parser.print_help(sys.stderr)
        return 1
    con = sqlite3.connect(DB_FILE)

    if 'COMP_LINE' in os.environ:
        completion(con, config)
        return 0

    create_table(con)
    if args.path == '_record':
        path = os.path.realpath(os.path.abspath(os.curdir))
        if path == os.environ['HOME'] or path == '/':
            return 0
        with con:
            cur = con.cursor()
            cur.execute("INSERT OR IGNORE INTO jumps VALUES (?, ?, 0)", [path, os.path.basename(path)])
            cur.execute("UPDATE jumps SET count = count + 1 WHERE path = ?", [path])
            cur.execute("INSERT OR IGNORE INTO meta_int VALUES ('counter', 0)")
            cur.execute("UPDATE meta_int SET value = value + 1 WHERE key = 'counter'")
            cur.execute("SELECT value FROM meta_int WHERE key = 'counter'")
            counter = cur.fetchone()[0]
            if counter >= config.decay_every:
                logger.info("Decaying location scores")
                cur.execute("UPDATE meta_int SET value = 0 WHERE key = 'counter'")
                cur.execute("UPDATE jumps SET count = CAST(count * ? AS INT)", [config.decay_factor])
                cur.execute("DELETE FROM jumps WHERE count = 0")
    elif args.path == '_debug':
        with con:
            cur = con.cursor()
            rows = cur.execute('SELECT path, dir, count FROM jumps')
            for row in rows:
                print(row[2], row[1], row[0])
    else:
        dest = config.bookmarks.get(args.path)
        if dest:
            print(dest)
            return 0
        with con:
            cur = con.cursor()
            rows = cur.execute('SELECT path, count FROM jumps WHERE dir = ? ORDER BY count DESC LIMIT 1', [args.path])
            rows = list(rows)
            if not rows:
                rows = cur.execute('SELECT path, count FROM jumps WHERE path LIKE ? ORDER BY count DESC LIMIT 1', ['%' + args.path + '%'])
                rows = list(rows)
            for row in rows:
                print(row[0])

    return 0
        


if __name__ == '__main__':
    bootstrap()
