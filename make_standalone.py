#!/usr/bin/env python
""" Script for building a standalone python package executable """
import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import venv
from distutils.spawn import find_executable


def main():
    """ Build a standalone executable """
    parser = argparse.ArgumentParser(description=main.__doc__)
    parser.add_argument(
        "package", help="The name of the package containing the executable"
    )
    parser.add_argument(
        "-s",
        "--script",
        help="The console script to use as the entry point (defaults to name of package)",
    )
    parser.add_argument(
        "args", nargs=argparse.REMAINDER, help="These args will be passed to pex"
    )
    args = parser.parse_args()
    if not args.script:
        args.script = args.package

    venv_dir = tempfile.mkdtemp()
    try:
        venv.create(venv_dir, with_pip=True)

        print("Downloading dependencies")
        pip = os.path.join(venv_dir, "bin", "pip")
        subprocess.check_call([pip, "install", "pex", "wheel"])
        subprocess.check_call([pip, "install", args.package])

        print("Building executable")
        entry = (
            subprocess.check_output(
                [
                    os.path.join(venv_dir, "bin", "python"),
                    "-c",
                    "import pkg_resources; e = pkg_resources.get_entry_info('%s', 'console_scripts', '%s'); print(e.module_name + ':' + '.'.join(e.attrs))"
                    % (args.package, args.script),
                ]
            )
            .strip()
            .decode("utf-8")
        )
        pex = os.path.join(venv_dir, "bin", "pex")
        cmd = [pex, args.package, "-m", entry, "-o", args.script] + args.args
        print(" ".join(cmd))
        subprocess.check_call(cmd)

        print("executable written to %s" % os.path.abspath(args.script))
    finally:
        shutil.rmtree(venv_dir)


if __name__ == "__main__":
    main()
