# Active Directory Terminal User Interface Tool

A menu-driven terminal application for running Active Directory queries and actions, built for Blue Team exercises. Uses the `ldap3` library to talk directly to a domain controller over LDAP — no RSAT required.

**Requires valid, authorized AD credentials to function.** This tool has no exploitation or credential-bypass capability — it is an incident response aid, not an attack tool.

## Requirements

- Python 3
- `ldap3` (installed automatically on first run if missing)
- `questionary` (installed automatically on first run if missing)

## Why Python instead of PowerShell/RSAT

- RSAT can only be installed on Windows Pro, Enterprise, or Education editions — not Home.
- Exercise workstations block PowerShell script execution (`Restricted` policy), with no reliable workaround if it's enforced via GPO (`MachinePolicy`).
- `.py` file execution and `pip install` were not blocked in testing on the target environment.
- `ldap3` talks directly to the domain controller over LDAP/LDAPS, the same protocol RSAT's cmdlets use under the hood — so no Windows edition restriction and no PowerShell execution policy involved at all.

A parallel PowerShell version exists in `../ps1_version/` but is kept only as a minimal reference (title, arrow-key menu, ping) and isn't being developed further.

## Features

### Available

- Ping a host
- Session details (domain controller, base DN, credentials) - prompted at startup
- See session details
- Change session details
- Set export path (prompted automatically on first export if not set)
- Set user list path (prompted automatically on first use if not set) - shared by all actions that take a username list
- Get user details (status, group membership, creation date, password last set, last logon, admin count, expiration, description)
- Enumerate privileged groups (Domain Admins, Enterprise Admins, Schema Admins, Account Operators, Backup Operators, DnsAdmins - includes nested group membership)
- Remove users from privileged groups (from a username list file)
- Disable accounts (from a username list file)
- Delete account (single account, requires typing `DELETE` to confirm)
- Export results to `.txt` (markdown table), `.csv`, or both

### Upcoming

- Get all users with creation dates
- Get disabled accounts
- Get accounts by creation date
- Get accounts with password never expiring
- Get accounts never logged on
- Get accurate last logon (cross-DC)
- Set account expiration (single/bulk)
- Reset password (requires LDAPS)

## Structure

````txt
py_version/
    main.py
    modules/
        __init__.py
        ensure_dependencies.py
        title.py
        ping.py
        session.py
        get_user_details.py
        enumerate_privileged_groups.py
        remove_privileged_groups.py
        disable_accounts.py
        delete_account.py
        markdown_table.py
        export_helper.py
````

## Usage

````py
python main.py
````

You'll be prompted for your domain controller and credentials at startup (base DN can be auto-discovered or entered manually). The menu is organized into submenus (Session, Queries, Actions), each with a "Back to Main Menu" option. Navigate with arrow keys, Enter to select.

## Notes

- Password reset requires an LDAPS (port 636) connection, since it's a plaintext-sensitive write. This was not testable on the exercise domain controller, where only port 389 was open — not yet implemented.
- Disable accounts works by flipping the `ACCOUNTDISABLE` bit in `userAccountControl` directly, since `ldap3` has no dedicated "disable account" call the way RSAT's `Disable-ADAccount` does. Test against a non-critical account before relying on it.
- Delete account is permanent and destructive. Disabling is usually the correct IR action instead - it preserves the account, SID, group memberships, and audit trail for forensics.
- Session details (domain controller, base DN, username, password) are held in memory only for the current run - nothing is written to disk, and you'll need to re-enter them each time you launch the program.
- Export path and user list path are not prompted at startup - each is requested once, the first time it's needed, and reused for the rest of the session. Both can also be set/changed proactively from the Session menu.
- Username list files support blank lines and `#`-prefixed comment lines, which are skipped.
- Modules requiring valid AD credentials use the session details set at startup; nothing is hardcoded.
