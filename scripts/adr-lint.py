#!/usr/bin/env python3
"""scripts/adr-lint.py — sanity-check ADR files for required sections."""

from __future__ import annotations
import os
import re
import sys

NAME_RE = re.compile(r"^(ADR-)?(\d{4})-[\w-]+\.md$")
ALLOWED_STATUS = {"Proposed", "Accepted", "Superseded by ADR-XXXX",
                   "Deprecated", "Deferred", "Deferred — no decision made."}
# Required top-level section headers. For deferred-decision ADRs
# (Status starts with "Deferred"), we accept "## Options" or
# "## Options to be compared" in place of "## Options considered".
REQUIRED_SECTIONS = [
    "## Context",
    "## Decision",
    "## Rationale",
    "## Consequences",
    "## Revisit triggers",
    "## Verification plan",
]
# Plus one of the following "Options" headers:
OPTIONS_HEADERS = (
    "## Options considered",
    "## Options to be compared",
    "## Options",
)


def lint_file(path: str) -> list[str]:
    issues: list[str] = []
    fname = os.path.basename(path)
    if fname == "0000-template.md":
        return issues
    if not NAME_RE.match(fname):
        issues.append(f"name does not match ADR-NNNN-slug.md: {fname}")

    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    status_match = re.search(r"^\- \*\*Status:\*\*\s*(.+?)\s*$", text, re.MULTILINE)
    if not status_match:
        issues.append("missing or malformed Status line")
    else:
        status_value = status_match.group(1).split("(")[0].strip().rstrip(".")
        prefix_ok = any(status_value.startswith(s) for s in ALLOWED_STATUS)
        if not prefix_ok and "Deferred" not in status_value:
            issues.append(f"Status '{status_value}' not in allowed set: {ALLOWED_STATUS}")

    for header in REQUIRED_SECTIONS:
        if header not in text:
            issues.append(f"missing required section: {header}")
    if not any(h in text for h in OPTIONS_HEADERS):
        issues.append(f"missing any of: {OPTIONS_HEADERS}")
    return issues


def main(adr_dir: str) -> int:
    if not os.path.isdir(adr_dir):
        print(f"FATAL: {adr_dir} is not a directory", file=sys.stderr)
        return 2

    files = sorted(f for f in os.listdir(adr_dir)
                   if f.endswith(".md") and f != "0000-template.md")
    if not files:
        print("No ADR files found.")
        return 1

    total_issues = 0
    for fname in files:
        path = os.path.join(adr_dir, fname)
        issues = lint_file(path)
        if not issues:
            print(f"  OK  {fname}")
        else:
            print(f"  FAIL {fname}")
            for i in issues:
                print(f"        - {i}")
            total_issues += len(issues)

    print()
    print(f"Summary: {len(files)} files, {total_issues} issues")
    return 0 if total_issues == 0 else 1


if __name__ == "__main__":
    adr_dir = sys.argv[1] if len(sys.argv) > 1 else "docs/adr"
    sys.exit(main(adr_dir))
