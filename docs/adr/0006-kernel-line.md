# ADR-0006 — Kernel line, baseline, and patch policy

- **Status:** Proposed (pending owner approval)
- **Date:** 2026-10-30
- **Phase origin:** Phase 0
- **Decision owner:** Project owner (§8 — affects compatibility and maintenance horizon)
- **Confidence:** Verified upstream state (kernel.org/releases.json, 2026-10-30)

## Context

§7 of Project Initiation v2 fixes the policy: «База — upstream Linux LTS. Собственная ветка = минимальный набор патчей поверх LTS + конфигурации по профилям». This ADR pins **which LTS line** is the base, records the version verification, and sets the patch policy.

Project Initiation v2 §6 lists "Ядро: см. раздел 7" as one of the comparison points but does not enumerate alternatives to LTS — there is no real alternative for a source-based distribution that wants long-term CVE backports. The choice is **which LTS line**.

## Upstream verification (2026-10-30)

Retrieved from `https://www.kernel.org/releases.json`:

| Version | Moniker | Released |
|---|---|---|
| 7.3 | mainline | 2026-10-18 |
| 7.2.13 | stable | 2026-10-26 |
| **6.18.59** | **longterm** | **2026-10-26** |
| 6.12.114 | longterm | 2026-10-21 |
| 6.6.160 | longterm | 2026-10-21 |
| 6.1.190 | longterm | 2026-10-15 |
| 5.15.223 | longterm | 2026-10-15 |
| 5.10.272 | longterm | 2026-10-15 |

Active LTS lines as of today: **6.18.y, 6.12.y, 6.6.y, 6.1.y, 5.15.y, 5.10.y** (per kernel.org longterm list).

LFS 13.1-systemd bundles **Linux 7.1.8** for its host kernel default. Our project diverges from that.

## Options considered

| Option | LTS until (approx.) | Newer drivers | Maintenance horizon | Risk on legacy HW |
|---|---|---|---|---|
| **Linux 6.18.y LTS** (latest retired mainline → longterm) | late 2027 / early 2028 | broadest among LTS | shortest remaining | low |
| **Linux 6.12.y LTS** | end of 2027 | slightly fewer than 6.18 | medium | very low |
| **Linux 6.6.y LTS** | end of 2026 | fewer | shortest of the realistic choices | very low — battle-tested |
| **Linux 7.x stable** | N/A — not LTS | newest | none — fast-moving | medium (rapid API churn) |
| **Linux 6.1.y LTS** | end of 2026 | older | shortest | very low — battle-tested |

## Decision

Adopt **Linux 6.18.y LTS** as the project baseline kernel line, pinning **6.18.59** for the first Phase 3 build. Re-pin to the latest 6.18.y patch release at the time each phase begins (Phase 3 entry, Phase 4 entry, Phase 5 entry, etc.). All kernel sources are fetched from `https://cdn.kernel.org/pub/linux/kernel/v6.x/`.

The project kernel branch is named `proj/6.18.y-lts` and starts as a verbatim `v6.18.59` tag. No project patches are added in Phase 0 — Phase 10 will add the first measurable patch.

## Rationale

1. Project Initiation v2 §7 fixes the policy: upstream LTS, minimal patches. The only question is which LTS.
2. 6.18.y is the **most recent LTS line** (kernel.org moniker `longterm`), giving us the newest driver support without going to non-LTS 7.x mainline.
3. 7.x is excluded — it is `mainline`/`stable`, not `longterm`. The project owner wants LTS for CVE backport discipline.
4. Older LTS lines (6.12, 6.6, 6.1) are also valid; we choose 6.18 because newer drivers (especially for newer Intel/AMD Wi-Fi and audio codecs found in "old but not ancient" laptops from 2018–2020) appear in 6.16–6.18 and would otherwise need backporting.
5. Divergence from LFS 13.1-systemd's bundled 7.1.8 is intentional and recorded in `docs/AUDIT_FINDINGS.md` (AUDIT-001).

## Patch policy (per Project Initiation v2 §7)

- Project patch branch `proj/6.18.y-lts` contains **only** patches with: (a) stated problem, (b) affected subsystem, (c) before/after benchmark, (d) maintenance-cost-at-LTS-bump analysis, (e) upstream submission plan.
- No rewrites of scheduler, MM, VFS, or network stack for "own code" reasons.
- Configuration first; sysctl tuning second; patches third — and only with measurable benefit.
- Generic release kernel config: built from the **hardware compatibility matrix** in `TARGET_HARDWARE.md`. `localmodconfig` is forbidden for release builds.
- Stable upstream `v6.18.59` baseline is always kept as a fallback boot entry.

## Consequences

- Positive: predictable maintenance horizon; broad driver support; aligned with §7's policy.
- Negative: every LTS bump requires a rebase of the project patch set (currently empty, so no immediate cost).
- Risks: 6.18.y may EOL during the project's lifetime; revisit triggers below handle this.

## Revisit triggers

- kernel.org retires 6.18.y from longterm → re-pin to the next- LTS line (likely 6.12.y or 7.x-LTS once it exists).
- A target driver is missing from 6.18.y but present in 7.x mainline → consider backport (preferred) or LTS-line bump (if backport is unmaintainable).

## Verification plan

- **Verified (build):** kernel 6.18.59 builds from `linux-6.18.59.tar.xz` with our generic config without errors (Phase 3).
- **Verified (QEMU):** boots to PID 1 systemd; `uname -r` reports `6.18.59` (Phase 3).
- **Verified (hardware):** boots on at least one Legacy, one Standard, one Extended target (Phase 4).

## Source verification (Phase 0)

The kernel tarball URL is reachable:

```
$ curl -sI https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.59.tar.xz
HTTP/2 200
content-type: application/x-xz
```

SHA256 will be computed in `sources.lock` after download (Phase 2). A `.tar.sign` detached PGP signature is published by kernel.org maintainers; verification is part of the Phase 2 download script.
