# Lists installed services with start type and path; exports to CSV, TXT, and MD, and shows a grid.

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

New-Item -ItemType Directory -Path C:\temp -Force | Out-Null

# Get service details via CIM (Win32_Service), which includes path and start mode not exposed by Get-Service alone
$ServiceReport = Get-CimInstance -ClassName Win32_Service | ForEach-Object {
    [pscustomobject]@{
        Name        = $_.Name
        DisplayName = $_.DisplayName
        State       = $_.State
        StartMode   = $_.StartMode
        StartName   = $_.StartName
        PathName    = $_.PathName
    }
} | Sort-Object Name

# Export to CSV
$ServiceReport | Export-Csv -Path "C:\temp\Services_Current.csv" -NoTypeInformation

# Export to a human-readable text file
$ServiceReport | Format-Table -AutoSize | Out-String -Width 4096 | Out-File "C:\temp\Services_Current.txt" -Encoding utf8

# Export to markdown table (UTF-8, no BOM)
[System.IO.File]::WriteAllLines("C:\temp\Services_Current.md", (ConvertTo-MarkdownTable $ServiceReport), (New-Object System.Text.UTF8Encoding($false)))

# Display in an interactive grid (blocks until closed, so keep it last)
$ServiceReport | Out-GridView -Title "Current Services"