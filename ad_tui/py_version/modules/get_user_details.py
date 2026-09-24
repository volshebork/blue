# ad_tui/py_version/modules/get_user_details.py
# Queries a specific SamAccountName in AD and reports status, group membership, and key attributes.
# Offers export to .txt (markdown) and/or .csv.

from ldap3 import Server, Connection, ALL, NTLM
import questionary
from modules import session
from modules import markdown_table
from modules import export_helper

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

    # Extract just the group CN from each full group DN, for a cleaner display/export
    groups = []
    if entry.memberOf:
        for group_dn in entry.memberOf.values:
            cn = group_dn.split(",")[0].replace("CN=", "")
            groups.append(cn)

    row = {
        "SamAccountName": entry.sAMAccountName.value,
        "Enabled": enabled,
        "Created": str(entry.whenCreated.value) if entry.whenCreated else "N/A",
        "PwdLastSet": str(entry.pwdLastSet.value) if entry.pwdLastSet else "N/A",
        "LastLogon": str(entry.lastLogonTimestamp.value) if entry.lastLogonTimestamp else "N/A",
        "AdminCount": entry.adminCount.value if entry.adminCount else 0,
        "AccountExpires": str(entry.accountExpires.value) if entry.accountExpires else "N/A",
        "Description": entry.description.value if entry.description else "N/A",
        "Groups": "; ".join(groups) if groups else "(none)",
    }

    conn.unbind()

    print(markdown_table.build([row]))
    export_helper.prompt_and_export([row], f"user_details_{target_user}")