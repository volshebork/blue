#!/usr/bin/env bash

# This script will invoke an nmap command to gather OS and service details for discovered hosts.
# You can add an argument to choose how many top ports get scanned, or have no argument to have the default 1000 top ports scanned.

set -euo pipefail  # exit on error, unset var, or failed pipe

# variables
logs_dir="$HOME/main/blue/logs"
ips_file="$logs_dir/ips.txt"  # produced by get_hostnames.sh
ports="${1:-}"  # optional; leave blank to use nmap's default top 1000 ports

# build the port flag only if a port count was given
port_flag=()
if [[ -n "$ports" ]]; then
    port_flag=(--top-ports "$ports")
fi

# OS + service/version detection against discovered hosts, saved as XML and plain text
# no port argument given uses nmap's default top 1000 ports
sudo nmap -sV -O "${port_flag[@]}" -iL "$ips_file" \
    -oX "$logs_dir/host_details.xml" \
    -oN "$logs_dir/host_details.txt"