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

# Python 2 & 3
try:
    from urllib import urlretrieve
except ImportError:
    from urllib.request import urlretrieve

VENV_VERSION = '15.0.1'
VENV_URL = ("https://pypi.python.org/packages/source/v/"
            "virtualenv/virtualenv-%s.tar.gz" % VENV_VERSION)


def make_virtualenv(env):
    """ Create a virtualenv """
    if find_executable('virtualenv') is not None:
        cmd = ['virtualenv'] + [env]
        subprocess.check_call(cmd)
    else:
        # Otherwise, download virtualenv from pypi
        path = urlretrieve(VENV_URL)[0]
        subprocess.check_call(['tar', 'xzf', path])
        subprocess.check_call(
            [sys.executable, "virtualenv-%s/virtualenv.py" % VENV_VERSION,
             env])
        os.unlink(path)
        shutil.rmtree("virtualenv-%s" % VENV_VERSION)


def main():
    """ Build a standalone executable """
    parser = argparse.ArgumentParser(description=main.__doc__)
    parser.add_argument('package', help="The name of the package containing the executable")
    parser.add_argument('script', nargs="?", help="The console script to use as the entry point (defaults to name of package)")
    args = parser.parse_args()
    if not args.script:
        args.script = args.package

    venv_dir = tempfile.mkdtemp()
    try:
        make_virtualenv(venv_dir)

        print("Downloading dependencies")
        pip = os.path.join(venv_dir, 'bin', 'pip')
        subprocess.check_call([pip, 'install', 'pex'])
        subprocess.check_call([pip, 'install', args.package])

        print("Building executable")
        python = os.path.join(venv_dir, 'bin', 'python')
        entry = subprocess.check_output([
            python,
            '-c',
            "import pkg_resources; e = pkg_resources.get_entry_info('%s', 'console_scripts', '%s'); print(e.module_name + ':' + '.'.join(e.attrs))"
            % (args.package, args.script)
        ])
        pex = os.path.join(venv_dir, 'bin', 'pex')
        subprocess.check_call([pex, args.package, '-m', entry, '-o', args.script])

        print("executable written to %s" % os.path.abspath(args.script))
    finally:
        shutil.rmtree(venv_dir)


if __name__ == '__main__':
    main()
