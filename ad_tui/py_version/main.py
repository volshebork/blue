# ad_tui/py_version/main.py
# Menu skeleton only - checks dependencies, sets up session, then imports and calls each feature module.

from modules import ensure_dependencies
ensure_dependencies.run()

import questionary
from modules import title, ping, session, get_user_details

def main():
    title.show()
    session.prompt_for_session()

    while True:
        choice = questionary.select(
            "AD TUI",
            choices=["Ping", "See Session Details", "Change Session Details", "Get User Details", "Exit"]
        ).ask()

        if choice == "Ping":
            ping.run()
        elif choice == "See Session Details":
            session.show_session_details()
        elif choice == "Change Session Details":
            session.prompt_for_session()
        elif choice == "Get User Details":
            get_user_details.run()
        elif choice == "Exit" or choice is None:
            break

if __name__ == "__main__":
    main()