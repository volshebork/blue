# Retrieves Event ID 7045 (new service installed) entries from the System log; exports to CSV/TXT/MD, shows grid.

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

# Pull Event ID 7045 (a new service was installed) from the System log
$Events = Get-WinEvent -FilterHashtable @{ LogName = "System"; Id = 7045 } -ErrorAction SilentlyContinue

if (-not $Events) {
    Write-Host "No Event ID 7045 entries found."
    return
}

# Parse each event's XML for service name, image path, start type, and account
$ServiceInstallReport = foreach ($event in $Events) {
    $xml = [xml]$event.ToXml()
    $data = $xml.Event.EventData.Data
    [pscustomobject]@{
        TimeCreated = $event.TimeCreated
        ServiceName = ($data | Where-Object { $_.Name -eq "ServiceName" }).'#text'
        ImagePath   = ($data | Where-Object { $_.Name -eq "ImagePath" }).'#text'
        StartType   = ($data | Where-Object { $_.Name -eq "StartType" }).'#text'
        AccountName = ($data | Where-Object { $_.Name -eq "AccountName" }).'#text'
    }
}

$ServiceInstallReport = $ServiceInstallReport | Sort-Object TimeCreated -Descending

# Export to CSV
$ServiceInstallReport | Export-Csv -Path "C:\temp\ServiceInstallEvents_7045.csv" -NoTypeInformation

# Export to a human-readable text file
$ServiceInstallReport | Format-Table -AutoSize | Out-String -Width 4096 | Out-File "C:\temp\ServiceInstallEvents_7045.txt" -Encoding utf8

# Export to markdown table (UTF-8, no BOM)
[System.IO.File]::WriteAllLines("C:\temp\ServiceInstallEvents_7045.md", (ConvertTo-MarkdownTable $ServiceInstallReport), (New-Object System.Text.UTF8Encoding($false)))

# Display in an interactive grid (blocks until closed, so keep it last)
$ServiceInstallReport | Out-GridView -Title "Service Install Events (7045)"