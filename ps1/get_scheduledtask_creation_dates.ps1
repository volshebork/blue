# Lists scheduled tasks with creation dates; exports to CSV, TXT, and MD, and shows a grid.

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

New-Item -ItemType Directory -Path C:\temp -Force | Out-Null

$TaskReport = Get-ScheduledTask | ForEach-Object {
    $taskFile = Join-Path "$env:SystemRoot\System32\Tasks" ($_.TaskPath.TrimStart('\') + $_.TaskName)
    [pscustomobject]@{
        TaskName    = $_.TaskName
        TaskPath    = $_.TaskPath
        State       = $_.State
        Author      = $_.Author
        Registered  = $_.Date
        FileCreated = (Get-Item $taskFile -ErrorAction SilentlyContinue).CreationTime
    }
} | Sort-Object FileCreated -Descending

# Export to CSV
$TaskReport | Export-Csv -Path "C:\temp\ScheduledTasks_CreationDates.csv" -NoTypeInformation

# Export to a human-readable text file
$TaskReport | Format-Table -AutoSize | Out-String -Width 4096 | Out-File "C:\temp\ScheduledTasks_CreationDates.txt" -Encoding utf8

# Export to markdown table (UTF-8, no BOM)
[System.IO.File]::WriteAllLines("C:\temp\ScheduledTasks_CreationDates.md", (ConvertTo-MarkdownTable $TaskReport), (New-Object System.Text.UTF8Encoding($false)))

# Display in an interactive grid (blocks until closed, so keep it last)
$TaskReport | Out-GridView -Title "Scheduled Tasks Creation Dates"