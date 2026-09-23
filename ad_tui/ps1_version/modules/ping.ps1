# ad_tui/ps1_version/modules/ping.ps1
# Pings a user-specified host.

function Invoke-PingModule {
    $target = Read-Host "Enter a hostname or IP to ping"
    if (-not $target) { return }
    ping $target
}