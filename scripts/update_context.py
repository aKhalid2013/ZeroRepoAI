#!/usr/bin/env python3
"""Helper to update docs/CONTEXT_MANAGER.md status and change log."""

import argparse
import datetime
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
CONTEXT_PATH = ROOT / "docs" / "CONTEXT_MANAGER.md"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Update context manager status and step")
    parser.add_argument("--status", required=True, help="New status value")
    parser.add_argument("--step", required=True, help="New current step")
    return parser.parse_args()


def update_current_feature(lines: list[str], status: str, step: str) -> None:
    mappings = {"Status": status, "Current Step": step}
    for label, value in mappings.items():
        replacement = f"| **{label}** | {value} |"
        for idx, line in enumerate(lines):
            if line.startswith(f"| **{label}** |"):
                lines[idx] = replacement
                break
        else:
            raise ValueError(f"Could not find row for '{label}' in Current Feature Progress table")


def append_change_log(lines: list[str], status: str, step: str) -> None:
    marker = "## Change Log"
    try:
        marker_index = lines.index(marker)
    except ValueError as exc:
        raise ValueError("Could not find Change Log section") from exc

    # Find the start of the table rows after the header separator
    table_start = None
    for idx in range(marker_index + 1, len(lines)):
        if lines[idx].strip().startswith("| ---"):
            table_start = idx
            break
    if table_start is None:
        raise ValueError("Change Log table header not found")

    insert_at = table_start + 1
    for idx in range(table_start + 1, len(lines)):
        if lines[idx].startswith("|"):
            insert_at = idx + 1
        else:
            break

    today = datetime.date.today().strftime("%Y-%m-%d")
    summary = f"Updated status to {status} and step to {step}"
    new_row = f"| {today} | _context_update_ | {summary} |"

    lines.insert(insert_at, new_row)


def main() -> int:
    args = parse_args()

    if not CONTEXT_PATH.exists():
        print(f"Context manager file not found: {CONTEXT_PATH}", file=sys.stderr)
        return 1

    content = CONTEXT_PATH.read_text(encoding="utf-8").splitlines()

    try:
        update_current_feature(content, args.status, args.step)
        append_change_log(content, args.status, args.step)
    except ValueError as exc:
        print(f"Error updating context: {exc}", file=sys.stderr)
        return 1

    CONTEXT_PATH.write_text("\n".join(content) + "\n", encoding="utf-8")
    print("Updated docs/CONTEXT_MANAGER.md with new status and step.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
