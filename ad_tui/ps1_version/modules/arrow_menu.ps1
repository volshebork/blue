# ad_tui/ps1_version/modules/arrow_menu.ps1
# Displays a title and a menu of options navigable with arrow keys; returns the selected option on Enter.

function Show-ArrowMenu {
    param(
        [string[]]$Options,
        [scriptblock]$TitleBlock
    )

    $selected = 0
    $key = $null

    while ($key -ne 13) {  # 13 = Enter
        Clear-Host
        if ($TitleBlock) { & $TitleBlock }

        for ($i = 0; $i -lt $Options.Count; $i++) {
            if ($i -eq $selected) {
                Write-Host "> $($Options[$i])" -ForegroundColor Cyan
            } else {
                Write-Host "  $($Options[$i])"
            }
        }

        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode

        if ($key -eq 38) { $selected = [Math]::Max(0, $selected - 1) }       # Up arrow
        if ($key -eq 40) { $selected = [Math]::Min($Options.Count - 1, $selected + 1) }  # Down arrow
    }

    return $Options[$selected]
}