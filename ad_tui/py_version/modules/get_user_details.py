# ad_tui/py_version/modules/get_user_details.py
# Queries a specific SamAccountName in AD and reports status, group membership, and key attributes.

from ldap3 import Server, Connection, ALL, NTLM
import questionary
from modules import session

# userAccountControl bit flag for a disabled account
ACCOUNTDISABLE = 0x2

ATTRIBUTES = [
    "sAMAccountName",
    "userAccountControl",
    "memberOf",
    "whenCreated",
    "pwdLastSet",
    "lastLogonTimestamp",
    "adminCount",
    "accountExpires",
    "description",
]

def run():
    dc_host, base_dn, username, password = session.get_connection_info()

    if not all([dc_host, base_dn, username, password]):
        print("Session details are not fully set. Use 'Set Session Details' first.")
        return

    target_user = questionary.text("Enter the SamAccountName to look up:").ask()
    if not target_user:
        return

    server = Server(dc_host, get_info=ALL)
    conn = Connection(server, user=username, password=password, authentication=NTLM, auto_bind=True)

    conn.search(
        base_dn,
        f"(sAMAccountName={target_user})",
        attributes=ATTRIBUTES
    )

    if not conn.entries:
        print(f"No account found for {target_user}")
        conn.unbind()
        return

    entry = conn.entries[0]
    uac = int(entry.userAccountControl.value) if entry.userAccountControl else 0
    enabled = not bool(uac & ACCOUNTDISABLE)

    print(f"SamAccountName:     {entry.sAMAccountName.value}")
    print(f"Enabled:            {enabled}")
    print(f"Created:            {entry.whenCreated.value if entry.whenCreated else 'N/A'}")
    print(f"Password Last Set:  {entry.pwdLastSet.value if entry.pwdLastSet else 'N/A'}")
    print(f"Last Logon:         {entry.lastLogonTimestamp.value if entry.lastLogonTimestamp else 'N/A'}")
    print(f"Account Expires:    {entry.accountExpires.value if entry.accountExpires else 'N/A'}")
    print(f"AdminCount:         {entry.adminCount.value if entry.adminCount else 0}")
    print(f"Description:        {entry.description.value if entry.description else 'N/A'}")

    print("Group Memberships:")
    if entry.memberOf:
        for group_dn in entry.memberOf.values:
            print(f"  - {group_dn}")
    else:
        print("  (none found)")

    conn.unbind()