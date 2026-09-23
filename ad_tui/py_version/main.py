# ad_tui/py_version/main.py
# Menu skeleton only - checks dependencies, then imports and calls each feature module.

from modules import ensure_dependencies
ensure_dependencies.run()

import questionary
from modules import title, ping

def main():
    title.show()
    while True:
        choice = questionary.select(
            "AD TUI",
            choices=["Ping", "Exit"]
        ).ask()

        if choice == "Ping":
            ping.run()
        elif choice == "Exit" or choice is None:
            break

if __name__ == "__main__":
    main()