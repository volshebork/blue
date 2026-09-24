# ad_tui/py_version/modules/session.py
# Holds shared AD connection settings (DC host, base DN, credentials) for the current run.
# Set once via the menu; other modules read from here instead of prompting each time.

import questionary

# Defaults - edit if your environment's typical values differ
BASE_DN_DEFAULT = "DC=domain,DC=com"

_dc_host = None
_base_dn = None
_username = None
_password = None

def set_domain_controller():
    global _dc_host, _base_dn
    _dc_host = questionary.text("Enter the domain controller hostname or IP:").ask()
    _base_dn = questionary.text("Enter the base DN:", default=BASE_DN_DEFAULT).ask()
    print("Domain controller settings saved for this session.")

def set_credentials():
    global _username, _password
    _username = questionary.text("Enter your username (DOMAIN\\user):").ask()
    _password = questionary.password("Enter your password:").ask()
    print("Credentials saved for this session.")

def get_connection_info():
    """Returns (dc_host, base_dn, username, password), or None for any not yet set."""
    return _dc_host, _base_dn, _username, _password

def is_configured():
    return all([_dc_host, _base_dn, _username, _password])