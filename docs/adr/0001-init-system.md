# ADR-0001 — Init / service manager

- **Status:** Proposed (pending owner approval)
- **Date:** 2026-10-30
- **Phase origin:** Phase 0
- **Decision owner:** Project owner (§8 of Project Initiation v2 — affects product)
- **Confidence:** Hypothesis — measurable revisit in Phase 5

## Context

Project Initiation v2 §6 requires an explicit comparison: «systemd vs OpenRC vs runit/s6 — по RAM, времени загрузки, совместимости с DE (logind, udev, NetworkManager), стоимости поддержки». The kit's `AI_MASTER_PROMPT.md` §4 pre-selects systemd without comparison. This ADR performs the comparison the owner asked for.

The §2 priority order says: reliability > performance > RAM > hardware compatibility > boot time > UX. Compatibility with desktop environments (Xfce, logind-driven power management, NetworkManager, PipeWire session handling) and **reliability of the update transaction** are higher priorities than absolute minimum RAM.

## Options considered

| Option | Idle RAM (typical, references) | Boot time | DE compatibility | NetworkManager | PipeWire session | Maintenance cost |
|---|---|---|---|---|---|---|
| **systemd** (LFS 13.1-systemd default) | ~30–60 MB | fast (parallel) | first-class (logind, sd-bus, sd-notify) | first-class | first-class | low — matches upstream LFS |
| **OpenRC** (used by Alpine/Artix) | ~10–25 MB | medium | needs elogind; needs DBus setup | works with patch | works | medium — extra elogind dependency |
| **runit** (Void) | ~5–10 MB | fast | needs seatd/elogind manually | works | works | high — many things to glue |
| **s6/s6-rc** (skarnet) | ~5–10 MB | fast | needs elogind + careful service bundle | works | works | high — steep learning curve |

Idle-RAM figures are quoted from public references (Alpine, Void, Artix wikis) and are themselves hardware- and version-dependent. They are **not** measured for our target; the revisit trigger below converts them into measured values in Phase 5.

## Decision

Adopt **systemd** as the project init/service manager. Pin to the version bundled with LFS 13.1-systemd: **systemd 261.2** (verified 2026-10-30 from LFS 13.1-systemd chapter 3 source list). Only the necessary services will be enabled; everything else is masked per Phase 1 SYSTEM_SERVICES.md.

## Rationale

1. Reliability of updates is §2 priority #1. systemd integrates transactional-update semantics natively (`systemctl revert`, journal-based rollback of failed units) and is what every major LFS variant uses. OpenRC + elogind doubles the surface area we must maintain ourselves; for the same reliability we would carry more code.
2. DE compatibility for the target user (GUI on legacy laptops) requires logind, seat management, brightness / lid / suspend hooks, NetworkManager-wait-online, PipeWire user-session wiring. All of these are first-class in systemd and require manual glue on runit/s6.
3. The RAM gap to alternatives (10–50 MB) is real but **measurable**: we will quantify it on the Legacy 2 GB profile in Phase 5 before deciding whether to keep systemd or move the Legacy profile to a lighter init.
4. Support cost: LFS 13.1-systemd variant is the upstream default; using it means we inherit the upstream documentation and patch cadence.

## Consequences

- Positive: minimal integration work; updates and security fixes tracked upstream; users get a familiar system.
- Negative: systemd idle RAM is non-trivial on 2 GB systems; some users dislike systemd on philosophical grounds.
- Risks: if Phase 5 measurement shows systemd idle RSS > 50 MB on Legacy, we reopen this ADR and consider OpenRC + elogind for the Legacy profile only.

## Revisit triggers

- Phase 5 measurement on the Legacy profile shows systemd idle RSS > 50 MB on 2 GB target.
- A critical systemd CVE leaves the project without an upstream patch within 14 days of disclosure.
- Owner requests a CLI-only sub-profile with target idle RAM < 30 MB (where systemd overhead would dominate).

## Verification plan

- **Verified (build):** build systemd 261.2 from LFS 13.1-systemd instructions (Phase 2).
- **Verified (QEMU):** PID 1 is `systemd`, `systemctl get-default` returns `multi-user.target` or `graphical.target` (Phase 3).
- **Verified (hardware):** boot on a Legacy target, run `systemd-analyze` and capture the boot chart (Phase 5).
- Measurements stored in `bench/results/<date>-init-comparison/`.
