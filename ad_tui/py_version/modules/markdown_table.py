# ad_tui/py_version/modules/markdown_table.py
# Builds an aligned markdown table from a list of dicts, keys used as headers.

def build(rows):
    if not rows:
        return "(no data)"

    headers = list(rows[0].keys())
    str_rows = [[str(row[h]) for h in headers] for row in rows]

    widths = [max(len(h), max((len(r[i]) for r in str_rows), default=0)) for i, h in enumerate(headers)]

    def format_row(cols):
        return "| " + " | ".join(col.ljust(widths[i]) for i, col in enumerate(cols)) + " |"

    lines = [format_row(headers)]
    lines.append("|-" + "-|-".join("-" * w for w in widths) + "-|")
    lines += [format_row(r) for r in str_rows]

    return "\n".join(lines)