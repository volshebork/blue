<#
.DESCRIPTION
    Lists Domain Admins with creation dates.
    Exports to CSV, TXT, and MD, and shows a grid.


.NOTES
    Author: Oscar Cortez
    Date Created: 2026-09-22
    Last Modified: 2026-09-22
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

# Define the group name
$GroupName = "Domain Admins"

# Fetch group members, filter for user accounts only, and grab their creation dates
$DomainAdminsReport = Get-ADGroupMember -Identity $GroupName -Recursive |
    Where-Object { $_.objectClass -eq "user" } |
    ForEach-Object {
        Get-ADUser -Identity $_.SamAccountName -Properties whenCreated
    } |
    Select-Object Name, SamAccountName, @{Name="CreationDate"; Expression={$_.whenCreated}}, Enabled

# Export to CSV
$DomainAdminsReport | Export-Csv -Path "C:\temp\DomainAdmins_CreationDates.csv" -NoTypeInformation

# Export to a human-readable text file
$DomainAdminsReport | Format-Table -AutoSize | Out-String -Width 4096 | Out-File "C:\temp\DomainAdmins_CreationDates.txt" -Encoding utf8

# Export to markdown table (UTF-8, no BOM)
[System.IO.File]::WriteAllLines("C:\temp\DomainAdmins_CreationDates.md", (ConvertTo-MarkdownTable $DomainAdminsReport), (New-Object System.Text.UTF8Encoding($false)))

# Display in an interactive grid (blocks until closed, so keep it last)
$DomainAdminsReport | Out-GridView -Title "Domain Admins Creation Dates"