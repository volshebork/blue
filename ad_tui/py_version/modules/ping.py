# ad_tui/py_version/modules/ping.py
# Pings a user-specified host.

import subprocess
import questionary

def run():
    target = questionary.text("Enter a hostname or IP to ping:").ask()
    if not target:
        return
    subprocess.run(["ping", target])