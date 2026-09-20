#!/usr/bin/env bash

# This script will invoke an nmap command to gather hostnames on the network.

set -euo pipefail # exit on error, unset var, or failed pipe

# prompt for target range; blank input is an error
read -rp "Enter the target IP range to scan (e.g. 192.168.1.0/24): " target_range
if [[ -z "$target_range" ]]; then
    echo "Error: target range cannot be blank." >&2
    exit 1
fi

# variables
logs_dir="$HOME/main/blue/logs"

# ping sweep + reverse DNS, saved as XML, plain text, and grepable
sudo nmap -sn "$target_range" \
    -oX "$logs_dir/hostnames.xml" \
    -oN "$logs_dir/hostnames.txt" \
    -oG "$logs_dir/hostnames.gnmap" # used to create ips.txt

# insert a blank line before each host entry in the text output, for readability
sed -i 's/^Nmap scan report for/\n&/' "$logs_dir/hostnames.txt"

# extract just the IPs of live hosts into a plain list, one per line, to be used by get_host_details.sh
awk '/Status: Up/{print $2}' "$logs_dir/hostnames.gnmap" > "$logs_dir/ips.txt"

# generate the readable markdown table from this run's results
python3 "$HOME/main/blue/py/make_hostnames_table.py"