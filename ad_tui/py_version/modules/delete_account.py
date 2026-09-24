# ad_tui/py_version/modules/delete_account.py
# Deletes a single AD user account by SamAccountName, after confirmation.

from ldap3 import Server, Connection, ALL, NTLM
import questionary
from modules import session

def run():
    dc_host, base_dn, username, password = session.get_connection_info()

    if not all([dc_host, base_dn, username, password]):
        print("Session details are not fully set. Use 'Set Session Details' first.")
        return

    target_user = questionary.text("Enter the SamAccountName to delete:").ask()
    if not target_user:
        return

    server = Server(dc_host, get_info=ALL)
    conn = Connection(server, user=username, password=password, authentication=NTLM, auto_bind=True)

    conn.search(base_dn, f"(sAMAccountName={target_user})", attributes=["distinguishedName"])
    if not conn.entries:
        print(f"No account found for {target_user}")
        conn.unbind()
        return

    user_dn = conn.entries[0].distinguishedName.value

    print(f"About to permanently delete account: {target_user}")
    print(f"  DN: {user_dn}")
    print("This is destructive and cannot be undone. Disabling is usually the correct")
    print("IR action instead of deletion - it preserves the account, SID, group")
    print("memberships, and audit trail for forensics.")
    confirm = input("Type DELETE to proceed: ")

    if confirm != "DELETE":
        print("Aborted.")
        conn.unbind()
        return

    success = conn.delete(user_dn)
    if success:
        print(f"Deleted: {target_user}")
    else:
        result_desc = conn.result.get("description", "unknown error")
        print(f"FAILED: {result_desc}")

    conn.unbind()