# Target hardware

This document defines the target hardware classes for the distribution and is the **only** place where individual target devices are recorded. It is distinct from `docs/ENVIRONMENT.md`, which describes the build host.

## 1. Profiles (Phase 0 hypotheses)

| Profile | CPU | RAM | Disk | Display | Network | Use case |
|---|---|---|---|---|---|---|
| **Legacy** | x86_64, 2 cores, pre-2010 Intel/AMD | 2 GB | SATA HDD (80–320 GB), 5400 rpm | 1366×768 TN | Wi-Fi 802.11n + Ethernet 100 Mbps | Minimal responsive desktop |
| **Standard** | x86_64, 2–4 cores, 2010–2018 Intel/AMD | 4 GB | SATA SSD (120–512 GB) | 1366×768 / 1920×1080 IPS | Wi-Fi 802.11n/ac + Ethernet 1 Gbps | Primary profile |
| **Extended** | x86_64, 4+ cores, 2018+ Intel/AMD | 8 GB+ | NVMe SSD (256 GB+) | 1920×1080+ | Wi-Fi 802.11ac/ax + Ethernet 1 Gbps | Modern hardware headroom |

These profiles are **target classes** for design and measurement, not promises. Numerical budgets (idle RAM, boot time, app launch latency) are derived from Phase 5 measurements, not invented here.

## 2. Minimum supported baseline (per Project Initiation v2 §3)

- Architecture: x86_64 generic (no `-march=native` for release binaries).
- 32-bit CPUs: explicitly **out of scope** for the first release.
- 32-bit UEFI (rare Atom-based laptops): explicitly **out of scope** for the first release.

## 3. Functional requirements (per Phase 0 task 6 of `IMPLEMENTATION_ROADMAP.md`)

For each profile, the system must support the following on hardware where the corresponding device is present:

- Boot (BIOS or UEFI, depending on the device's firmware mode).
- Display output (text console + graphical desktop).
- Storage (SATA, NVMe as applicable).
- Input (keyboard, touchpad with palm-reject and tap-to-click).
- Wi-Fi and Ethernet.
- Audio (output and microphone).
- Battery reporting and brightness control.
- Lid open/close, suspend/resume.
- USB (mass storage, HID).
- File manager, terminal, browser.
- Updates via the package manager (Phase 7+) — signed, with rollback.

## 4. Hardware compatibility matrix — first version

| Category | Subsystem / device class | Status (Phase 0) |
|---|---|---|
| CPU | Intel Core 2 / Sandy Bridge / Ivy Bridge / Haswell / Broadwell / Skylake / Kaby Lake / Coffee Lake / Ice Lake / Tiger Lake / Alder Lake | planned |
| CPU | AMD Athlon 64 / Phenom / A-series / Ryzen | planned |
| Boot | BIOS (SeaBIOS, AMI BIOS) | planned |
| Boot | UEFI (pre-2018 firmware, no Secure Boot enforcement) | planned |
| Boot | UEFI + Secure Boot | **deferred to Phase 8** (see ADR-0003) |
| GPU | Intel iGPU (i915 driver — i810 through Xe) | planned |
| GPU | AMD iGPU (amdgpu / radeon driver — TeraScale through RDNA2) | planned |
| GPU | NVIDIA legacy (nouveau; 340.x / 304.x closed-source drivers separately documented) | planned, partial |
| Storage | SATA HDD | planned |
| Storage | SATA SSD | planned |
| Storage | NVMe SSD | planned |
| Network | Ethernet (Realtek, Intel) | planned |
| Network | Wi-Fi (Intel, Atheros, Broadcom — closed-source Broadcom documented separately) | planned |
| Network | Wi-Fi (MediaTek, Ralink) | planned |
| Bluetooth | USB BT adapters (BlueZ) | planned |
| Audio | HDA codecs (Realtek, Conexant, Cirrus) | planned |
| Input | Touchpad (libinput / synaptics) | planned |
| Input | Keyboard, USB mouse | planned |
| Power | ACPI, brightness, battery reporting, suspend/resume | planned |
| Power | CPU frequency scaling (intel_pstate, acpi-cpufreq) | planned |
| Misc | Webcam (UVC) | planned |

**Status legend (per Project Initiation v2 §5):**

- **Planned** — described in design; not built / not tested.
- **Implemented** — code/config exists, not verified.
- **Verified (build)** — package compiles reproducibly.
- **Verified (QEMU)** — boots and passes tests in QEMU.
- **Verified (hardware)** — tested on a real device, with model recorded.

Everything in the matrix above is **Planned** as of Phase 0. No device has been tested.

## 5. Per-device sheets

The owner has not yet provided access to a target laptop. Therefore:

- **No specific target device is named in Phase 0.** This is recorded as a known risk in `PROJECT_STATUS.md`.
- When the owner provides access to a device (Phase 4 entry), a per-device sheet is added to `docs/devices/<model>.md` with: model name, CPU, RAM, storage, GPU, Wi-Fi chipset, audio codec, BIOS/UEFI mode, suspend/resume behavior, and a checklist of which features work / partially work / fail.

## 6. Open hardware questions for the owner

1. Is there a specific legacy laptop the owner wants the first release to target? Model name allows early driver-list research.
2. Is Wi-Fi Broadcom (closed-source driver) in scope for the first release, or deferred?

These questions are batched in `REPORT.md`.
