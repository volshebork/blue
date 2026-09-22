# Enumerates WMI permanent event subscriptions (filters, consumers, and bindings) - a common fileless persistence mechanism; exports to CSV/TXT/MD, shows grid.

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

# WMI persistence has three parts that work together: a Filter (the trigger condition,
# e.g. "every 60 seconds" or "at logon"), a Consumer (the action taken - commonly
# CommandLineEventConsumer, which runs a command), and a Binding (links a filter to
# a consumer). All three live in the root\subscription namespace and normally have
# very few entries on a clean system, so anything present is worth reviewing.

$Filters = Get-WmiObject -Namespace root\subscription -Class __EventFilter -ErrorAction SilentlyContinue
$Consumers = Get-WmiObject -Namespace root\subscription -Class __EventConsumer -ErrorAction SilentlyContinue
$Bindings = Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding -ErrorAction SilentlyContinue

if (-not $Filters -and -not $Consumers -and -not $Bindings) {
    Write-Host "No WMI event filters, consumers, or bindings found."
    return
}

# Build one combined report: each binding links a filter to a consumer, so resolve
# those references into readable names/queries/commands rather than raw WMI paths
$SubscriptionReport = foreach ($binding in $Bindings) {
    $filterName = ($binding.Filter -split '"')[1]
    $consumerName = ($binding.Consumer -split '"')[1]

    $filter = $Filters | Where-Object { $_.Name -eq $filterName }
    $consumer = $Consumers | Where-Object { $_.Name -eq $consumerName }

    [pscustomobject]@{
        FilterName    = $filterName
        Query         = $filter.Query
        ConsumerName  = $consumerName
        ConsumerClass = $consumer.__CLASS
        CommandLine   = $consumer.CommandLineTemplate   # populated for CommandLineEventConsumer
        ScriptText    = $consumer.ScriptText             # populated for ActiveScriptEventConsumer
        CreatorSID    = $filter.CreatorSID -join ","
    }
}

if (-not $SubscriptionReport) {
    Write-Host "No filter-to-consumer bindings found (filters/consumers exist independently with nothing tying them together)."
    return
}

# Export to CSV
$SubscriptionReport | Export-Csv -Path "C:\temp\WmiSubscriptions.csv" -NoTypeInformation

# Export to a human-readable text file
$SubscriptionReport | Format-Table -AutoSize | Out-String -Width 4096 | Out-File "C:\temp\WmiSubscriptions.txt" -Encoding utf8

# Export to markdown table (UTF-8, no BOM)
[System.IO.File]::WriteAllLines("C:\temp\WmiSubscriptions.md", (ConvertTo-MarkdownTable $SubscriptionReport), (New-Object System.Text.UTF8Encoding($false)))

# Display in an interactive grid (blocks until closed, so keep it last)
$SubscriptionReport | Out-GridView -Title "WMI Event Subscriptions"