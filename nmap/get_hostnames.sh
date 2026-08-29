#!/usr/bin/env bash

# This script will invoke an nmap command to gather hostnames on the network.

set -euo pipefail # exit on error, unset var, or failed pipe

# print usage and exit if called with no/bad args
usage() {
    echo "Usage: $0 <target_range>"
    echo "Example: $0 192.168.1.0/24"
    exit 1
}

# require at least 1 arg, else print usage and exit
[[ $# -ge 1 ]] || usage

# variables
target_range="$1"
logs_dir="$HOME/blue/logs"

# ping sweep + reverse DNS, saved as XML and plain text
sudo nmap -sn "$target_range" \
    -oX "$logs_dir/hostnames.xml" \
    -oN "$logs_dir/hostnames.txt"