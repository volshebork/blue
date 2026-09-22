# Disables AD accounts listed in a text file (one username per line), run locally on the domain controller.

# Path to the username list - edit this before running
$listPath = "C:\Users\you\Desktop\usernames.txt"

if (-not (Test-Path $listPath)) {
    Write-Host "File not found: $listPath" -ForegroundColor Red
    return
}

Import-Module ActiveDirectory

# Read usernames, skipping blank lines
$usernames = Get-Content $listPath | Where-Object { $_.Trim() -ne "" }

if (-not $usernames) {
    Write-Host "No usernames found in $listPath" -ForegroundColor Red
    return
}

Write-Host "About to disable $($usernames.Count) account(s):"
$usernames | ForEach-Object { Write-Host "  - $_" }
$confirm = Read-Host "Type YES to proceed"
if ($confirm -ne "YES") {
    Write-Host "Aborted."
    return
}

# Disable each account, logging success/failure per user
$results = foreach ($user in $usernames) {
    try {
        Disable-ADAccount -Identity $user -ErrorAction Stop
        [pscustomobject]@{ Username = $user; Result = "Disabled" }
    } catch {
        [pscustomobject]@{ Username = $user; Result = "FAILED: $($_.Exception.Message)" }
    }
}

$results | Format-Table -AutoSize
