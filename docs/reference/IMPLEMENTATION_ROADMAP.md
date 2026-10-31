# Implementation Roadmap — Lightweight Linux Distribution

## Product statement

A source-built, x86_64 Linux distribution designed for older laptops: responsive, low-overhead, usable, hardware-aware, and maintainable. LFS is the bootstrap/build methodology; Linux remains the upstream kernel and core ecosystem.

## Phase 0 — Product requirements and hardware discovery

**Goal:** Replace assumptions with real target requirements.

Tasks:
1. Create the project repository or inspect the existing repository without changing its branch or user changes.
2. Inventory the build host: OS, CPU, RAM, free disk, compiler/tool versions, available virtualization.
3. Inventory each real target laptop, if available. Collect model, CPU, RAM, storage, GPU, Wi-Fi chipset, audio, BIOS/UEFI mode, and battery/suspend information. Use read-only commands such as `lscpu`, `free -h`, `lsblk`, `lspci -nnk`, `lsusb`, `inxi -Fxxxz` if installed.
4. Create hardware profiles: `legacy` (2 GB target), `standard` (4 GB), `extended` (8 GB+), but label them as target classes rather than guarantees.
5. Define the minimum supported CPU baseline as generic x86_64. Explicitly defer 32-bit CPUs and unusual 32-bit UEFI unless the user later requests them.
6. Record functional requirements: boot, display, Wi-Fi, Ethernet, audio, touchpad, battery, brightness, suspend/resume, USB, file manager, browser, updates.
7. Record constraints and open decisions in ADRs.

Deliverables:
- `PROJECT_VISION.md`
- `TARGET_HARDWARE.md`
- initial `ARCHITECTURE.md`
- `docs/adr/0001-target-architecture.md`
- `PROJECT_STATUS.md`

Acceptance gate:
- build host and target hardware are not confused;
- unknown hardware facts are marked unknown, not invented;
- target profile and explicit non-goals are documented;
- no system build or host modification has started.

## Phase 1 — Repository scaffold and architecture specifications

**Goal:** Establish boundaries before implementation.

Tasks:
1. Create repository structure for `bootstrap`, `kernel`, `system`, `desktop`, `hardware`, `package-manager`, `installer`, `build-system`, `benchmarks`, `tests`, and `docs`.
2. Define the dependency direction between build host, cross-toolchain, target root filesystem, kernel, initramfs, user space, and ISO image.
3. Write the boot flow: firmware -> GRUB -> kernel -> optional initramfs -> root filesystem -> systemd -> login/desktop.
4. Create a system-service inventory template. No service should be enabled without a reason.
5. Define release profiles: `base` (CLI), `legacy` (minimal GUI profile, subject to testing), and `desktop` (Xfce). Do not implement all profiles yet.
6. Define source pinning/lock-manifest schema and document how checksums/signatures are verified.
7. Add coding conventions, ADR template, test policy, and report templates.

Deliverables:
- repository skeleton;
- `ARCHITECTURE.md`, `BOOT_AND_RECOVERY.md`, `SYSTEM_SERVICES.md`, `BUILD_SYSTEM.md`, `TESTING_STRATEGY.md`;
- ADRs for init, libc, filesystem, display stack, and kernel line;
- `PROJECT_STATUS.md` and `IMPLEMENTATION_LOG.md`.

Acceptance gate:
- module responsibilities and dependency boundaries are unambiguous;
- no application/system component is duplicated without justification;
- decisions and open risks are documented;
- no custom package manager or kernel patch has been written.

## Phase 2 — Isolated LFS build environment and source lock

**Goal:** Build safely and reproducibly without modifying the host system.

Tasks:
1. Verify the stable LFS systemd book version and matching stable BLFS book at execution time. Use LFS 13.1-systemd and BLFS 13.1 as the current starting baseline, but re-check stable release, errata, and security advisories before pinning.
2. Verify host prerequisites against the LFS host requirements chapter.
3. Design an isolated build environment: dedicated VM or disposable build disk/image, dedicated build directory and unprivileged build user. Keep target filesystem separate from host `/`.
4. Implement source download/cache and a lock manifest with exact versions, source URLs, hashes, and signature status.
5. Follow LFS stages: host validation, temporary toolchain, cross compilation/chroot stages, final toolchain/system. Do not shortcut commands without documenting why.
6. Add preflight checks, resumability where safe, logs, failure exit codes, and cleanup that only touches project-owned build directories.
7. Produce a minimal base root filesystem artifact; do not install it to a physical machine.

Deliverables:
- `build-system/` scripts;
- source lock manifest;
- build host requirements document;
- build logs and a hash of the output artifact;
- documented clean/rebuild procedure.

Acceptance gate:
- isolated build works from documented instructions;
- source versions and checksums are pinned;
- host root filesystem and partitions were not modified;
- a second build can be compared and any nondeterminism is documented;
- the resulting rootfs is archived as an artifact.

## Phase 3 — Generic kernel and first bootable CLI system

**Goal:** Boot the newly built system in QEMU to a reliable console.

Tasks:
1. Pin a specific upstream Linux 6.18.y LTS patch release after checking kernel.org; record the commit/tag and source hash.
2. Start with a broad generic x86_64 configuration, not a machine-specific `localmodconfig`.
3. Keep boot-critical storage, filesystem, console, ACPI, and common bus support available. Decide carefully which features are built-in and which are modules.
4. Build and install kernel, modules, and matching module metadata into the target rootfs.
5. Initially use a controlled, testable root-mount strategy. If initramfs is deferred, make all required boot drivers built-in and document the limitation. Add initramfs once its design and tests are ready.
6. Create GRUB configuration for QEMU. Validate serial/virtual console and graphical console paths.
7. Boot in QEMU using a disposable disk image. Do not write to physical disks.
8. Test login, `systemd` startup, shell, filesystem mounts, shutdown and reboot.

Deliverables:
- `kernel/` pinned source/config/build scripts;
- generic kernel artifact and modules;
- QEMU boot scripts and disk image;
- boot logs and troubleshooting guide;
- `KERNEL_POLICY.md` and updated `BOOT_AND_RECOVERY.md`.

Acceptance gate:
- repeatable QEMU boot to login shell;
- correct root filesystem and systemd PID 1;
- clean reboot/shutdown;
- no unexplained kernel panic or critical service failure;
- original upstream kernel baseline is retained for comparison.

## Phase 4 — Hardware enablement and compatibility matrix

**Goal:** Make the system usable on real target laptops before desktop polishing.

Tasks:
1. Expand generic kernel support for common x86 laptop hardware without trimming unrelated drivers.
2. Define kernel modules and firmware packaging policy.
3. Test graphics modesetting and Mesa support for target Intel/AMD GPUs.
4. Test Wi-Fi, Ethernet, Bluetooth, audio, USB, webcam, storage, keyboard and touchpad.
5. Test ACPI, brightness, battery, lid close/open, suspend/resume, thermal behavior and CPU frequency scaling.
6. Record exact PCI/USB IDs, kernel driver, firmware requirement and test result.
7. Mark each device as `tested`, `partially-tested`, `untested`, or `unsupported`.
8. Keep proprietary and legacy NVIDIA cases separate; do not block the open-driver baseline on a universal NVIDIA promise.

Deliverables:
- `HARDWARE_COMPATIBILITY.md`;
- `hardware/` profiles and diagnostic collection scripts;
- firmware manifest and licensing notes;
- test reports for every available physical target.

Acceptance gate:
- the declared minimum hardware target boots and provides the essential functions claimed;
- unsupported devices are clearly listed;
- no driver was removed solely because it was absent on the build host;
- firmware redistribution is legally reviewed/documented.

## Phase 5 — Performance baseline and optimization budgets

**Goal:** Establish reproducible measurements before optimizing.

Tasks:
1. Define benchmark protocol and environment controls.
2. Measure cold boot from bootloader handoff to login, and separately to desktop when present.
3. Measure idle memory with `MemAvailable`, RSS/PSS and cache distinguished; record services and process list.
4. Measure CPU idle, wakeups, disk I/O, startup services, app launch latency and interactive responsiveness.
5. Run realistic tasks: terminal, file manager, browser with fixed test pages/tabs, audio/video playback, Wi-Fi active, suspend/resume.
6. Compare with at least one reference distribution on identical hardware and comparable settings.
7. Store scripts, raw outputs, machine metadata, summaries, medians and run-to-run spread.
8. Set versioned performance budgets only after these measurements.
9. Make one optimization at a time and rerun regression tests.

Deliverables:
- `PERFORMANCE_BUDGET.md`;
- `benchmarks/` scripts and raw reports;
- baseline comparison report;
- documented bottleneck list ranked by measured impact.

Acceptance gate:
- measurements are reproducible and hardware-specific;
- no unsupported claim such as “faster than Linux” appears;
- each optimization has before/after evidence;
- performance budgets do not conceal regressions in battery life, heat, compatibility or stability.

## Phase 6 — User environment and desktop profiles

**Goal:** Provide a usable graphical experience without forcing a heavy default stack.

Tasks:
1. Establish Xorg + Xfce as the first full desktop baseline for broad compatibility.
2. Keep desktop components modular: display server, window manager/session, panel, file manager, settings, terminal, network UI, audio UI.
3. Evaluate a separate `legacy` lightweight session only after measuring Xfce on 2 GB hardware. Select the lightest usable option based on evidence (for example Openbox-based session), not assumptions.
4. Ensure basic setup can be completed graphically: user, network, display, audio, time, power, updates and storage.
5. Add a file manager, terminal, text editor, archive utility and browser selection appropriate to available resources.
6. Do not auto-start indexing, telemetry, sync or background helpers unless justified and documented.
7. Test accessibility, font rendering, HiDPI scaling and keyboard navigation where applicable.
8. Treat Wayland as an optional later profile until target hardware and desktop components are validated.

Deliverables:
- `DESKTOP_ARCHITECTURE.md`;
- usable desktop profile in QEMU and on physical hardware;
- service and autostart audit;
- desktop benchmark report.

Acceptance gate:
- graphical login works on the declared supported GPU set;
- Wi-Fi, sound, touchpad, brightness and power controls work where supported;
- users can perform basic tasks without the terminal;
- desktop does not cause unacceptable regression on the 2 GB target compared with the measured baseline.

## Phase 7 — Package format and package manager

**Goal:** Create a safe, auditable installation/update mechanism after the base OS is stable.

Tasks:
1. Write `PACKAGE_FORMAT.md` before coding.
2. Define package metadata: name, version, architecture, dependencies, conflicts, files, license, source, checksums, signature, build recipe and install size.
3. Use a documented archive format (for example tar + zstd) and signed repository metadata.
4. Design database schema for installed packages and file ownership.
5. Implement offline parser/validator first; then dependency resolver; then install/remove/list/query; then repository sync.
6. Use Rust for the package-manager implementation if justified by toolchain availability; keep the package manager itself small and auditable.
7. Avoid arbitrary package install shell scripts initially. If hooks are later required, define a constrained, reviewed hook model.
8. Stage installs into a temporary root and detect file conflicts before modifying the live root.
9. Test interrupted installs, corrupt archives, invalid signatures, dependency cycles, conflicting files, downgrade and recovery.
10. Never use the package manager to modify the host system during development; test against disposable target rootfs images.

Deliverables:
- package format specification;
- package manager CLI/library;
- signed local test repository;
- package database and integration tests;
- package recipes for a small representative package set.

Acceptance gate:
- install/remove/query works on a disposable target image;
- signatures and checksums are enforced;
- conflict and interrupted-operation tests pass;
- no untrusted package can silently execute arbitrary privileged scripts.

## Phase 8 — Security, update and recovery design

**Goal:** Preserve system integrity and make updates recoverable.

Tasks:
1. Document trust boundaries and threat model.
2. Establish repository signing keys and a safe key-rotation/revocation policy. Never store private release keys in the repository or agent context.
3. Verify signed metadata and package payload hashes.
4. Define update transaction semantics, interrupted-update behavior and recovery procedure.
5. Add system hardening only where it does not break hardware or usability: least privilege, capabilities, sensible sysctl defaults, namespaces/seccomp where applicable, firewall defaults and service sandboxing.
6. Evaluate AppArmor/LSM policy as a later controlled feature, not a blanket untested configuration.
7. Add recovery environment and a documented rollback procedure. Do not claim atomic rollback until tested.
8. Test corrupted metadata, expired/rotated keys, interrupted updates and failed boot recovery.

Deliverables:
- `SECURITY_MODEL.md`;
- `UPDATE_AND_RECOVERY.md`;
- key-management documentation;
- security/integrity tests.

Acceptance gate:
- update verification is enforced;
- interrupted update/recovery has tested behavior;
- release keys are not present in source control;
- security hardening does not silently disable critical hardware functionality.

## Phase 9 — Installer and bootable ISO

**Goal:** Deliver a live/installable image without risking user data.

Tasks:
1. Build a live ISO that can boot in QEMU using UEFI and BIOS configurations where supported.
2. Add an installer that supports guided/manual partitioning, bootloader setup, users, locale, timezone, keyboard and desktop profile.
3. Default to non-destructive inspection; show a clear disk/partition summary before any write.
4. Require explicit user confirmation immediately before formatting or writing a partition table.
5. Add install log, failure handling, validation and recovery guidance.
6. Test only on disposable QEMU disk images until the installer is proven safe.
7. Test installation to a blank image and an image containing data/partitions that must be preserved.
8. Test both UEFI/GPT and legacy BIOS/MBR paths if included in the support promise.

Deliverables:
- ISO build pipeline;
- live environment;
- installer;
- installation/recovery manual;
- QEMU installer test suite.

Acceptance gate:
- image boots repeatedly in QEMU;
- clean install completes on disposable images;
- installer refuses ambiguous/destructive operations without confirmation;
- existing data preservation behavior is tested and documented;
- live image and installed system both pass core smoke tests.

## Phase 10 — Controlled kernel development

**Goal:** Add genuinely project-owned kernel work without destabilizing the distribution.

Tasks:
1. Establish a separate upstream tracking branch and project patch branch.
2. Add patch metadata: problem, rationale, affected subsystem, upstream status, risks, benchmark/test plan, rollback procedure.
3. Start with low-risk, measurable improvements: configuration, diagnostics, build-time options, or a contained driver fix.
4. Profile scheduler, memory, storage and wakeup behavior before proposing algorithm changes.
5. Prototype risky scheduler/memory changes behind explicit experimental config options and in a separate kernel build.
6. Run kernel selftests, relevant subsystem tests, stress tests and boot/hardware regression matrix.
7. Keep a known-good upstream kernel available as fallback.
8. Submit generally useful fixes upstream where appropriate; avoid carrying needless permanent patches.

Deliverables:
- kernel patch policy and patch series;
- benchmark/test evidence per patch;
- experimental kernel build separate from stable kernel;
- fallback boot entry.

Acceptance gate:
- every patch has evidence and rollback;
- stable kernel boots and passes compatibility tests;
- experimental features are opt-in;
- no performance claim is made without a before/after report.

## Phase 11 — Release engineering and maintenance

**Goal:** Turn the project into a maintainable distribution.

Tasks:
1. Define version scheme, release channels and support windows.
2. Automate linting, source-lock validation, recipe tests, package tests and QEMU smoke boot in CI.
3. Keep full builds on suitable self-hosted hardware or controlled build workers; do not pretend a lightweight CI job performed a full LFS build.
4. Produce checksums, signed release metadata, source manifests, SBOM/license notices and known-issues list.
5. Publish installation instructions and hardware compatibility notes.
6. Define kernel/security update cadence and end-of-life policy.
7. Validate upgrade path between at least two test releases before declaring stable.

Deliverables:
- `RELEASE_POLICY.md`;
- CI pipeline;
- release scripts and artifacts;
- SBOM/license report;
- release notes and support matrix.

Acceptance gate:
- clean documented build and installation path;
- signed release artifacts and checksums;
- hardware/performance test evidence attached to release;
- upgrade and recovery procedures tested;
- no unverified compatibility claims.

## Cross-phase rule

A phase is complete only when its acceptance gate is evidenced. A successful compilation alone is not sufficient. If a phase is blocked, report the exact blocker and safe next action; do not silently skip the gate.
