# Disables AD accounts listed in a text file (one username per line), run from a workstation against a target DC.

# Path to the username list - edit this before running
$listPath = "C:\Users\you\Desktop\usernames.txt"

if (-not (Test-Path $listPath)) {
    Write-Host "File not found: $listPath" -ForegroundColor Red
    return
}

# Prompt for the domain controller to target and credentials to use
$dcName = Read-Host "Enter the domain controller hostname or IP"
$cred = Get-Credential -Message "Enter credentials with rights to disable accounts"

# Read usernames, skipping blank lines
$usernames = Get-Content $listPath | Where-Object { $_.Trim() -ne "" }

if (-not $usernames) {
    Write-Host "No usernames found in $listPath" -ForegroundColor Red
    return
}

Write-Host "About to disable $($usernames.Count) account(s) on $dcName`:"
$usernames | ForEach-Object { Write-Host "  - $_" }
$confirm = Read-Host "Type YES to proceed"
if ($confirm -ne "YES") {
    Write-Host "Aborted."
    return
}

# Disable each account, logging success/failure per user
$results = foreach ($user in $usernames) {
    try {
        Disable-ADAccount -Identity $user -Server $dcName -Credential $cred -ErrorAction Stop
        [pscustomobject]@{ Username = $user; Result = "Disabled" }
    } catch {
        [pscustomobject]@{ Username = $user; Result = "FAILED: $($_.Exception.Message)" }
    }
}

$results | Format-Table -AutoSize
