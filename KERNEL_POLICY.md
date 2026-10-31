# Kernel policy

This document summarizes the project's kernel policy for everyday reference. Authoritative details are in ADR-0006.

## 1. Baseline

- **Upstream Linux 6.18.y LTS** line (kernel.org moniker `longterm`).
- Pinned patch release: **6.18.59** for Phase 3 entry; re-pin to the latest 6.18.y at the start of each subsequent phase.
- Source: `https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-<version>.tar.xz`
- PGP signature: `linux-<version>.tar.sign` (detached, signed by kernel.org release maintainer).

## 2. Project kernel branch

- Branch: `proj/6.18.y-lts`
- Starts as a verbatim `v6.18.59` upstream tag.
- Project patches live on top, each with a metadata header (see §5 below).
- No project patches added in Phase 0–9. First patch lands in Phase 10, behind an experimental config option.

## 3. Configuration rules (per §7 of Project Initiation v2 and §3 of `AI_MASTER_PROMPT.md`)

- **Generic release kernel** built from the hardware compatibility matrix in `TARGET_HARDWARE.md`.
- `localmodconfig` is **forbidden** for release kernels.
- `-march=native` is **forbidden** for release kernel + userspace.
- Profile-specific configs: `config/kernel/legacy.config`, `config/kernel/standard.config`, `config/kernel/extended.config`.
- Verification: `make olddefconfig` (no unrequested changes), `scripts/diffconfig` between versions, QEMU boot test.

## 4. What we do NOT do

- No scheduler rewrites.
- No MM / VFS / network-stack rewrites for "own code" reasons.
- No driver removal based on the build host's loaded modules.
- No disabling of features just because they're unused on the build host.
- No mixing kernel-space and user-space concerns (project tools go in user space).

## 5. Patch metadata (per Phase 10)

Every project patch on `proj/6.18.y-lts` ships with a header containing:

- **Problem** — what is being fixed.
- **Affected subsystem** — scheduler, MM, VFS, net, drivers/..., security/.
- **Upstream status** — submitted / accepted / rejected / not submitted.
- **Risks** — what could go wrong if applied.
- **Rollback procedure** — how to disable at runtime or boot.
- **Benchmark plan** — script path in `bench/` for before/after.
- **Maintenance cost at LTS bump** — estimated rebase effort.

Patches without this header are not accepted into the branch.

## 6. Verification ladder (per Project Initiation v2 §5)

- **Verified (build):** `make` of `config/kernel/standard.config` against `linux-6.18.59.tar.xz` completes with no errors.
- **Verified (QEMU):** kernel boots in `qemu-system-x86_64` to PID 1 systemd; `uname -r` reports `6.18.59`; `dmesg` shows no critical errors.
- **Verified (hardware):** kernel boots on at least one physical device per profile (Legacy / Standard / Extended), with the same `uname -r` and no critical `dmesg` errors.

## 7. CVE and security update policy (per §6 of Project Initiation v2)

- Track CVE feed for `linux-6.18.y` (NVD + kernel.org CVE feed + linux-distros mailing list).
- Adopt upstream stable patch releases within 7 days of publication (for Critical/High CVEs) or 30 days (Medium/Low).
- Backport project patches onto the new LTS patch release; re-run QEMU + at least one hardware smoke test before declaring the new baseline.

## 8. LTS-line bump policy

When kernel.org retires 6.18.y from longterm:

1. Pick the next LTS line as the project baseline (likely 7.x-LTS once it exists, or 6.12.y as a fallback).
2. Rebase `proj/<new>-lts` onto the new tag.
3. Run all Phase 4 hardware tests; document any regression.
4. Update this document and ADR-0006.

## 9. Open questions (Phase 0)

- Which kernel configuration options are too aggressive for the Legacy profile? Decide in Phase 5 after measurement.
- Should we ship `CONFIG_PREEMPT_DYNAMIC=y` so the user can switch preempt model at boot? Likely yes; revisit at Phase 3.
