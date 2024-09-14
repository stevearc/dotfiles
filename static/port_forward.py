#! /usr/bin/env python3
import json
import logging as log
import os
import re
import subprocess
import time
from typing import Optional

torrent_port_label = "ProtonVPN torrent"
gateway = "10.2.0.1"
home = os.getenv("HOME") or "/home/stevearc"
settings_file = os.path.join(home, ".config", "transmission-daemon", "settings.json")


def find_previous_port() -> Optional[int]:
    if not os.path.exists(settings_file):
        return
    with open(settings_file, "r") as ifile:
        settings = json.load(ifile)
        return settings.get("peer-port")


def refresh_protonvpn_forwarded_port() -> int:
    port = None
    for protocol in ["tcp", "udp"]:
        log.info(f"Running natpmpc to forward {protocol} port")
        command = ["natpmpc", "-g", gateway, "-a", "0", "0", protocol, "60"]
        result = subprocess.run(command, capture_output=True)
        stdout = result.stdout.decode()
        stderr = result.stderr.decode()
        if result.returncode != 0:
            raise RuntimeError("natpmpc error:\n" + stdout + "\n" + stderr)
        line = stdout.splitlines()[-3]
        match = re.match(r"^Mapped public port (\d+) protocol", line)
        assert match, "natpmpc output could not be parsed:\n" + stdout
        port = match.group(1)
        port = int(port)
        log.info(f"Forwarded ProtonVPN {protocol} port: {port}")
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


def main():
    log.basicConfig(
        filename=os.path.join(home, ".local", "state", "port_forward.log"),
        filemode="a",
        format="%(asctime)s - %(message)s",
        level=log.INFO,
    )

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
