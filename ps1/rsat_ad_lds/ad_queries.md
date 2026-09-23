# Active Direcotry Query Commands

This file contains ad hoc commands for useful AD queries.

These commands are meant to be run from a workstation with RSAT: Active Directory Domain Services and Lightweight Directory Tools installed.

## Get-ADUser Commands

Query a specific SAM Account Name and get enabled status.

```ps1
Get-ADUser -Identity "SamAccountName" -Properties Enabled -server 192.168.1.1 -Credential (Get-Credential) | Select-Object SamAccountName, Enabled
```

Filter for a SAM Account Name and get Enabled Status

```ps1
Get-ADUser -Filter "SamAccountName -like '*'" -Properties Enabled -server 192.168.1.1 -Credential (Get-Credential) | Select-Object SamAccountName, Enabled
```
