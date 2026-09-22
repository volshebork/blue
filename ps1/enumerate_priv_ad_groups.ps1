# Enumerates privileged AD groups and reports member creation dates, CSV/TXT/MD exports, terminal grid.

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

Import-Module ActiveDirectory

New-Item -ItemType Directory -Path C:\temp -Force | Out-Null

# Groups to check
$GroupNames = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Account Operators",
    "Backup Operators",
    "DnsAdmins"
)

# Fetch members of each group, filter for user accounts, tag with group name
$PrivGroupReport = foreach ($GroupName in $GroupNames) {
    Get-ADGroupMember -Identity $GroupName -Recursive -ErrorAction SilentlyContinue |
        Where-Object { $_.objectClass -eq "user" } |
        ForEach-Object {
            Get-ADUser -Identity $_.SamAccountName -Properties whenCreated |
                Select-Object @{Name="Group"; Expression={$GroupName}}, Name, SamAccountName, @{Name="CreationDate"; Expression={$_.whenCreated}}, Enabled
        }
}

# Export to CSV
$PrivGroupReport | Export-Csv -Path "C:\temp\PrivilegedGroups_CreationDates.csv" -NoTypeInformation

# Export to a human-readable text file
$PrivGroupReport | Format-Table -AutoSize | Out-String -Width 4096 | Out-File "C:\temp\PrivilegedGroups_CreationDates.txt" -Encoding utf8

# Export to markdown table (UTF-8, no BOM)
[System.IO.File]::WriteAllLines("C:\temp\PrivilegedGroups_CreationDates.md", (ConvertTo-MarkdownTable $PrivGroupReport), (New-Object System.Text.UTF8Encoding($false)))

# Display in an interactive grid (blocks until closed, so keep it last)
$PrivGroupReport | Out-GridView -Title "Privileged Group Membership Creation Dates"