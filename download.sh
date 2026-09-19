#!/usr/bin/env bash

# This script downloads the Blue toolkit files from GitHub (no .git history) into a directory you choose.

set -euo pipefail  # exit on error, unset var, or failed pipe

# prompt for destination, defaulting to ~/main/blue if left blank
read -rp "Enter the directory to download the toolkit to [~/main/blue]: " destination
destination="${destination:-$HOME/main/blue}"

# variables
repo_url="https://github.com/volshebork/blue/archive/refs/heads/main.tar.gz"

# ensure destination exists, then download and extract directly into it
mkdir -p "$destination"
curl -L "$repo_url" | tar -xz -C "$destination" --strip-components=1

# explicitly set execute permissions, since tar extraction doesn't reliably preserve them
find "$destination" -type f -name "*.sh" -exec chmod +x {} \;