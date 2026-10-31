# Audit findings — Phase 0

The audit compares the four starter documents in `docs/reference/` (AI_MASTER_PROMPT.md, IMPLEMENTATION_ROADMAP.md, PHASE_PROMPTS.md, PROJECT_STATUS_TEMPLATE.md, START_HERE_RU.md — the "kit") with the project owner's authoritative **Project Initiation v2** specification, and with the actual upstream state of LFS 13.1-systemd and the Linux LTS kernel line as of 2026-10-30.

Each finding follows the format required by §13 of Project Initiation v2:

```
ID / priority
  Problem (file / section)
  Proposed fix
  Rationale
  Impact (performance, compatibility, security)
  Risks and cost
  Owner decision needed?
```

## AUDIT-001 — High

**Problem.** `AI_MASTER_PROMPT.md` §4 pins the project baseline kernel to "upstream Linux 6.18.y LTS line" and `IMPLEMENTATION_ROADMAP.md` Phase 3 repeats "Linux 6.18.y LTS patch release". As of 2026-10-30, kernel.org `releases.json` confirms `6.18.59` is tagged `longterm` with release date 2026-10-26 — so the pin is currently valid. **However**, LFS 13.1-systemd itself uses Linux 7.1.8 (kernel.org path `v7.x/linux-7.1.8.tar.xz`), not 6.18.y. The kit therefore diverges from LFS 13.1's bundled kernel without explanation.

**Proposed fix.** Keep **Linux 6.18.y LTS** as the project baseline (matches §7 of Project Initiation v2). Add ADR-0006 documenting the deliberate divergence from LFS 13.1's default host/target kernel, with rationale: LTS = longer maintenance window and fewer API surprises than 7.x mainline. State explicitly that LFS build instructions are kernel-agnostic for the host requirement ("Linux 5.10 or newer"), so substituting 6.18.y for 7.1.8 has no effect on the LFS build itself; only the bundled kernel package version changes.

**Rationale.** 6.18.y is the most recent retired mainline that has graduated to longterm status (kernel.org tag `longterm`, not `stable`). 7.x is the active mainline/stable stream — too volatile for an LTS project.

**Impact.** Performance: none. Compatibility: kernel modules and APIs are stable for ~2 years of LTS support; the risk of needing a 7.x-only driver is low for the target hardware class (legacy x86_64). Security: CVE backporting is part of LTS — better than chasing mainline.

**Risks and cost.** If a critical 7.x driver becomes needed (unlikely for legacy x86_64), we either backport or accept the limitation. Cost: nothing in Phase 0; from Phase 3 onward we maintain a small patch set on top of 6.18.y.

**Owner decision needed?** **Yes** — confirm pinning to 6.18.y LTS (latest patch release at execution time) as the project baseline.

## AUDIT-002 — Critical

**Problem.** Project Initiation v2 §14 acceptance criterion for Phase 0 demands an ADR set covering `init, libc, bootloader, DE, FS, kernel, package manager`. The kit's `IMPLEMENTATION_ROADMAP.md` Phase 0 deliverables list is much smaller (only `0001-target-architecture.md` plus the standalone docs) and defers ADRs for init/libc/filesystem/display/kernel to **Phase 1**. The two scopes conflict on when architectural decisions must be made.

**Proposed fix.** Project Initiation v2 is the authoritative spec (per §1: «Я — владелец проекта»). Phase 0 will produce all ADRs required by §14. The Phase 0 deliverable list from `IMPLEMENTATION_ROADMAP.md` will be **subsumed** — i.e., Phase 0 of this project is a strict superset of the kit's Phase 0 plus parts of the kit's Phase 1. The kit's later phases (1–11) will be re-mapped after Phase 0 completes.

**Rationale.** §14 explicitly states: «До завершения пунктов ниже не начинай масштабную разработку ядра и не добавляй собственные компоненты». The owner wants decisions to be explicit before any code; deferring ADRs to Phase 1 contradicts that.

**Impact.** Schedule: Phase 0 is longer than the kit's Phase 0. Quality: better — fewer rework loops later.

**Risks and cost.** Cost: 1–2 extra hours of design work in Phase 0. Risk: low; ADRs are easy to revise.

**Owner decision needed?** No — following the owner's own spec.

## AUDIT-003 — Critical

**Problem.** `AI_MASTER_PROMPT.md` §4 says "a documented package format and eventually a project-owned package manager/repository"; `IMPLEMENTATION_ROADMAP.md` Phase 7 mandates "Use Rust for the package-manager implementation". The kit is biased toward **building from scratch**. Project Initiation v2 §6 explicitly lists package manager as a **decision gate**: «разработка с нуля vs адаптация существующего», and §8 lists it among decisions that **require owner approval before action**.

**Proposed fix.** ADR-0007 (package manager) will be written as a **deferred decision** that records (a) the requirements, (b) the candidate set (from scratch in Rust; from scratch in C; adapt `apk-tools` from Alpine; adapt `opkg` from OpenWrt; adapt `dpkg`+`apt`; adapt `pacman`), (c) the criteria (RAM footprint, transaction atomicity, signature story, dependency resolver correctness, code size we must maintain, license compatibility, ease of building from LFS stage). No implementation choice is made in Phase 0. The Rust pre-decision in the kit is recorded as an **assumption to challenge**, not as a chosen baseline.

**Rationale.** §6 of Project Initiation v2 is unambiguous: «менеджер пакетов: разработка с нуля vs адаптация существующего … Это гейт решения: сначала требования и сравнение, потом реализация». The kit's pre-bias would short-circuit that gate.

**Impact.** Performance: undecided until Phase 7. Compatibility: undecided. Security: critical — the package manager signs updates, which is §1 priority.

**Risks and cost.** Cost: time to write a real comparison at Phase 7 entry. Risk of NOT doing this: ending up with a from-scratch manager that breaks updates, violating the project's #1 priority.

**Owner decision needed?** **Yes** — at Phase 7 entry, owner chooses between build-new vs adapt-existing. For Phase 0, owner only needs to confirm that ADR-0007 will be a deferred-decision record, not a choice.

## AUDIT-004 — High

**Problem.** Project Initiation v2 §6 mandates coverage of "безопасность и обновления (подпись пакетов, Secure Boot, отслеживание CVE для LTS-ядра), откат и восстановление (A/B-раздел или снапшоты), локализация (ru/en), установщик, управление лицензиями и соблюдение GPL (исходники и offer)". The kit covers all of these across Phases 7–11 but **none are present in Phase 0**. Project Initiation v2 wants the *outlines* of these in Phase 0 ADRs.

**Proposed fix.** Phase 0 will produce **issue stubs** (not full ADRs) for: Secure Boot policy, CVE tracking process, rollback strategy (A/B vs snapshots vs Btrfs), installer requirements, localization scope, GPL offer / source redistribution. Each stub goes in `docs/` as a short document with a `TODO(phase-N)` marker pointing to the phase that will resolve it. They are not full ADRs because no decision can be made without measurements and owner input — they are explicitly tracked work items.

**Rationale.** The owner wants Phase 0 to identify these as open architectural questions, not to silently defer them by their absence.

**Impact.** Better visibility of decisions still to be made.

**Risks and cost.** Low. A few short stub documents.

**Owner decision needed?** No, but owner is invited to comment on the stub list.

## AUDIT-005 — High

**Problem.** `IMPLEMENTATION_ROADMAP.md` Phase 0 task 2 ("Inventory the build host") and task 3 ("Inventory each real target laptop") are listed together but the kit's `START_HERE_RU.md` instruction 4 ("build host and target hardware are not confused") is the only enforcement. The Project Initiation v2 §4 separation ("Инвентаризация окружения" vs "Целевые профили") is sharper: build-host inventory feeds `docs/ENVIRONMENT.md`; target profiles feed `TARGET_HARDWARE.md`.

**Proposed fix.** Maintain two distinct documents: `docs/ENVIRONMENT.md` (host) and `TARGET_HARDWARE.md` (target classes + per-device sheets). Never confuse the two. The current build host (Debian 13, 4 GB, 2 cores, KVM VM) is **not** representative of any target profile.

**Rationale.** §2 priority #1 is «надёжность и безопасность обновлений»; conflating host and target invites building for the wrong machine.

**Impact.** Avoids the classic LFS mistake of accidentally inheriting host kernel modules.

**Risks and cost.** Two short docs. Negligible.

**Owner decision needed?** No.

## AUDIT-006 — Medium

**Problem.** `AI_MASTER_PROMPT.md` §4 says "Initial filesystem: ext4. Consider Btrfs/snapshots only after a reliable first release and recovery design." `IMPLEMENTATION_ROADMAP.md` Phase 1 says "ADRs for init, libc, filesystem, display stack, and kernel line" without specifying a default. Project Initiation v2 §6 lists "FS: ext4 vs XFS vs Btrfs — HDD/SSD, надёжность, снапшоты для отката" — ext4 is one of three candidates, with snapshot-based rollback being a primary criterion (because §1 priority #1 is "update brick-resistance").

**Proposed fix.** ADR-0005 (filesystem) will: (a) keep **ext4** as the default for the first release (matches §4 of the kit, defers Btrfs complexity); (b) explicitly evaluate Btrfs for rollback in a separate Phase 8 sub-decision, not now; (c) record XFS as a documented non-choice for the Legacy profile (XFS lacks metadata checksums robust enough for HDD power-loss scenarios). Snapshot/rollback strategy is the **only** FS decision that affects §1 priority #1, and it is deferred to Phase 8 with A/B-vs-Btrfs as the open question.

**Rationale.** ext4 + a separate A/B partition scheme (two root partitions, alternate updates) gives us rollback without depending on Btrfs's more complex failure modes. ext4 + LVM snapshots is an alternative but adds LVM userspace.

**Impact.** Phase 0–7: ext4, simple, measurable. Phase 8: revisit.

**Risks and cost.** If we pick Btrfs early we risk data loss on legacy hardware. The cost of staying with ext4 is «no native snapshots» — mitigated by A/B or LVM.

**Owner decision needed?** **Yes** — confirm ext4 as default first-release FS, with Btrfs/A-B-rollback deferred to Phase 8.

## AUDIT-007 — Medium

**Problem.** `AI_MASTER_PROMPT.md` §4 says "Init/service management: systemd initially, with only necessary services enabled." Project Initiation v2 §6 demands an explicit comparison: «systemd vs OpenRC vs runit/s6 — по RAM, времени загрузки, совместимости с DE (logind, udev, NetworkManager), стоимости поддержки». The kit treats the decision as made.

**Proposed fix.** ADR-0001 (init) will perform the actual comparison. Provisional recommendation: **systemd** (matches LFS 13.1-systemd variant, has best DE compatibility, lowest support cost). OpenRC/s6 are realistic alternatives only if idle-RAM measurements (Phase 5) show systemd > 50 MB on the Legacy profile. The ADR records the conditions under which we would revisit.

**Rationale.** Kit's choice is reasonable, but the owner explicitly asked for the comparison. Doing it once, in writing, removes a recurring question.

**Impact.** Idle RAM on Legacy is the key risk; we measure in Phase 5.

**Risks and cost.** Low.

**Owner decision needed?** **Yes** — confirm systemd as the provisional baseline, with explicit revisit triggers.

## AUDIT-008 — Low

**Problem.** `PROJECT_STATUS_TEMPLATE.md` from the kit has 8 stub fields. Project Initiation v2 §12 specifies PROJECT_STATUS.md as «фаза, задачи со статусами достоверности, блокеры, известные проблемы». The kit template is missing the "status per component" structure required by §5.

**Proposed fix.** Replace `PROJECT_STATUS.md` with a structure that satisfies both: phase + per-component status table (with §5 status values Planned / Implemented / Verified (build) / Verified (QEMU) / Verified (hardware)) + blockers + known issues + next action. Keep the kit's `IMPLEMENTATION_LOG.md` template as-is.

**Rationale.** §5 mandates per-component status; the kit's template doesn't enforce it.

**Impact.** None.

**Risks and cost.** None.

**Owner decision needed?** No.

## AUDIT-009 — Low

**Problem.** `AI_MASTER_PROMPT.md` §4 says "C library: glibc initially for compatibility." `IMPLEMENTATION_ROADMAP.md` does not require an ADR for libc. Project Initiation v2 §6 demands «glibc vs musl — по совместимости с проприетарным ПО, драйверами и приложениями».

**Proposed fix.** ADR-0002 (libc) will: keep **glibc** (matches LFS default, best binary compatibility for legacy proprietary drivers and pre-compiled apps like older browsers). musl is documented as a non-choice for the first release because (a) several closed-source Wi-Fi firmware loaders and (b) some pre-built Electron apps assume glibc. The decision is revisitable if a future Legacy sub-profile (≤1 GB) makes the 1–2 MB savings worth the compatibility cost.

**Rationale.** glibc is the path of least resistance for compatibility with the target user class (people with old laptops who want things to "just work"). musl savings are small relative to the rest of the userspace.

**Impact.** ~1 MB more RAM than musl baseline. Compatible with all current target packages.

**Risks and cost.** None for the first release.

**Owner decision needed?** **Yes** — confirm glibc, with musl deferred.

## AUDIT-010 — Low

**Problem.** The kit's `README.md` and `START_HERE_RU.md` say "Send only one phase prompt at a time." Project Initiation v2 says nothing about this discipline explicitly but §14 (Phase 0) is itself a single-phase gate. Both align.

**Proposed fix.** None — record the alignment as a finding. The "one phase at a time" rule will be respected: after Phase 0 completes and the owner approves, the next request will explicitly target Phase 1 (re-mapped, since the kit's Phase 1 is now partially subsumed).

**Owner decision needed?** No.

## AUDIT-011 — Low

**Problem.** `AI_MASTER_PROMPT.md` §11 says "Avoid background daemons unless they provide a user-visible or system-critical function." Project Initiation v2 §2 priority 5 is «минимальная фоновая нагрузка». Consistent.

**Proposed fix.** None.

**Owner decision needed?** No.

## AUDIT-012 — Low

**Problem.** `AI_MASTER_PROMPT.md` §7 forbids `localmodconfig` and `-march=native` for release kernels. Project Initiation v2 §7 forbids the same. Consistent.

**Proposed fix.** None.

**Owner decision needed?** No.

## Summary

| ID | Priority | Owner decision needed? |
|---|---|---|
| AUDIT-001 | High | Yes — confirm 6.18.y LTS |
| AUDIT-002 | Critical | No (follows spec) |
| AUDIT-003 | Critical | Yes — confirm deferred ADR-0007 |
| AUDIT-004 | High | No (invited to comment) |
| AUDIT-005 | High | No |
| AUDIT-006 | Medium | Yes — confirm ext4 + deferred Btrfs |
| AUDIT-007 | Medium | Yes — confirm systemd provisional |
| AUDIT-008 | Low | No |
| AUDIT-009 | Low | Yes — confirm glibc |
| AUDIT-010 | Low | No |
| AUDIT-011 | Low | No |
| AUDIT-012 | Low | No |

All "Yes" items are batched in the **Decisions needed** section of `REPORT.md`.
