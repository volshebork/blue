#!/usr/bin/env bash

# This script downloads the Blue toolkit files from GitHub (no .git history) into a directory you choose.

set -euo pipefail  # exit on error, unset var, or failed pipe

# print usage and exit if called with no/bad args
usage() {
    echo "Usage: $0 <destination>"
    echo "Example: $0 ~/main/blue"
    exit 1
}

[[ $# -ge 1 ]] || usage  # require at least 1 arg, else print usage and exit

# variables
destination="$1"
repo_url="https://github.com/volshebork/blue/archive/refs/heads/main.tar.gz"

# ensure destination exists, then download and extract directly into it
mkdir -p "$destination"
curl -L "$repo_url" | tar -xz -C "$destination" --strip-components=1

# explicitly set execute permissions, since tar extraction doesn't reliably preserve them
find "$destination" -type f -name "*.sh" -exec chmod +x {} \;