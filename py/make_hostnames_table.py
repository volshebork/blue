#!/usr/bin/env python3

# This script builds an aligned markdown table of discovered hosts from hostnames.xml.

import xml.etree.ElementTree as ET
from pathlib import Path

# variables
logs_dir = Path.home() / "main" / "blue" / "logs"
xml_file = logs_dir / "hostnames.xml"

# parse the XML and pull out hostname, IP, status, and MAC for each host
tree = ET.parse(xml_file)
root = tree.getroot()

hosts = []
for host in root.findall("host"):
    status = host.find("status").get("state")

    ipv4 = host.find("address[@addrtype='ipv4']").get("addr")

    mac_elem = host.find("address[@addrtype='mac']")
    mac = mac_elem.get("addr") if mac_elem is not None else ""
    vendor = mac_elem.get("vendor", "") if mac_elem is not None else ""

    hostname_elem = host.find("hostnames/hostname")
    hostname = hostname_elem.get("name") if hostname_elem is not None else ""

    times_elem = host.find("times")
    if times_elem is not None:
        latency = f"{int(times_elem.get('srtt')) / 1_000_000:.5f}s"
    else:
        latency = ""

    hosts.append({
        "hostname": hostname,
        "ip": ipv4,
        "status": status,
        "latency": latency,
        "mac": mac,
        "vendor": vendor,
    })

# build the four columns, and headers
headers = ("Hostname", "IP Address", "Status", "MAC Address")
rows = []
for h in hosts:
    hostname_col = h["hostname"] if h["hostname"] else ""
    ip_col = h["ip"]
    status_col = f"Host is up ({h['latency']} latency)." if h["latency"] else "Host is up."
    mac_col = f"{h['mac']} ({h['vendor']})" if h["mac"] else ""
    rows.append((hostname_col, ip_col, status_col, mac_col))

# compute the widest value per column (including the header) for alignment
widths = [max(len(row[i]) for row in [headers] + rows) for i in range(4)]

# build the markdown table, padding every cell to its column's width
def make_row(cols):
    padded = [col.ljust(widths[i]) for i, col in enumerate(cols)]
    return "| " + " | ".join(padded) + " |"

separator = "|-" + "-|-".join("-" * w for w in widths) + "-|"

table_lines = [make_row(headers), separator]
table_lines += [make_row(row) for row in rows]

# write the table to its own file
table_file = logs_dir / "hostnames_table.md"
table_file.write_text("\n".join(table_lines) + "\n")