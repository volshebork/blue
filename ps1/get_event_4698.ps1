# Retrieves Event ID 4698 (scheduled task created) entries from the Security log; exports to CSV/TXT/MD, shows grid.

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

# Pull Event ID 4698 (a scheduled task was created) from the Security log
$Events = Get-WinEvent -FilterHashtable @{ LogName = "Security"; Id = 4698 } -ErrorAction SilentlyContinue

if (-not $Events) {
    Write-Host "No Event ID 4698 entries found. (Task Scheduler auditing may not be enabled, or no tasks have been created.)"
    return
}

# Parse each event's XML for the subject (who) and task name
$TaskCreationReport = foreach ($event in $Events) {
    $xml = [xml]$event.ToXml()
    $data = $xml.Event.EventData.Data
    [pscustomobject]@{
        TimeCreated = $event.TimeCreated
        SubjectUser = ($data | Where-Object { $_.Name -eq "SubjectUserName" }).'#text'
        SubjectDomain = ($data | Where-Object { $_.Name -eq "SubjectDomainName" }).'#text'
        TaskName = ($data | Where-Object { $_.Name -eq "TaskName" }).'#text'
    }
}

$TaskCreationReport = $TaskCreationReport | Sort-Object TimeCreated -Descending

# Export to CSV
$TaskCreationReport | Export-Csv -Path "C:\temp\TaskCreationEvents_4698.csv" -NoTypeInformation

# Export to a human-readable text file
$TaskCreationReport | Format-Table -AutoSize | Out-String -Width 4096 | Out-File "C:\temp\TaskCreationEvents_4698.txt" -Encoding utf8

# Export to markdown table (UTF-8, no BOM)
[System.IO.File]::WriteAllLines("C:\temp\TaskCreationEvents_4698.md", (ConvertTo-MarkdownTable $TaskCreationReport), (New-Object System.Text.UTF8Encoding($false)))

# Display in an interactive grid (blocks until closed, so keep it last)
$TaskCreationReport | Out-GridView -Title "Scheduled Task Creation Events (4698)"