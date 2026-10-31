# REPORT — Phase 0 cycle

## PROJECT_STATUS

- **Current phase:** Phase 0
- **Status:** PARTIAL — Phase 0 deliverables produced; awaiting owner decisions on 5 batched questions before declaring Phase 0 COMPLETE and starting Phase 1.
- **Repository path:** `/home/z/my-project/download/distro`
- **Branch / working tree:** git initialized; **no commits** (per §10 of Project Initiation v2). Working tree is clean except for the new Phase 0 files, which are deliberately untracked.
- **Build host:** Debian 13 (trixie), 2 cores, 4 GB RAM, 9.3 GB free disk, KVM VM (no nested virt). Not a target device.
- **Target hardware:** NONE provided by owner.

### What changed (files and purpose)

Created a complete Phase 0 repository at `/home/z/my-project/download/distro/`:

- **Top-level docs:** `README.md`, `PROJECT_VISION.md`, `ARCHITECTURE.md`, `TARGET_HARDWARE.md`, `KERNEL_POLICY.md`, `PROJECT_STATUS.md`, `IMPLEMENTATION_LOG.md`, `REPORT.md` (this file), `sources.lock`, `Makefile`, `.gitignore`, `.github/workflows/ci.yml`.
- **`docs/`:** `ENVIRONMENT.md` (host inventory), `AUDIT_FINDINGS.md` (12 findings vs Project Initiation v2), `HARDWARE_TEST_PLAN.md` (23 deferred HW tests + device sheet template).
- **`docs/adr/`:** 1 template + 7 ADRs covering init (0001), libc (0002), bootloader (0003), DE (0004), filesystem (0005), kernel line (0006), and package manager (0007 — deferred decision record).
- **`docs/reference/`:** verbatim copies of the AI kit files (AI_MASTER_PROMPT.md, IMPLEMENTATION_ROADMAP.md, PHASE_PROMPTS.md, START_HERE_RU.md, PROJECT_STATUS_TEMPLATE.md, README.md) — read-only reference.
- **`scripts/`:** `lib/lfs-safety.sh` (with `--self-test`), `host-version-check.sh`, `sources-verify.py`, `adr-lint.py`.
- **`scripts/bench/`:** `idle-ram.sh`, `boot-time.sh`, `disk-io.sh`.
- **`config/kernel/`, `config/system/`, `tests/`, `bench/results/`:** Phase 0 stub READMEs.

### Build/test commands actually run

| Command | Result |
|---|---|
| `bash scripts/lib/lfs-safety.sh --self-test` | **PASS** (5/5 self-test cases) |
| `bash scripts/host-version-check.sh` | **3 missing LFS-required tools** (bison, gawk, texinfo). 0 too-old. Extra-tool gaps: shellcheck, qemu-system-x86_64, ccache, ninja, meson, rustc, cargo. `fio` on PATH is the wrong tool (fiona's CLI, not the disk I/O bench). Output: `bench/results/host-version-check-<timestamp>.txt`. |
| `python3 scripts/adr-lint.py docs/adr` | **PASS** (7 ADRs, 0 issues). |
| `python3 scripts/sources-verify.py sources.lock` | **PARTIAL** — 23 entries found. Some OK; many `FAIL` because `ftpmirror.gnu.org` is unreachable in this sandbox. URLs are correct; reachability is a sandbox limitation. Output: see command stdout. |
| `bash scripts/bench/idle-ram.sh` | Wrote `bench/results/<timestamp>-idle-ram.txt`. |
| `bash scripts/bench/boot-time.sh` | Wrote `bench/results/<timestamp>-boot-time.txt`. systemd not PID 1 on host (it's `tini`); only the procedural document was produced. |
| `bash scripts/bench/disk-io.sh` | Wrote `bench/results/<timestamp>-disk-io.txt`. Real `fio` not installed → dd fallback. Non-authoritative. |
| `make check` | Runs self-test + host-version-check; both complete. |

### Performance data, if applicable

**None of the bench numbers above describe the target system.** They describe the build host (Debian 13 in a KVM VM with no nested virt). The target system has not been measured because the owner has not yet provided access to a target laptop.

Per Project Initiation v2 §3: target numerical budgets (idle RAM, boot time, app latency) are **hypotheses** measured in Phase 5. Phase 0 deliberately does **not** invent target budgets.

### Known limitations and risks

1. **No target hardware provided.** All 23 HW-* tests in `docs/HARDWARE_TEST_PLAN.md` are deferred to Phase 4.
2. **3 LFS host prerequisites missing** (bison, gawk, texinfo). Phase 2 cannot start until they are installed (requires owner approval).
3. **`qemu-system-x86_64` not installed and `/dev/kvm` absent.** Phase 3 QEMU tests will only run in TCG (very slow) unless QEMU is added.
4. **`shellcheck` not installed.** `make shellcheck` skips gracefully; full linting will require installation.
5. **`fio` on the host PATH is the wrong tool** (Python `fiona` CLI). Real `fio` (the disk I/O bench) is needed for authoritative I/O measurements in Phase 5.
6. **No passwordless sudo.** Phase 2's `lfs` user creation requires owner-supplied credentials, OR a no-root build strategy that we will design at Phase 2 entry.
7. **`sources.lock` SHA256 values are `UNVERIFIED`.** URLs are HEAD-checked (where the sandbox network permits); SHA256 will be computed in Phase 2 after actual download.
8. **No git commits exist.** Per §10 of Project Initiation v2, no commit / push / external modification is performed by automation. The owner may want a first baseline commit before Phase 1 — that is their decision.

### Whether the Phase 0 acceptance criteria are met (per §14 of Project Initiation v2)

| Criterion | Met? | Evidence |
|---|---|---|
| Documents do not contradict each other; deviations from kit listed | YES | `docs/AUDIT_FINDINGS.md` (12 findings) |
| ADRs for init, libc, bootloader, DE, FS, kernel, package manager | YES | `docs/adr/0001`–`0007` (passes `adr-lint`) |
| Profiles + first measurable targets + measurement method | PARTIAL | `TARGET_HARDWARE.md` defines Legacy/Standard/Extended; numerical budgets deferred to Phase 5 per kit's own guidance |
| Host-check script + bench scripts run + pass shellcheck | PARTIAL | Scripts run; `shellcheck` unavailable (graceful skip) |
| First-stage sources pinned with versions + SHA256 OR marked "unverified, no network" | YES | `sources.lock` — URLs reachable where sandbox network permits; SHA256 = `UNVERIFIED` for Phase 2 download |
| Each component in `PROJECT_STATUS.md` has a §5 status | YES | See status table in `PROJECT_STATUS.md` |
| No commits, push, or out-of-tree changes | YES | `git init` only; no commits; only new files under `/home/z/my-project/download/distro/` |

### Recommended next phase (do NOT start it)

Phase 1 — re-mapped: **detailed architecture documents** (`BOOT_AND_RECOVERY.md`, `SYSTEM_SERVICES.md`, `BUILD_SYSTEM.md`, `TESTING_STRATEGY.md`, `SECURITY_MODEL.md` sketch, `PACKAGE_FORMAT.md` sketch, `RELEASE_POLICY.md` sketch, `GPL_COMPLIANCE.md` stub) + remaining Phase 0 stubs (per-device sheets when hardware is available). Do **not** start until the owner answers the 5 questions below.

## Decisions needed from the owner

5 batched questions (per §8: "Вопросы собирай в один блок, не более 5, с рекомендацией по каждому"):

| # | Question | Recommendation |
|---|---|---|
| 1 | **Confirm the provisional baselines** (kernel 6.18.y LTS, systemd, glibc, GRUB, Xfce, ext4+A/B) per ADRs 0001–0006? | YES — all 7 ADRs have revisit triggers; the provisional baseline lets Phase 2 begin. |
| 2 | **Confirm that ADR-0007 (package manager) is a deferred-decision record**, NOT a build-from-scratch Rust pre-decision? | YES — Project Initiation v2 §6 explicitly requires build-new vs adapt-existing comparison at Phase 7 entry. |
| 3 | **May we install host prerequisites** (bison, gawk, texinfo, shellcheck, qemu-system-x86_64, qemu-utils, ninja-build, meson, ccache, real `fio`) on this Debian 13 host? | RECOMMEND: yes, install via `sudo apt-get install`. Without these, Phase 2 and Phase 3 are blocked. If "no", Phase 2 must move to a different build worker. |
| 4 | **Phase 2 build strategy**: (a) create a dedicated `lfs` user with sudo, (b) build as the unprivileged `z` user inside a project-owned directory with no root, or (c) move to a different build worker that has root? | RECOMMEND: option (b) — build entirely without root, in a loopback file under `/home/z/my-project/download/distro/build/`. Mount/loop setup still needs root for the loop device; if that's also blocked, fall back to plain directory-mode without `mount`. Document the constraint in `BUILD_SYSTEM.md` (Phase 1). |
| 5 | **Is there a specific legacy laptop the first release should target?** Model name lets us research drivers early. | Optional — if not, Phase 4 entry will work with whatever laptop the owner provides. |

---

## IMPLEMENTATION_LOG (summary — full entry in `IMPLEMENTATION_LOG.md`)

**2026-10-30 — Phase 0 (initial cycle).** Read AI kit, audited against Project Initiation v2 (12 findings, 3 critical), inventoried build host (Debian 13, 4 GB, no nested KVM), verified LFS 13.1-systemd + Linux 6.18.59 LTS upstream, wrote 7 ADRs, defined 3 target profiles + hardware matrix, created repo skeleton, wrote `host-version-check.sh`, `sources-verify.py`, `adr-lint.py`, `lib/lfs-safety.sh` (with self-test), 3 bench scripts, `sources.lock` (kernel + 13 LFS core packages + 8 patches), `Makefile`, `.github/workflows/ci.yml`. Ran all safe validations: self-test PASS, host-version-check 3 missing, adr-lint 0 issues, sources-verify 4 OK / network-limited, bench scripts all wrote output files. No commits, no host packages installed, no partitioning, no out-of-tree changes.

## REPORT (clear-language summary)

Phase 0 is **substantially complete** but cannot be declared FULLY complete without owner sign-off on the 5 questions above (especially #3 — installing the missing LFS host prerequisites).

Three things that worked well:

1. The audit caught real divergence between the AI kit's implicit choices and Project Initiation v2's explicit gate-decision requirement (AUDIT-003, package manager). Recording ADR-0007 as a deferred decision preserves the gate.
2. The host version check is honest: it reports `bison`, `gawk`, `texinfo` as missing (not "should work") and identifies the `fio` on PATH as the wrong tool (Python `fiona`, not the disk bench).
3. The LFS safety library actually fails closed — its self-test verifies that relative paths, `/`, `/usr`, and `/usr/local/bin` are all refused.

Three things to note:

1. `ftpmirror.gnu.org` is unreachable from this sandbox, so several URLs in `sources.lock` show as `FAIL` in `sources-verify.py` output. The URLs themselves are correct; reachability is a sandbox limitation. The Phase 2 download script will retry from a different mirror (`https://mirrors.kernel.org/gnu/` is the fallback).
2. The bench numbers in `bench/results/` describe the **build host**, not the target. Do not quote them as target performance.
3. No git commits exist. This is intentional per §10 of Project Initiation v2.

**No commits, no pushes, no host package installations, no partitioning, no bootloader installation, and no out-of-tree file modifications were performed.**

To start Phase 1 (after answering the 5 questions), the next message should explicitly say "Phase 1" and ideally re-state the answers to questions 1–5.
