# Initial architecture (Phase 0 sketch)

This is the Phase 0 sketch of the system architecture. Detailed component-by-component design lands in Phase 1 (`docs/ARCHITECTURE.md` will be expanded there).

## 1. Layered view

```
+--------------------------------------------------------------+
|  User applications                                           |
|  (Xfce, terminal, browser, file manager, ...)               |
+--------------------------------------------------------------+
|  Desktop environment / display server                        |
|  (Xorg + Xfce; Wayland optional later)                       |
+--------------------------------------------------------------+
|  System services                                             |
|  (NetworkManager, PipeWire, BlueZ, logind, udev, dbus, ...)  |
+--------------------------------------------------------------+
|  Init / service manager                                      |
|  (systemd 261.2)                                             |
+--------------------------------------------------------------+
|  C library                                                   |
|  (glibc 2.44)                                                |
+--------------------------------------------------------------+
|  Linux kernel (6.18.y LTS + project patch set, empty in Ph0) |
+--------------------------------------------------------------+
|  Bootloader (GRUB 2.14, BIOS + UEFI)                         |
+--------------------------------------------------------------+
|  Firmware (BIOS or UEFI on target hardware)                  |
+--------------------------------------------------------------+
```

## 2. Dependency direction

```
build host (Debian 13)
        |
        v
cross-toolchain (gcc/binutils built for target, Phase 2)
        |
        v
target rootfs (glibc + systemd + coreutils + ...)
        |
        v
target kernel (linux-6.18.59.y)
        |
        v
bootable image (GRUB + kernel + rootfs)
        |
        v
QEMU (Phase 3) --> physical hardware (Phase 4+)
```

The build host never writes to a physical block device. Output artifacts (rootfs tarball, kernel image, ISO) are produced in `build/` and consumed by QEMU on disposable disk images.

## 3. Module boundaries (repository layout)

| Path | Module | Owner phase |
|---|---|---|
| `docs/` | All documentation, ADRs, audit, env, hardware test plan | Phase 0 |
| `docs/reference/` | Verbatim copies of the AI kit files (read-only reference) | Phase 0 |
| `docs/adr/` | Architecture Decision Records | Phase 0+ |
| `docs/devices/` | Per-device hardware sheets | Phase 4 |
| `docs/reports/` | Past REPORT.md snapshots | Phase 0+ |
| `scripts/` | Host check, build helpers, bench scripts | Phase 0+ |
| `scripts/lib/` | Shared shell libraries (LFS safety, logging) | Phase 0+ |
| `scripts/bench/` | Benchmark scripts (boot, RAM, I/O) | Phase 0 |
| `config/kernel/` | Kernel configs per profile | Phase 0 (stubs), Phase 3 (real) |
| `config/system/` | System-wide configs (sysctl, systemd units, locales) | Phase 0 (stubs), Phase 6 (real) |
| `tests/` | Unit + integration test scripts | Phase 0 (skeleton) |
| `bench/results/` | Raw benchmark outputs (raw data; summaries only in git) | Phase 0+ |
| `sources.lock` | Pinned source manifest (versions, URLs, SHA256, sig status) | Phase 0 (kernel + LFS core), Phase 2 (full) |
| `Makefile` | Single entry point for `make check`, `make bench`, `make sources-verify` | Phase 0 |
| `.github/workflows/ci.yml` | CI config (no pushes) — runs shellcheck + Makefile checks | Phase 0 |

## 4. Boot flow (high level)

```
power on
  -> firmware (BIOS / UEFI)
     -> GRUB stage 1 / EFI executable
        -> GRUB stage 2 (config from /boot/grub/grub.cfg)
           -> load Linux kernel + initramfs (initramfs deferred to Phase 3.5)
              -> kernel: mount rootfs (ext4 on /dev/sda2 or A/B slot)
                 -> systemd as PID 1
                    -> default target: multi-user.target (CLI) or graphical.target (Xfce)
                       -> login
```

Detailed boot/recovery design lives in `BOOT_AND_RECOVERY.md` (Phase 1 deliverable).

## 5. Update flow (high level sketch; full design in Phase 8)

```
repository (signed metadata + signed packages)
  -> package manager (Phase 7) downloads to staging area
     -> signature + hash verification
        -> transactional install OR A/B slot swap
           -> on success: commit (rename / mark slot active) and reboot
           -> on failure: rollback to previous state
```

The flow is intentionally hand-wavy here because the package manager is a deferred decision (ADR-0007).

## 6. Open architectural questions (recorded; not blocking)

These questions are noted here and resolved in later phases. Each has a stub document or ADR reference.

- **Secure Boot policy** — see ADR-0003 (deferred).
- **CVE tracking process** — see `KERNEL_POLICY.md` §7 (sketch; full process in Phase 8).
- **Rollback strategy** (A/B vs Btrfs snapshots) — deferred to Phase 8, ADR-0005 records ext4+A/B as the working hypothesis.
- **Localization scope (ru/en)** — Phase 6 will decide which locales are first-class.
- **Installer requirements** — Phase 9.
- **GPL offer / source redistribution** — Phase 11 (release engineering). A stub `docs/GPL_COMPLIANCE.md` will be added at Phase 1.

## 7. Phase 0 architecture deliverable status

| Deliverable | Status |
|---|---|
| This document (initial architecture sketch) | Implemented |
| ADRs for init, libc, bootloader, DE, FS, kernel, package manager | Implemented (7 ADRs) |
| Profiles + compatibility matrix | Implemented (`TARGET_HARDWARE.md`) |
| Hardware test plan | Implemented (`docs/HARDWARE_TEST_PLAN.md`) |
| Boot flow sketch | Implemented (§4 above; full doc deferred to Phase 1) |
| Update flow sketch | Implemented (§5 above; full doc deferred to Phase 8) |
| Per-device sheets | Planned (awaiting owner-provided hardware) |
| BOOT_AND_RECOVERY.md | Planned (Phase 1) |
| SYSTEM_SERVICES.md | Planned (Phase 1) |
| BUILD_SYSTEM.md | Planned (Phase 2) |
| SECURITY_MODEL.md | Planned (Phase 8) |
| PACKAGE_FORMAT.md | Planned (Phase 7 entry) |
| TESTING_STRATEGY.md | Planned (Phase 1) |
| RELEASE_POLICY.md | Planned (Phase 11) |
| PERFORMANCE_BUDGET.md | Planned (Phase 5) |
