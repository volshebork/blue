# ad_tui/py_version/modules/session.py
# Holds shared AD connection settings (DC host, base DN, credentials) for the current run.
# Prompted once at startup; base DN can be auto-discovered from the DC or entered manually.
# Other modules read from here instead of prompting each time.

import questionary
from ldap3 import Server, Connection, ALL

_dc_host = None
_base_dn = None
_username = None
_password = None

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

def is_configured():
    return all([_dc_host, _base_dn, _username, _password])

def show_session_details():
    print("Current session details:")
    print(f"  Domain Controller: {_dc_host}")
    print(f"  Base DN:           {_base_dn}")
    print(f"  Username:          {_username}")
    print(f"  Password:          {'*' * len(_password) if _password else None}")
    input("\nPress Enter to return to the main menu...")