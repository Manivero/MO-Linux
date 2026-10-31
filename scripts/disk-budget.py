#!/usr/bin/env python3
"""scripts/disk-budget.py — disk budget table for A/B vs single-root vs image-based layouts.

Recreated 2026-10-31 after sandbox recycle.
Referenced from ADR-0008 §4.10. Produces deterministic plain-text output that
can be diffed across revisions. Numbers are ESTIMATES derived from typical LFS
component sizes; they will be replaced by measurements in Phase 5/8.

Usage:
    python3 scripts/disk-budget.py
    python3 scripts/disk-budget.py --json   # machine-readable

Exit codes: 0 = OK; 2 = bad args.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass
from typing import List


# ---------------------------------------------------------------------------
# Constants — keep in sync with ADR-0008 §4.4 and §4.9.4
# ---------------------------------------------------------------------------

# Per-slot root sizes (GB)
SLOT_CLI_MIN = 2.5
SLOT_DESKTOP_MIN = 8.0       # LFS + Xfce, no headroom (matches ADR-0008 §4.4)
SLOT_DESKTOP_RECOMMENDED = 12.0
SLOT_DESKTOP_LARGE = 15.0

# Fixed overhead (GB), separate from slots
ESP_UEFI = 0.5
BOOT_SHARED = 1.0
SWAP_LEGACY = 2.0   # = 2 GB RAM for hibernate
SWAP_STD = 4.0
SWAP_EXT = 8.0

RECOVERY_PARTITION = 3.0   # base image + tools, read-only (op C)
IMAGE_CACHE = 6.0         # 2 image versions × 3 GB squashfs (op E)

DISK_SIZES_GB = [32, 64, 128, 256]


@dataclass
class LayoutResult:
    disk_gb: float
    layout_name: str
    slot_size_gb: float
    n_slots: int
    fixed_overhead_gb: float
    home_avail_gb: float
    verdict: str


def _verdict(home_avail: float) -> str:
    """Verdict thresholds — kept in sync with ADR-0008 §4.10.1 tables."""
    if home_avail < 15:
        return "UNACCEPTABLE"
    if home_avail < 30:
        return "TIGHT"
    if home_avail < 50:
        return "WORKABLE"
    return "COMFORTABLE"


def layout_ab(disk_gb: float, slot_size: float, *,
              bios_only: bool = True) -> LayoutResult:
    n_slots = 2
    fixed = BOOT_SHARED + SWAP_LEGACY
    if not bios_only:
        fixed += ESP_UEFI
    slots = n_slots * slot_size
    home = disk_gb - slots - fixed
    return LayoutResult(
        disk_gb=disk_gb,
        layout_name="A/B partitions (ext4)",
        slot_size_gb=slot_size,
        n_slots=n_slots,
        fixed_overhead_gb=fixed,
        home_avail_gb=home,
        verdict=_verdict(home),
    )


def layout_single_root_recovery(disk_gb: float,
                                root_size: float = SLOT_DESKTOP_RECOMMENDED,
                                *, bios_only: bool = True) -> LayoutResult:
    n_slots = 1
    fixed = BOOT_SHARED + SWAP_LEGACY + RECOVERY_PARTITION
    if not bios_only:
        fixed += ESP_UEFI
    home = disk_gb - root_size - fixed
    return LayoutResult(
        disk_gb=disk_gb,
        layout_name="Single-root + recovery",
        slot_size_gb=root_size,
        n_slots=n_slots,
        fixed_overhead_gb=fixed,
        home_avail_gb=home,
        verdict=_verdict(home),
    )


def layout_image_based(disk_gb: float, *,
                       bios_only: bool = True) -> LayoutResult:
    n_slots = 1
    root = 3.0   # squashfs image, mounted read-only
    fixed = BOOT_SHARED + SWAP_LEGACY + IMAGE_CACHE
    if not bios_only:
        fixed += ESP_UEFI
    home = disk_gb - root - fixed
    return LayoutResult(
        disk_gb=disk_gb,
        layout_name="Image-based (squashfs+overlay)",
        slot_size_gb=root,
        n_slots=n_slots,
        fixed_overhead_gb=fixed,
        home_avail_gb=home,
        verdict=_verdict(home),
    )


def render_table(rows: List[LayoutResult]) -> str:
    lines = []
    header = (
        f"{'Disk GB':<8} {'Layout':<32} {'Slot GB':<8} "
        f"{'nSlots':<7} {'Fixed GB':<10} {'/home GB':<10} {'Verdict':<14}"
    )
    lines.append(header)
    lines.append("-" * len(header))
    for r in rows:
        lines.append(
            f"{int(r.disk_gb):<8} {r.layout_name:<32} "
            f"{r.slot_size_gb:<8.1f} {r.n_slots:<7d} "
            f"{r.fixed_overhead_gb:<10.1f} {r.home_avail_gb:<10.1f} "
            f"{r.verdict:<14}"
        )
    return "\n".join(lines)


def build_full_table() -> List[LayoutResult]:
    rows: List[LayoutResult] = []
    for disk in DISK_SIZES_GB:
        rows.append(layout_ab(disk, SLOT_DESKTOP_RECOMMENDED, bios_only=True))
    for disk in DISK_SIZES_GB:
        rows.append(layout_ab(disk, SLOT_DESKTOP_MIN, bios_only=True))
    for disk in DISK_SIZES_GB:
        rows.append(layout_single_root_recovery(disk, bios_only=True))
    for disk in DISK_SIZES_GB:
        rows.append(layout_image_based(disk, bios_only=True))
    return rows


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true",
                        help="emit JSON instead of plain text")
    args = parser.parse_args(argv)

    rows = build_full_table()

    if args.json:
        print(json.dumps([asdict(r) for r in rows], indent=2))
        return 0

    print("=== A/B partitions (ext4), slot = 12 GB (recommended) ===")
    print(render_table(rows[0:4]))
    print()
    print("=== A/B partitions (ext4), slot = 8 GB (minimum) ===")
    print(render_table(rows[4:8]))
    print()
    print("=== Single-root + recovery partition (op C) ===")
    print(render_table(rows[8:12]))
    print()
    print("=== Image-based (squashfs + overlay, op E) ===")
    print(render_table(rows[12:16]))
    print()
    print("Notes:")
    print("  - Numbers are estimates; verified by Phase 5/8 measurements.")
    print("  - BIOS-only Legacy target assumed; add 0.5 GB ESP for UEFI.")
    print("  - swap = 2 GB (= Legacy RAM target); Standard 4 GB, Extended 8 GB.")
    print("  - /home verdict thresholds: <15 UNACCEPTABLE, <30 TIGHT, "
          "<50 WORKABLE, >=50 COMFORTABLE.")
    print("  - 64 GB threshold NOT approved by owner (decision 2026-10-31); "
          "use real measured rootfs size after Phase 2 (ADR-0008 gate G6).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
