<#
.DESCRIPTION
    Removes users listed in a text file from all privileged AD groups
    (Domain Admins, Enterprise Admins, Schema Admins, Account Operators,
    Backup Operators, DnsAdmins).
    Run from a workstation against a target DC.
    You must edit the list path prior to running.
    You must have RSAT: Active Directory Domain Services and Lightweight Directory Tools installed.

.NOTES
    Author: Oscar Cortez
    Date Created: 2026-09-23
    Last Modified: 2026-09-23
#>

# Path to the username list - edit this before running
$listPath = "C:\Users\you\Desktop\usernames.txt"

if (-not (Test-Path $listPath)) {
    Write-Host "File not found: $listPath" -ForegroundColor Red
    return
}

Import-Module ActiveDirectory

# Prompt for the target DC and credentials to use
$dcName = Read-Host "Enter the domain controller hostname or IP"
$cred = Get-Credential -Message "Enter credentials with rights to modify group membership"

# Read usernames, skipping blank lines and commented-out (#) lines
$usernames = Get-Content $listPath | Where-Object { $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#") }

if (-not $usernames) {
    Write-Host "No usernames found in $listPath" -ForegroundColor Red
    return
}

# Groups to remove membership from
$GroupNames = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Account Operators",
    "Backup Operators",
    "DnsAdmins"
)

Write-Host "About to remove $($usernames.Count) account(s) from all privileged groups on $dcName`:"
$usernames | ForEach-Object { Write-Host "  - $_" }
$confirm = Read-Host "Type YES to proceed"
if ($confirm -ne "YES") {
    Write-Host "Aborted."
    return
}

# For each user, attempt removal from each privileged group; log per user/group result
$results = foreach ($user in $usernames) {
    foreach ($group in $GroupNames) {
        try {
            Remove-ADGroupMember -Identity $group -Members $user -Server $dcName -Credential $cred -Confirm:$false -ErrorAction Stop
            [pscustomobject]@{ Username = $user; Group = $group; Result = "Removed" }
        } catch {
            # Not a member of this group is expected/common, not a real failure
            if ($_.Exception.Message -like "*cannot find the member*" -or $_.Exception.Message -like "*not a member*") {
                [pscustomobject]@{ Username = $user; Group = $group; Result = "Not a member" }
            } else {
                [pscustomobject]@{ Username = $user; Group = $group; Result = "FAILED: $($_.Exception.Message)" }
            }
        }
    }
}

$results | Format-Table -AutoSize