# ADR-0007 — Package manager

- **Status:** **Deferred — no decision made.** Decision gate per Project Initiation v2 §6 and §8.
- **Date:** 2026-10-30
- **Phase origin:** Phase 0 (this ADR records the gate) → resolution at Phase 7 entry.
- **Decision owner:** Project owner (§8 — explicitly owner-controlled)
- **Confidence:** N/A (deferred)

## Context

Project Initiation v2 §6: «Менеджер пакетов: разработка с нуля vs адаптация существующего (форматы, зависимости, транзакции, откат, подпись). Это гейт решения (раздел 8): сначала требования и сравнение, потом реализация».

§8: «Спрашивай меня до действия: выбор ключевой технологии, влияющей на продукт (init, libc, пакетный менеджер, DE, схема обновлений)».

`AI_MASTER_PROMPT.md` §4 says "eventually a project-owned package manager/repository" and `IMPLEMENTATION_ROADMAP.md` Phase 7 says "Use Rust for the package-manager implementation". **These pre-decisions are recorded here as assumptions to challenge, not as accepted baselines.** AUDIT-003 captures the contradiction.

## Requirements (must be met by any candidate)

Derived from §2 priority order and §6 criteria:

1. **Update reliability (§2 #1).** An interrupted update must not brick the system. Transactional install with staged commit, atomic rename, or A/B-style rollback.
2. **Security.** Signed repository metadata; payload hash verification; key rotation/revocation policy; no execution of arbitrary privileged scripts from untrusted packages.
3. **RAM footprint (§2 #3).** Idle memory cost of running the package manager background (if any) must be minimal; the on-disk database must be small for the Legacy profile.
4. **Dependency resolution.** Correct SAT-class or topological dependency resolver with cycle detection and conflict reporting.
5. **Offline operation.** Must work fully offline for install/remove/query against a pre-downloaded repository.
6. **Reproducibility (§2 #7).** Build recipes pinned in `sources.lock`; a package rebuild must produce a bit-identical result given identical inputs and `SOURCE_DATE_EPOCH`.
7. **License compatibility.** Manager license must permit redistribution alongside the distribution; package metadata must include license and source-URL fields (GPL offer compliance).
8. **Auditability.** Small, readable codebase. Reviewer can understand the entire install path.
9. **No host modification during development.** The manager is tested only against disposable target rootfs images (per §7 of `AI_MASTER_PROMPT.md` and §9 of Project Initiation v2).

## Options to be compared at Phase 7 entry

| Option | Origin | License | Language | Transaction story | Notes |
|---|---|---|---|---|---|
| Build-from-scratch (Rust) | project | TBD (likely MIT/Apache-2.0) | Rust | we design it | matches kit's hint; highest code-maintenance cost; full control |
| Build-from-scratch (C) | project | TBD | C | we design it | smaller toolchain dependency than Rust; harder safety story |
| **apk-tools** | Alpine | GPL-2.0 | C (3.x) / Rust (experimental) | atomic via `apk add --no-scripts` + overlay | mature, very small, designed for atomic installs |
| **opkg** | OpenWrt | GPL-2.0 | C | simple, no native transaction | small footprint, but no atomic install |
| **dpkg + apt** | Debian | GPL family | C | dpkg has unpack-then-configure, not atomic | large, mature, heavy dependency set |
| **pacman** | Arch | GPL-2.0 | C | non-atomic but simple | small, simple, no signature-first design |
| **dnf / rpm** | Fedora | GPL family | C / Python | RPM has transaction support | heavy dependency set, ill-suited to Legacy |

This list is **not** the Phase 7 decision; it is the candidate set that Phase 7 will evaluate.

## Decision

**No decision.** This ADR exists to:

1. Record that the decision is a gate (per §6 and §8).
2. Capture the requirements the chosen solution must satisfy.
3. List the candidate set.
4. Override the kit's implicit pre-decision (Rust from-scratch) by recording it as one candidate among several.

Phase 7 entry will produce ADR-0007-rev1 with the chosen option, the comparison table, and the verification plan.

## Rationale

A premature decision would lock in a solution before the requirements (especially transaction atomicity and signature story) are measured against the target hardware. Project Initiation v2 §6 is explicit: requirements first, comparison second, implementation third.

## Consequences

- Phase 0–6 proceed without a package manager. The system is configured via LFS/BLFS manual build steps; the "package database" is a set of text manifests.
- A `PACKAGE_FORMAT.md` document will be written at Phase 7 entry, before the manager.
- Source code and package-format design work that depends on a specific package manager is forbidden before this ADR is revised.

## Revisit triggers

This ADR is **automatically reopened at Phase 7 entry**. No additional trigger is required.

## Verification plan

N/A — the decision is deferred. Verification happens against ADR-0007-rev1 at Phase 7.
