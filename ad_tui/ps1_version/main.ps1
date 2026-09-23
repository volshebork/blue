# ad_tui/ps1_version/main.ps1
# Menu skeleton only - dot-sources each module and calls its function.

. "$PSScriptRoot\modules\title.ps1"
. "$PSScriptRoot\modules\ping.ps1"
. "$PSScriptRoot\modules\arrow_menu.ps1"

while ($true) {
    $choice = Show-ArrowMenu -Options @("Ping", "Exit") -TitleBlock { Show-Title }

    switch ($choice) {
        "Ping" { Invoke-PingModule }
        "Exit" { return }
    }
}