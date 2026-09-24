# ad_tui/py_version/modules/enumerate_privileged_groups.py
# Enumerates privileged AD groups (including nested membership) and reports member accounts as a markdown table.
# Offers export to .txt (markdown) and/or .csv.

from ldap3 import Server, Connection, ALL, NTLM
from modules import session
from modules import markdown_table
from modules import export_helper

GROUPS = [
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Account Operators",
    "Backup Operators",
    "DnsAdmins",
    "Administrators",
    "Remote Desktop Users",
]

ACCOUNTDISABLE = 0x2
LDAP_MATCHING_RULE_IN_CHAIN = "1.2.840.113556.1.4.1941"

def run():
    dc_host, base_dn, username, password = session.get_connection_info()

    if not all([dc_host, base_dn, username, password]):
        print("Session details are not fully set. Use 'Set Session Details' first.")
        return

    server = Server(dc_host, get_info=ALL)
    conn = Connection(server, user=username, password=password, authentication=NTLM, auto_bind=True)

    rows = []
    for group in GROUPS:
        # Find the group's DN first
        conn.search(base_dn, f"(&(objectClass=group)(cn={group}))", attributes=["distinguishedName"])
        if not conn.entries:
            continue
        group_dn = conn.entries[0].distinguishedName.value

        # Recursive membership search: every user whose membership chain includes this group DN
        conn.search(
            base_dn,
            f"(&(objectClass=user)(memberOf:{LDAP_MATCHING_RULE_IN_CHAIN}:={group_dn}))",
            attributes=["sAMAccountName", "userAccountControl", "whenCreated", "pwdLastSet"]
        )

        for entry in conn.entries:
            uac = int(entry.userAccountControl.value) if entry.userAccountControl else 0
            enabled = not bool(uac & ACCOUNTDISABLE)

            rows.append({
                "Group": group,
                "SamAccountName": entry.sAMAccountName.value,
                "Enabled": enabled,
                "Created": str(entry.whenCreated.value) if entry.whenCreated else "N/A",
                "PwdLastSet": str(entry.pwdLastSet.value) if entry.pwdLastSet else "N/A",
            })

    conn.unbind()

    print(markdown_table.build(rows))
    export_helper.prompt_and_export(rows, "privileged_groups_export")