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

## Structure

```txt
py_version/
    main.py
    modules/
        __init__.py
        ensure_dependencies.py
        title.py
        ping.py
```

## Usage

```py
python main.py
```

Navigate the menu with arrow keys, Enter to select.

## Notes

- Password reset is implemented, but requires an LDAPS (port 636) connection, since it's a plaintext-sensitive write. This was not testable on the exercise domain controller, where only port 389 was open.
- Modules requiring valid AD credentials will prompt for them at runtime; nothing is hardcoded.
