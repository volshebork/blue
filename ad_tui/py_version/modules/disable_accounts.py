# ad_tui/py_version/modules/disable_list_of_accounts.py
# Disables users listed in a text file by flipping the ACCOUNTDISABLE bit in userAccountControl.
# Reports per-user results as a markdown table. Offers export.

from ldap3 import Server, Connection, ALL, NTLM, MODIFY_REPLACE
from modules import session
from modules import markdown_table
from modules import export_helper

ACCOUNTDISABLE = 0x2

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

    print(f"About to disable {len(usernames)} account(s):")
    for u in usernames:
        print(f"  - {u}")
    confirm = input("Type YES to proceed: ")
    if confirm != "YES":
        print("Aborted.")
        return

    server = Server(dc_host, get_info=ALL)
    conn = Connection(server, user=username, password=password, authentication=NTLM, auto_bind=True)

    rows = []
    for target_user in usernames:
        conn.search(base_dn, f"(sAMAccountName={target_user})", attributes=["distinguishedName", "userAccountControl"])
        if not conn.entries:
            rows.append({"Username": target_user, "Result": "User not found"})
            continue

        entry = conn.entries[0]
        user_dn = entry.distinguishedName.value
        current_uac = int(entry.userAccountControl.value)
        new_uac = current_uac | ACCOUNTDISABLE

        success = conn.modify(user_dn, {"userAccountControl": [(MODIFY_REPLACE, [new_uac])]})
        if success:
            rows.append({"Username": target_user, "Result": "Disabled"})
        else:
            result_desc = conn.result.get("description", "unknown error")
            rows.append({"Username": target_user, "Result": f"FAILED: {result_desc}"})

    conn.unbind()

    print(markdown_table.build(rows))
    export_helper.prompt_and_export(rows, "disable_accounts_results")