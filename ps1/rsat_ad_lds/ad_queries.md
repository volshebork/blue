# Active Directory Query Commands

This file contains ad hoc commands for useful AD queries.

These commands are meant to be run from a workstation with RSAT: Active Directory Domain Services and Lightweight Directory Tools installed.

## Get-ADUser Commands

Query a specific SAM Account Name and get enabled status.

```ps1
Get-ADUser `
    -Identity "SamAccountName" `
    -Properties Enabled `
    -server 192.168.1.1 `
    -Credential (Get-Credential) `
    | Select-Object SamAccountName, Enabled
```

Filter for a SAM Account Name and get Enabled Status.

```ps1
Get-ADUser `
    -Filter "SamAccountName -like '*'" `
    -Properties Enabled `
    -server 192.168.1.1 `
    -Credential (Get-Credential) `
    | Select-Object SamAccountName, Enabled
```

## Other Commands

Disable an account.

```ps1
Disable-ADAccount `
    -Identity "SamAccountName" `
    -Server 192.168.1.1 `
    -Credential (Get-Credential)
```

Find accounts with no pw expiration.

```ps1
Get-ADUser `
    -Filter "PasswordNeverExpires -eq `$true" `
    -Server 192.168.1.1 `
    -Credential (Get-Credential) `
    | Select-Object SamAccountName, Name
```

Check group membership of a specified user.

```ps1
Get-ADPrincipalGroupMembership `
    -Identity "SamAccountName" `
    -Server 192.168.1.1 `
    -Credential (Get-Credential) `
    | Select-Object Name
```

Reset a password.

```ps1
Set-ADAccountPassword `
    -Identity "SamAccountName" `
    -Reset `
    -NewPassword (ConvertTo-SecureString "NewPassword123!" -AsPlainText -Force) `
    -Server 192.168.1.1 `
    -Credential (Get-Credential)
```

Reset a password securely.

```ps1
Set-ADAccountPassword `
    -Identity "SamAccountName" `
    -Reset `
    -NewPassword (Read-Host -AsSecureString "Enter new password") `
    -Server 192.168.1.1 `
    -Credential (Get-Credential)
```
