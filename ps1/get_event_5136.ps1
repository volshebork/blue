<#
.DESCRIPTION
    Retrieves privileged logon-related events (4624, 4672, 4648) from the Security log, filtered to privileged accounts.
    Exports to CSV/TXT/MD, shows grid.

.NOTES
    Author: Oscar Cortez
    Date Created: 2026-09-22
    Last Modified: 2026-09-22
#>

function ConvertTo-MarkdownTable {
    param([Parameter(Mandatory)][object[]]$Data)

    $props = $Data[0].PSObject.Properties.Name

    $rows = @()
    foreach ($item in $Data) {
        $cells = foreach ($p in $props) { ([string]$item.$p) -replace '\|', '\|' }
        $rows += ,@($cells)
    }

    $widths = for ($i = 0; $i -lt $props.Count; $i++) {
        $max = $props[$i].Length
        foreach ($r in $rows) { if ($r[$i].Length -gt $max) { $max = $r[$i].Length } }
        $max
    }

    $fmt = {
        param($cols)
        $padded = for ($i = 0; $i -lt $cols.Count; $i++) { $cols[$i].PadRight($widths[$i]) }
        "| " + ($padded -join " | ") + " |"
    }

    $lines = @(& $fmt $props)
    $lines += "|-" + (($widths | ForEach-Object { "-" * $_ }) -join "-|-") + "-|"
    foreach ($r in $rows) { $lines += & $fmt $r }
    $lines
}

Import-Module ActiveDirectory

New-Item -ItemType Directory -Path C:\temp -Force | Out-Null

# Build the list of privileged account names to filter on, from the same groups
# get_privileged_groups.ps1 checks. Re-queried here (rather than reading that
# script's CSV) so this script has no dependency on run order or file paths.
$GroupNames = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Account Operators",
    "Backup Operators",
    "DnsAdmins"
)

$PrivilegedAccounts = foreach ($GroupName in $GroupNames) {
    Get-ADGroupMember -Identity $GroupName -Recursive -ErrorAction SilentlyContinue |
        Where-Object { $_.objectClass -eq "user" } |
        Select-Object -ExpandProperty SamAccountName
}
$PrivilegedAccounts = $PrivilegedAccounts | Select-Object -Unique

# Pull logon-related events: 4624 (logon success), 4672 (special privileges assigned), 4648 (explicit credential use)
$Events = Get-WinEvent -FilterHashtable @{ LogName = "Security"; Id = 4624, 4672, 4648 } -ErrorAction SilentlyContinue

if (-not $Events) {
    Write-Host "No logon events (4624/4672/4648) found."
    return
}

# Logon type lookup for 4624, for readability
$LogonTypes = @{
    "2" = "Interactive"; "3" = "Network"; "4" = "Batch"; "5" = "Service"
    "7" = "Unlock"; "8" = "NetworkCleartext"; "9" = "NewCredentials"
    "10" = "RemoteInteractive (RDP)"; "11" = "CachedInteractive"
}

# Parse each event's XML; field names differ slightly between event IDs
$LogonReport = foreach ($event in $Events) {
    $xml = [xml]$event.ToXml()
    $data = $xml.Event.EventData.Data

    $logonTypeRaw = ($data | Where-Object { $_.Name -eq "LogonType" }).'#text'
    $logonType = if ($logonTypeRaw) { $LogonTypes[$logonTypeRaw] } else { "" }

    $subjectUser = ($data | Where-Object { $_.Name -eq "SubjectUserName" }).'#text'
    $targetUser  = ($data | Where-Object { $_.Name -eq "TargetUserName" }).'#text'

    [pscustomobject]@{
        TimeCreated     = $event.TimeCreated
        EventId         = $event.Id
        SubjectUser     = $subjectUser
        TargetUser      = $targetUser
        LogonType       = $logonType
        IpAddress       = ($data | Where-Object { $_.Name -eq "IpAddress" }).'#text'
        WorkstationName = ($data | Where-Object { $_.Name -eq "WorkstationName" }).'#text'
    }
}

# Filter to events where either the account doing the logon (SubjectUser) or the
# account being logged into/as (TargetUser) is one of the privileged accounts
# gathered above. Keeping both sides means this catches a privileged account
# logging on (TargetUser match) AND a privileged account being used to access
# something else remotely, as in 4648 (SubjectUser match).
$LogonReport = $LogonReport | Where-Object {
    ($_.SubjectUser -in $PrivilegedAccounts) -or ($_.TargetUser -in $PrivilegedAccounts)
}

$LogonReport = $LogonReport | Sort-Object TimeCreated -Descending

if (-not $LogonReport) {
    Write-Host "No logon events matched a privileged account."
    return
}

# Export to CSV
$LogonReport | Export-Csv -Path "C:\temp\LogonEvents_Privileged.csv" -NoTypeInformation

# Export to a human-readable text file
$LogonReport | Format-Table -AutoSize | Out-String -Width 4096 | Out-File "C:\temp\LogonEvents_Privileged.txt" -Encoding utf8

# Export to markdown table (UTF-8, no BOM)
[System.IO.File]::WriteAllLines("C:\temp\LogonEvents_Privileged.md", (ConvertTo-MarkdownTable $LogonReport), (New-Object System.Text.UTF8Encoding($false)))

# Display in an interactive grid (blocks until closed, so keep it last)
$LogonReport | Out-GridView -Title "Privileged Logon Events (4624/4672/4648)"