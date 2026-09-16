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

# ping sweep + reverse DNS, saved as XML, plain text, and grepable
sudo nmap -sn "$target_range" \
    -oX "$logs_dir/hostnames.xml" \
    -oN "$logs_dir/hostnames.txt" \
    -oG "$logs_dir/hostnames.gnmap" # used to create ips.txt

# insert a blank line before each host entry in the text output, for readability
sed -i 's/^Nmap scan report for/\n&/' "$logs_dir/hostnames.txt"

# verify awk is correctly grouping each host's lines together before building the table
awk -v RS="" -v FS="\n" '{ print NF, $1 }' "$logs_dir/hostnames.txt"

# extract just the IPs of live hosts into a plain list, one per line, to be used by get_host_details.sh
awk '/Status: Up/{print $2}' "$logs_dir/hostnames.gnmap" > "$logs_dir/ips.txt"