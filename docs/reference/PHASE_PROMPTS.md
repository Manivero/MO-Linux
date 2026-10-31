# Copy/Paste Prompts for the AI Coding Agent

Use `AI_MASTER_PROMPT.md` and `IMPLEMENTATION_ROADMAP.md` as permanent project instructions. Send only one phase prompt at a time. Do not tell the agent to implement the whole distribution in one run.

## First message — initialize the project

```text
Read AI_MASTER_PROMPT.md and IMPLEMENTATION_ROADMAP.md completely. Do not implement any system components yet.

Start Phase 0 only. Inspect the repository and current host environment safely. Determine what is known about the build host and what is unknown about the real target laptop(s). Do not invent hardware facts. Create the Phase 0 deliverables and ADRs described in the roadmap. Do not install host packages, modify partitions, change boot settings, create commits, or push anything.

Before editing, show a short plan and identify any genuinely blocking unknowns. After implementation, run safe validation, update PROJECT_STATUS.md and IMPLEMENTATION_LOG.md, and provide the required PROJECT_STATUS / IMPLEMENTATION_LOG / REPORT. Stop at the Phase 0 acceptance gate. Do not start Phase 1.
```

## Phase 1 — architecture and repository scaffold

```text
Read AI_MASTER_PROMPT.md, IMPLEMENTATION_ROADMAP.md, and the current PROJECT_STATUS.md. Implement Phase 1 only. Inspect existing files and preserve all user work. Create the repository scaffold, module boundaries, boot/system/build/test specifications, ADRs, and templates. Do not compile LFS, write kernel code, build a package manager, or begin later phases. Validate internal consistency and update the project status/log. Stop at the Phase 1 acceptance gate and report evidence.
```

## Phase 2 — isolated LFS build environment

```text
Implement Phase 2 only. First verify the current stable LFS systemd book, matching BLFS book, errata, security advisories, and host prerequisites from official sources. Pin the exact book/source revisions used. Design an isolated build environment and source lock. Implement safe preflight, download/cache, logging, and build orchestration following the published LFS sequence. Do not modify the host root filesystem or physical partitions. Do not skip LFS steps or claim a completed build unless it actually completed. Produce a minimal rootfs artifact in a project-owned build directory or disposable image. Update status/log and stop at the Phase 2 gate.
```

## Phase 3 — generic kernel and first QEMU boot

```text
Implement Phase 3 only. Verify the currently maintained Linux 6.18.y LTS patch level and pin an exact source revision. Build a generic x86_64 kernel without using localmodconfig or -march=native. Integrate it into the Phase 2 rootfs, create a QEMU-only boot path, and test login, mounts, systemd PID 1, shutdown and reboot. Use disposable image files; never target a physical disk. Keep the upstream baseline and all config/build inputs recorded. Update status/log and stop at the Phase 3 gate.
```

## Phase 4 — hardware compatibility

```text
Implement Phase 4 only. Use available physical target hardware if the user has provided access; otherwise build the compatibility test framework and mark untested hardware as untested. Expand generic driver/module support carefully, document firmware source/license status, test graphics, storage, network, audio, input, ACPI, power and suspend/resume. Do not remove drivers based on the build machine. Do not claim hardware support without a recorded test. Update the compatibility matrix, status/log and stop at the Phase 4 gate.
```

## Phase 5 — performance baseline

```text
Implement Phase 5 only. Do not optimize blindly. Establish repeatable measurements for boot, memory, CPU idle, I/O, service startup, app launch, browser workload, audio/video and suspend/resume. Compare on identical hardware with a relevant reference installation when available. Record commands, environment, raw data, medians and limitations. Derive initial budgets from evidence; treat previous numerical guesses as unvalidated hypotheses. Make no unrelated system changes. Update status/log and stop at the Phase 5 gate.
```

## Phase 6 — desktop environment

```text
Implement Phase 6 only. Establish the Xorg + Xfce desktop baseline, keeping its components modular. Measure it on the 2 GB target if available. Only then decide whether to add a separate ultra-light legacy session. Keep Wayland optional until tested on target GPUs. Verify basic tasks can be completed graphically: login, Wi-Fi, audio, display, power, files and terminal. Audit autostart/background services. Update status/log and stop at the Phase 6 gate.
```

## Phase 7 — package format and package manager

```text
Implement Phase 7 only. Finalize PACKAGE_FORMAT.md before writing the manager. Implement metadata parsing/validation, signed repository metadata, checksums, dependency resolution, package database, staged install/remove and conflict checks in that order. Use disposable target rootfs images; never operate on the host package database. Avoid arbitrary privileged package scripts. Add tests for corrupted packages, invalid signatures, dependency cycles, conflicts and interrupted operations. Update status/log and stop at the Phase 7 gate.
```

## Phase 8 — security, update and recovery

```text
Implement Phase 8 only. Write the threat model and trust boundaries first. Design repository signing, key rotation, package verification, transaction semantics, interruption handling and recovery. Do not place private signing keys in the repository or chat. Add hardening incrementally and test it against hardware functionality. Do not claim atomic rollback unless demonstrated. Update status/log and stop at the Phase 8 gate.
```

## Phase 9 — installer and ISO

```text
Implement Phase 9 only. Build a live ISO and installer tested exclusively on disposable QEMU disk images first. Support clear UEFI and legacy BIOS paths where included in the target matrix. The installer must inspect disks read-only first, show the exact target and partition changes, and require explicit confirmation immediately before destructive writes. Never run installer, partitioning, formatting or bootloader installation against a host/physical disk. Test blank-image installation, preservation of existing partitions/data, failure handling and recovery. Update status/log and stop at the Phase 9 gate.
```

## Phase 10 — own kernel patchset

```text
Implement Phase 10 only. Work on a separate project kernel patch branch while preserving an upstream baseline and known-good boot entry. Do not make broad scheduler or memory-manager rewrites. Profile first, choose one small measurable change, document problem/rationale/risk/rollback, implement behind an experimental option where appropriate, and run relevant kernel tests, stress tests, hardware tests and before/after benchmarks. Keep experimental changes out of stable release until accepted. Update status/log and stop at the Phase 10 gate.
```

## Phase 11 — release engineering

```text
Implement Phase 11 only. Add CI checks, source-lock validation, package/recipe tests, QEMU smoke boots, release metadata, checksums, signatures, SBOM/license reporting, release notes and maintenance policy. Be explicit about which jobs run a complete LFS build and which do not. Verify clean rebuild, installation, upgrade and recovery on disposable images. Do not publish or push a release without explicit user approval. Update status/log and stop at the Phase 11 gate.
```

## Fix-only prompt — when a phase fails

```text
Do not start the next phase. Reproduce and diagnose the specific failure from the last phase. Inspect logs and repository state first. Propose the smallest safe correction, implement only that correction, and rerun the failing test plus relevant regression tests. Do not hide or weaken a failing test to obtain a green result. Update PROJECT_STATUS.md and IMPLEMENTATION_LOG.md with the failure, root cause, fix and evidence. Stop and report whether the phase gate is now met.
```

## Review-only prompt — before approving a phase

```text
Perform a read-only review of the completed phase. Do not modify files. Check the diff, architecture consistency, unsafe commands, host modifications, source pinning, test evidence, documentation, and acceptance criteria. Identify blockers, risks, and claims not supported by test output. Return a concise review report. Do not start the next phase.
```
