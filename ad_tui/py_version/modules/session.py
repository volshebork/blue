# ad_tui/py_version/modules/session.py
# Holds shared AD connection settings (DC host, base DN, credentials), export path, and user list path for the current run.
# Export path and user list path are set lazily on first use, or manually via the Session menu.
# Base DN can be auto-discovered from the DC or entered manually.
# Other modules read from here instead of prompting each time.

import questionary
from pathlib import Path
from ldap3 import Server, Connection, ALL

EXPORT_PATH_DEFAULT = str(Path.home() / "ad_tui_exports")

_dc_host = None
_base_dn = None
_username = None
_password = None
_export_path = None
_user_list_path = None

def _discover_base_dn(dc_host):
    server = Server(dc_host, get_info=ALL)
    conn = Connection(server, auto_bind=True)  # anonymous bind, just to read RootDSE
    base_dn = server.info.other.get("defaultNamingContext", [None])[0]
    conn.unbind()
    return base_dn

def prompt_for_session():
    global _dc_host, _base_dn, _username, _password
    print("Session setup - enter your domain controller and credentials.")
    _dc_host = questionary.text("Enter the domain controller hostname or IP (e.g. 192.168.1.1):").ask()

    method = questionary.select(
        "How would you like to set the base DN?",
        choices=["Auto-discover from domain controller", "Enter manually"]
    ).ask()

    if method == "Auto-discover from domain controller":
        print("Discovering base DN from the domain controller...")
        try:
            _base_dn = _discover_base_dn(_dc_host)
            print(f"Base DN discovered: {_base_dn}")
        except Exception as e:
            print(f"Could not auto-discover base DN: {e}")
            _base_dn = questionary.text("Enter the base DN manually (e.g. DC=corp,DC=local):").ask()
    else:
        _base_dn = questionary.text("Enter the base DN (e.g. DC=corp,DC=local):").ask()

    _username = questionary.text("Enter your username (e.g. DOMAIN\\jsmith):").ask()
    _password = questionary.password("Enter your password:").ask()

    print("Session configured.")

def get_connection_info():
    """Returns (dc_host, base_dn, username, password)."""
    return _dc_host, _base_dn, _username, _password

def get_export_path():
    """Returns the export path, prompting for it on first use if not yet set."""
    global _export_path
    if not _export_path:
        _export_path = questionary.text("Enter the export folder path:", default=EXPORT_PATH_DEFAULT).ask()
        Path(_export_path).mkdir(parents=True, exist_ok=True)
    return _export_path

def set_export_path():
    """Prompts to set/change the export path directly, regardless of current value."""
    global _export_path
    default = _export_path if _export_path else EXPORT_PATH_DEFAULT
    _export_path = questionary.text("Enter the export folder path:", default=default).ask()
    Path(_export_path).mkdir(parents=True, exist_ok=True)
    print(f"Export path set to: {_export_path}")

def get_user_list_path():
    """Returns the user list file path, prompting for it on first use if not yet set."""
    global _user_list_path
    if not _user_list_path:
        _user_list_path = questionary.text("Enter the path to the username list file:").ask()
    return _user_list_path

def set_user_list_path():
    """Prompts to set/change the user list path directly, regardless of current value."""
    global _user_list_path
    default = _user_list_path if _user_list_path else ""
    _user_list_path = questionary.text("Enter the path to the username list file:", default=default).ask()
    print(f"User list path set to: {_user_list_path}")

def is_configured():
    return all([_dc_host, _base_dn, _username, _password])

def show_session_details():
    print("Current session details:")
    print(f"  Domain Controller: {_dc_host}")
    print(f"  Base DN:           {_base_dn}")
    print(f"  Username:          {_username}")
    print(f"  Password:          {'*' * len(_password) if _password else None}")
    print(f"  Export Path:       {_export_path if _export_path else '(not set yet)'}")
    print(f"  User List Path:    {_user_list_path if _user_list_path else '(not set yet)'}")
    input("\nPress Enter to return to the main menu...")