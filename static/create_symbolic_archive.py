#!/usr/bin/env python
import argparse
import os

ARCHIVE = "/mnt/storage/archive"
SYMBOLIC_ARCHIVE = "/mnt/storage/symbolic_archive"
LINK_ROOTS = ["/mnt/storage/plex", "/mnt/storage/audiobooks"]


def main() -> None:
    inodes = {}
    i = 0
    for link_root in LINK_ROOTS:
        for root, _dirs, files in os.walk(link_root):
            for file in files:
                fullpath = os.path.join(root, file)
                stat = os.stat(fullpath)
                inodes[stat.st_ino] = fullpath
                i += 1
                if i % 1000 == 0:
                    print(f"Reading file {i}")

    i = 0
    for root, _dirs, files in os.walk(ARCHIVE):
        rel_root = os.path.relpath(root, ARCHIVE)
        dest_root = os.path.normpath(os.path.join(SYMBOLIC_ARCHIVE, rel_root))
        os.makedirs(dest_root, exist_ok=True)
        for file in files:
            i += 1
            if i % 1000 == 0:
                print(f"Reading archive file {i}")
            src_path = os.path.join(root, file)
            dest_path = os.path.join(dest_root, file)
            stat = os.stat(src_path)
            link_path = inodes.get(stat.st_ino)
            if link_path is not None:
                symbolic_path = os.path.relpath(link_path, dest_root)
                if os.path.exists(dest_path):
                    if os.path.islink(dest_path):
                        existing_symbolic_path = os.readlink(dest_path)
                        if existing_symbolic_path == symbolic_path:
                            continue
                    os.unlink(dest_path)
                elif os.path.islink(dest_path):
                    # Remove broken symlink
                    os.unlink(dest_path)
                os.symlink(symbolic_path, dest_path)
            else:
                if os.path.islink(dest_path) and not os.path.exists(dest_path):
                    # Remove broken symlink
                    os.unlink(dest_path)

                if os.path.exists(dest_path):
                    dest_stat = os.stat(dest_path)
                    if stat.st_ino != dest_stat.st_ino:
                        raise Exception(
                            f'Attempting to create hard link "{dest_path}" -> "{src_path}", but it already points to another file'
                        )
                else:
                    os.link(src_path, dest_path)
    print("Done")


if __name__ == "__main__":
    main()
