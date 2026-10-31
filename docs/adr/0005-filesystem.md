# ADR-0005 — Root filesystem

- **Status:** Proposed (pending owner approval)
- **Date:** 2026-10-30
- **Phase origin:** Phase 0
- **Decision owner:** Project owner (§8 — affects update reliability)
- **Confidence:** Hypothesis

## Context

§6 of Project Initiation v2 requires «ext4 vs XFS vs Btrfs — HDD/SSD, надёжность, снапшоты для отката». §2 priority #1 is **reliability and safety of updates** — the system must not be "bricked". Snapshot-based rollback is therefore a primary criterion, not a nice-to-have. But snapshot support is not free, and Btrfs has known issues on legacy kernels / SMR HDDs.

## Options considered

| Option | Snapshot/rollback | Metadata checksum | HDD behaviour | SSD/NVMe trim | Code maturity on legacy kernel |
|---|---|---|---|---|---|
| **ext4** | no native (needs LVM or A/B partition scheme) | metadata_csum default since 4.x | good | `fstrim.timer` | mature, no concerns |
| **XFS** | no native (reflink snapshots since 5.x but only on certain configs) | metadata checksum since 4.x | good | `fstrim.timer` | mature |
| **Btrfs** | native (subvolume + snapshot) | full (data + metadata) | variable; SMR drives problematic | `fstrim.timer` (with caveats) | mostly mature on 6.x LTS; some corner cases |

ext4 + an A/B partition scheme (two root partitions, alternate updates) gives us rollback without depending on Btrfs's more complex failure modes. ext4 + LVM snapshots is an alternative but adds LVM userspace.

## Decision

Adopt **ext4** as the root filesystem for the first release. Rollback is delivered via an **A/B partition scheme** (Phase 8 design), not via Btrfs snapshots. XFS and Btrfs are explicitly deferred and may be revisited as part of Phase 8 (rollback strategy).

Pin: ext4 default mount options — `defaults,noatime,errors=remount-ro`.

## Rationale

1. Reliability of updates (§2 #1) is the dominant priority. A/B partitions give atomic-rollback semantics with ext4 — the failure mode is "reboot into the previous slot", not "fsck a corrupted Btrfs snapshot".
2. Hardware compatibility (§2 #4): Btrfs has documented problems on SMR HDDs common in pre-2015 laptops. ext4 has none.
3. Performance (§2 #2): ext4 is faster than Btrfs on small random writes typical of desktop workloads.
4. Maintenance: ext4 is the LFS default; zero extra configuration work for the first release.

## Consequences

- Positive: predictable behavior; broadest compatibility; simplest recovery story.
- Negative: no native snapshots — rollback requires A/B partition layout. The installer (Phase 9) must create two root partitions, which is more complex than a single partition.
- Risks: A/B layout doubles the root partition size budget; Legacy profile with 80 GB HDD loses ~20–40 GB to the inactive slot. Mitigated by allowing Legacy profile to use a single partition with LVM snapshots as a degraded mode.

## Revisit triggers

- Phase 5 measurement shows A/B layout consumes too much of the Legacy profile's disk.
- A critical Btrfs bug on legacy hardware is fixed and snapshot-rollback becomes the simpler design.
- Owner requests native snapshots as a user-visible feature.

## Verification plan

- **Verified (build):** mkfs.ext4 with default options on a loopback file produces a fsck-clean filesystem (Phase 2 sandbox).
- **Verified (QEMU):** boot from an ext4 root partition; remount read-only and back to read-write without errors (Phase 3).
- **Verified (hardware):** at least one Legacy HDD target boots reliably across 50 reboot cycles (Phase 5 / Phase 8).
