#!/usr/bin/env python
""" Script for building a standalone python package executable """
from __future__ import print_function
import argparse
import os
import tempfile
import sys
import shutil
import subprocess
from distutils.spawn import find_executable


VENV_VERSION = "16.0.0"
VENV_URL = (
    "https://pypi.python.org/packages/source/v/"
    "virtualenv/virtualenv-%s.tar.gz" % VENV_VERSION
)


def make_virtualenv(env):
    """ Create a virtualenv """
    if sys.version_info.major == 2:
        from urllib import urlretrieve

        if find_executable("virtualenv") is not None:
            cmd = ["virtualenv"] + [env]
            subprocess.check_call(cmd)
        else:
            # Otherwise, download virtualenv from pypi
            path = urlretrieve(VENV_URL)[0]
            subprocess.check_call(["tar", "xzf", path])
            subprocess.check_call(
                [sys.executable, "virtualenv-%s/virtualenv.py" % VENV_VERSION, env]
            )
            os.unlink(path)
            shutil.rmtree("virtualenv-%s" % VENV_VERSION)
    else:
        import venv

        venv.create(env, with_pip=True)


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
        make_virtualenv(venv_dir)

        print("Downloading dependencies")
        pip = os.path.join(venv_dir, "bin", "pip")
        subprocess.check_call([pip, "install", "pex"])
        subprocess.check_call([pip, "install", "wheel"])
        subprocess.check_call([pip, "install", args.package])

        print("Building executable")
        python = os.path.join(venv_dir, "bin", "python")
        entry = (
            subprocess.check_output(
                [
                    python,
                    "-c",
                    "import pkg_resources; e = pkg_resources.get_entry_info('%s', 'console_scripts', '%s'); print(e.module_name + ':' + '.'.join(e.attrs))"
                    % (args.package, args.script),
                ]
            )
            .strip()
            .decode('utf-8')
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
