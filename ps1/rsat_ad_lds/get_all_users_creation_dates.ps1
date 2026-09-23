<#
.DESCRIPTION
    Lists all AD user accounts with creation dates.
    Exports to CSV, TXT, and MD, and shows a grid.
    Run from a workstation against a target DC.
    You must have RSAT: Active Directory Domain Services and Lightweight Directory Tools installed.

.NOTES
    Author: Oscar Cortez
    Date Created: 2026-09-23
    Last Modified: 2026-09-23
#>

function ConvertTo-MarkdownTable {
    param([Parameter(Mandatory)][object[]]$Data)

    $props = $Data[0].PSObject.Properties.Name

    # build cell text, escaping pipes so values can't break the table
    $rows = @()
    foreach ($item in $Data) {
        $cells = foreach ($p in $props) { ([string]$item.$p) -replace '\|', '\|' }
        $rows += ,@($cells)
    }

    # widest value per column, including the header
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

# Ensure the Active Directory module is loaded
Import-Module ActiveDirectory

New-Item -ItemType Directory -Path C:\temp -Force | Out-Null

# Prompt for the target DC and credentials to query with
$dcName = Read-Host "Enter the domain controller hostname or IP"
$cred = Get-Credential -Message "Enter credentials with rights to query AD"

# Fetch all user accounts with creation dates
$AllUsersReport = Get-ADUser -Filter * -Properties whenCreated -Server $dcName -Credential $cred |
    Select-Object Name, SamAccountName, @{Name="CreationDate"; Expression={$_.whenCreated}}, Enabled

# Export to CSV
$AllUsersReport | Export-Csv -Path "C:\temp\AllUsers_CreationDates.csv" -NoTypeInformation

# Export to a human-readable text file
$AllUsersReport | Format-Table -AutoSize | Out-String -Width 4096 | Out-File "C:\temp\AllUsers_CreationDates.txt" -Encoding utf8

# Export to markdown table (UTF-8, no BOM)
[System.IO.File]::WriteAllLines("C:\temp\AllUsers_CreationDates.md", (ConvertTo-MarkdownTable $AllUsersReport), (New-Object System.Text.UTF8Encoding($false)))

# Display in an interactive grid (blocks until closed, so keep it last)
$AllUsersReport | Out-GridView -Title "All User Accounts - Creation Dates"