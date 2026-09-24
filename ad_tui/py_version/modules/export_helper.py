# ad_tui/py_version/modules/export_helper.py
# Prompts whether/how to export tabular data (list of dicts) to file: .txt (markdown table), .csv, both, or skip.

import csv
from pathlib import Path
import questionary
from modules import markdown_table
from modules import session

def prompt_and_export(rows, filename_base):
    if not rows:
        print("Nothing to export.")
        return

    choice = questionary.select(
        "Export results?",
        choices=[".txt (markdown table)", ".csv", "Both", "No"]
    ).ask()

    if choice == "No" or choice is None:
        return

    export_dir = Path(session.get_export_path())

    if choice in (".txt (markdown table)", "Both"):
        txt_path = export_dir / f"{filename_base}.txt"
        with open(txt_path, "w", encoding="utf-8") as f:
            f.write(markdown_table.build(rows))
        print(f"Saved: {txt_path}")

    if choice in (".csv", "Both"):
        csv_path = export_dir / f"{filename_base}.csv"
        with open(csv_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            writer.writeheader()
            writer.writerows(rows)
        print(f"Saved: {csv_path}")