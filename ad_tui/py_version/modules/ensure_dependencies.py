# ad_tui/py_version/modules/ensure_dependencies.py
# Checks required packages are installed; prompts before installing any that are missing.

import subprocess
import sys

REQUIRED_PACKAGES = ["questionary"]

def run():
    missing = []
    for package in REQUIRED_PACKAGES:
        try:
            __import__(package)
        except ImportError:
            missing.append(package)

    if not missing:
        return

    print("Missing required package(s):")
    for package in missing:
        print(f"  - {package}")

    confirm = input("Install now? (y/n): ").strip().lower()
    if confirm != "y":
        print("Cannot continue without required packages. Exiting.")
        sys.exit(1)

    for package in missing:
        print(f"Installing {package}...")
        subprocess.run([sys.executable, "-m", "pip", "install", package], check=True)