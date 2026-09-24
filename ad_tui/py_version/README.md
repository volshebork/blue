# Active Directory Terminal User Interface Tool

A menu-driven terminal application for running Active Directory queries and actions, built for Blue Team exercises. Uses the `ldap3` library to talk directly to a domain controller over LDAP — no RSAT required.

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
- Set session details (domain controller, base DN, credentials) - prompted at startup
- See session details
- Change session details

### Upcoming

- Get user status (Enabled/disabled)
- Get privileged group membership with creation dates
- Get all users with creation dates
- Get disabled accounts
- Get accounts by creation date
- Get accounts with password never expiring
- Get group membership for a user
- Get accounts never logged on
- Get accurate last logon (cross-DC)
- Disable accounts (from list)
- Remove accounts from privileged groups
- Set account expiration (single/bulk)
- Delete account
- Reset password (requires LDAPS)

## Structure

```txt
py_version/
    main.py
    modules/
        __init__.py
        ensure_dependencies.py
        title.py
        ping.py
        session.py
```

## Usage

```py
python main.py
```

You'll be prompted for your domain controller and credentials at startup (base DN can be auto-discovered or entered manually). Navigate the menu with arrow keys, Enter to select.

## Notes

- Password reset is implemented, but requires an LDAPS (port 636) connection, since it's a plaintext-sensitive write. This was not testable on the exercise domain controller, where only port 389 was open.
- Session details (domain controller, base DN, username, password) are held in memory only for the current run - nothing is written to disk, and you'll need to re-enter them each time you launch the program.
- Modules requiring valid AD credentials use the session details set at startup; nothing is hardcoded.
