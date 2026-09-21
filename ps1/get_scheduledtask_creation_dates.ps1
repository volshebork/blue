# Lists scheduled tasks with their creation dates, exports to CSV, and shows a grid.
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

# Display in an interactive grid
$TaskReport | Out-GridView -Title "Scheduled Tasks Creation Dates"