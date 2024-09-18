#!/usr/bin/env python3
import json
import logging
import logging.handlers
import os
import re
import subprocess
import time
from typing import Optional

log = logging.getLogger(__name__)
gateway = "10.2.0.1"
home = os.getenv("HOME") or "/home/stevearc"
settings_file = os.path.join(home, ".config", "transmission-daemon", "settings.json")


def find_previous_port() -> Optional[int]:
    if not os.path.exists(settings_file):
        return
    with open(settings_file, "r") as ifile:
        settings = json.load(ifile)
        return settings.get("peer-port")


port_pattern = re.compile(r"^Mapped public port (\d+) protocol", re.MULTILINE)


def refresh_protonvpn_forwarded_port() -> int:
    port = None
    for protocol in ["tcp", "udp"]:
        log.debug(f"Running natpmpc to forward {protocol} port")
        command = ["natpmpc", "-g", gateway, "-a", "1", "0", protocol, "60"]
        result = subprocess.run(command, capture_output=True)
        stdout = result.stdout.decode()
        stderr = result.stderr.decode()
        if result.returncode != 0:
            raise RuntimeError("natpmpc error:\n" + stdout + "\n" + stderr)
        match = port_pattern.search(stdout)
        assert match, "natpmpc output could not be parsed:\n" + stdout
        port = int(match.group(1))
        log.debug(f"Forwarded ProtonVPN {protocol} port: {port}")
    assert port
    return port


def update_transmission_port(port: int):
    command = ["transmission-remote", "--port", str(port), "--no-portmap"]
    subprocess.run(command, check=True)
    log.info(f"Updated Transmission to listen on port {port}.")
    if not os.path.exists(settings_file):
        return
    with open(settings_file, "r") as ifile:
        settings = json.load(ifile)
        settings["peer-port"] = port
    with open(settings_file, "w") as ofile:
        json.dump(settings, ofile, indent=2)


def _setup_logging() -> None:
    logfile = os.path.join(
        os.getenv("HOME") or "/home/stevearc",
        ".local",
        "state",
        "transmission-done-script.log",
    )
    handler = logging.handlers.RotatingFileHandler(
        logfile, maxBytes=1024 * 1000 * 4, backupCount=1
    )
    formatter = logging.Formatter("%(levelname)s %(asctime)s [%(name)s] %(message)s")
    handler.setFormatter(formatter)
    logging.root.addHandler(handler)
    logging.root.setLevel(logging.INFO)


def main():
    _setup_logging()

    try:
        previous_port = find_previous_port()
        log.info(f"Found previous peer port: {previous_port}.")
        while True:
            current_port = refresh_protonvpn_forwarded_port()
            if previous_port != current_port:
                log.info(f"Updating peer port from {previous_port} to {current_port}")
                update_transmission_port(current_port)
                previous_port = current_port
            # lease is for 60 seconds, so refresh every 50
            time.sleep(50)
    except KeyboardInterrupt:
        pass
    except:
        log.error("Exception occurred.", exc_info=True)
        raise


if __name__ == "__main__":
    main()
