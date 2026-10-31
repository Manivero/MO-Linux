#!/usr/bin/env python3
"""scripts/sources-verify.py — verify every URL in sources.lock is reachable.

Reads the sources.lock file, extracts every URL field, and performs an HTTP
HEAD request against each. Reports a per-URL status line and a summary.

Per Project Initiation v2 §11: do not imitate results. If a URL is
unreachable, say so.

Usage:
    python3 scripts/sources-verify.py [path/to/sources.lock]
"""

from __future__ import annotations
import os
import re
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone


URL_RE = re.compile(r'url\s*=\s*"([^"]+)"')
NAME_RE = re.compile(r'name\s*=\s*"([^"]+)"')


def main(lock_path: str) -> int:
    if not os.path.exists(lock_path):
        print(f"FATAL: {lock_path} does not exist", file=sys.stderr)
        return 2

    with open(lock_path, "r", encoding="utf-8") as f:
        text = f.read()

    # Walk the file and pair (name, url) entries.
    # Both name and url may appear on the same line (inline entries), so do
    # NOT skip the URL search after finding a name.
    entries: list[tuple[str, str]] = []
    last_name = "<unknown>"
    for line in text.splitlines():
        m = NAME_RE.search(line)
        if m:
            last_name = m.group(1)
        m = URL_RE.search(line)
        if m:
            entries.append((last_name, m.group(1)))

    print(f"# sources-verify run at {datetime.now(timezone.utc).isoformat()}")
    print(f"# entries: {len(entries)}")
    print()
    print(f"{'NAME':<30} {'STATUS':<10} URL")
    print(f"{'-'*30} {'-'*10} ---")

    ok = 0
    fail = 0
    skip = 0
    for name, url in entries:
        if "UNVERIFIED" in url:
            skip += 1
            print(f"{name:<30} {'SKIP':<10} {url}  (UNVERIFIED placeholder)")
            continue
        try:
            req = urllib.request.Request(url, method="HEAD",
                                         headers={"User-Agent": "sources-verify/1.0"})
            with urllib.request.urlopen(req, timeout=15) as resp:
                code = resp.status
                if 200 <= code < 400:
                    print(f"{name:<30} {'OK':<10} {url}  ({code})")
                    ok += 1
                else:
                    print(f"{name:<30} {'FAIL':<10} {url}  (HTTP {code})")
                    fail += 1
        except urllib.error.HTTPError as e:
            print(f"{name:<30} {'FAIL':<10} {url}  (HTTP {e.code})")
            fail += 1
        except (urllib.error.URLError, TimeoutError, ConnectionError, OSError) as e:
            print(f"{name:<30} {'FAIL':<10} {url}  ({type(e).__name__}: {e})")
            fail += 1

    print()
    print(f"Summary: {ok} OK, {fail} FAIL, {skip} SKIPPED (placeholder)")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    lock = sys.argv[1] if len(sys.argv) > 1 else "sources.lock"
    sys.exit(main(lock))
