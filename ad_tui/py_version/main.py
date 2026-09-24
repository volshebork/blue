# ad_tui/py_version/main.py
# Menu skeleton - checks dependencies, sets up session, then presents a submenu structure calling each feature module.

from modules import ensure_dependencies
ensure_dependencies.run()

import questionary
from modules import title, ping, session, get_user_details, enumerate_privileged_groups

def session_menu():
    while True:
        choice = questionary.select(
            "Session",
            choices=["See Session Details", "Change Session Details", "Set Export Path", "Back to Main Menu"]
        ).ask()

        if choice == "See Session Details":
            session.show_session_details()
        elif choice == "Change Session Details":
            session.prompt_for_session()
        elif choice == "Set Export Path":
            session.set_export_path()
        elif choice == "Back to Main Menu" or choice is None:
            break

def queries_menu():
    while True:
        choice = questionary.select(
            "Queries",
            choices=["Get User Details", "Enumerate Privileged Groups", "Ping", "Back to Main Menu"]
        ).ask()

        if choice == "Get User Details":
            get_user_details.run()
        elif choice == "Enumerate Privileged Groups":
            enumerate_privileged_groups.run()
        elif choice == "Ping":
            ping.run()
        elif choice == "Back to Main Menu" or choice is None:
            break

def actions_menu():
    while True:
        choice = questionary.select(
            "Actions",
            choices=["Back to Main Menu"]
        ).ask()

        if choice == "Back to Main Menu" or choice is None:
            break

def main():
    title.show()
    session.prompt_for_session()

    while True:
        choice = questionary.select(
            "AD TUI",
            choices=["Session", "Queries", "Actions", "Exit"]
        ).ask()

        if choice == "Session":
            session_menu()
        elif choice == "Queries":
            queries_menu()
        elif choice == "Actions":
            actions_menu()
        elif choice == "Exit" or choice is None:
            break

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nExiting.")