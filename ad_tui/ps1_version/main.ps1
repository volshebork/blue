# ad_tui/ps1_version/main.ps1
# Menu skeleton only - dot-sources each module and calls its function.

. "$PSScriptRoot\modules\title.ps1"
. "$PSScriptRoot\modules\ping.ps1"

Show-Title

while ($true) {
    $choice = Read-Host "AD TUI`nSelect: [1] Ping  [2] Exit"
    switch ($choice) {
        "1" { Invoke-PingModule }
        "2" { return }
        default { Write-Host "Invalid choice." }
    }
}