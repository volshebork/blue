# ad_tui/py_version/modules/remove_list_of_users_from_privileged_groups.py
# Removes users listed in a text file from all privileged AD groups
# (Domain Admins, Enterprise Admins, Schema Admins, Account Operators, Backup Operators, DnsAdmins).
# Reports per-user, per-group results as a markdown table. Offers export.

from ldap3 import Server, Connection, ALL, NTLM, MODIFY_DELETE
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
]

def _read_usernames(list_path):
    try:
        with open(list_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"File not found: {list_path}")
        return None

    usernames = [
        line.strip() for line in lines
        if line.strip() and not line.strip().startswith("#")
    ]
    return usernames

def run():
    dc_host, base_dn, username, password = session.get_connection_info()

    if not all([dc_host, base_dn, username, password]):
        print("Session details are not fully set. Use 'Set Session Details' first.")
        return

    list_path = session.get_user_list_path()
    usernames = _read_usernames(list_path)
    if not usernames:
        print("No usernames to process.")
        return

    print(f"About to remove {len(usernames)} account(s) from all privileged groups:")
    for u in usernames:
        print(f"  - {u}")
    confirm = input("Type YES to proceed: ")
    if confirm != "YES":
        print("Aborted.")
        return

    server = Server(dc_host, get_info=ALL)
    conn = Connection(server, user=username, password=password, authentication=NTLM, auto_bind=True)

    # Resolve each group's DN once up front
    group_dns = {}
    for group in GROUPS:
        conn.search(base_dn, f"(&(objectClass=group)(cn={group}))", attributes=["distinguishedName"])
        if conn.entries:
            group_dns[group] = conn.entries[0].distinguishedName.value

    rows = []
    for target_user in usernames:
        # Resolve the user's DN
        conn.search(base_dn, f"(sAMAccountName={target_user})", attributes=["distinguishedName"])
        if not conn.entries:
            rows.append({"Username": target_user, "Group": "(all)", "Result": "User not found"})
            continue
        user_dn = conn.entries[0].distinguishedName.value

        for group, group_dn in group_dns.items():
            success = conn.modify(group_dn, {"member": [(MODIFY_DELETE, [user_dn])]})
            if success:
                rows.append({"Username": target_user, "Group": group, "Result": "Removed"})
            else:
                result_desc = conn.result.get("description", "unknown error")
                if result_desc == "noSuchAttribute":
                    rows.append({"Username": target_user, "Group": group, "Result": "Not a member"})
                else:
                    rows.append({"Username": target_user, "Group": group, "Result": f"FAILED: {result_desc}"})

    conn.unbind()

    print(markdown_table.build(rows))
    export_helper.prompt_and_export(rows, "remove_privileged_groups_results")