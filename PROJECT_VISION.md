# Project vision

This document is the Phase 0 product brief: goals, target users, non-goals. It is the authoritative reference for scope disputes; ADRs and the roadmap defer to it.

## 1. What we are building

A **source-based**, lightweight, x86_64 Linux distribution built on Linux From Scratch (LFS) 13.1-systemd as the bootstrap method. It is a **genuine own distribution** — own build infrastructure, own kernel patch set, own profiles — not a rebrand of Debian, Ubuntu, Kali, or Arch.

The end-state product:

- boots reliably on legacy x86_64 laptops (BIOS and UEFI);
- uses low idle RAM and stays responsive under normal desktop load;
- supports a broad set of legacy hardware (Intel/AMD iGPUs, SATA HDD/SSD, NVMe, Wi-Fi, Bluetooth, audio, touchpad, ACPI, suspend/resume);
- has a usable Xfce desktop and an optional CLI-only profile;
- updates safely (signed repository, transactional or A/B rollback);
- has documented architecture and a reproducible build pipeline;
- permits controlled kernel patch development where measurable benefit exists.

## 2. Target users

- Owners of 5–15-year-old laptops who want a responsive, low-overhead Linux that "just works" for browsing, email, document editing, and light development.
- Tinkerers and students who want a transparent, source-built system they can read and modify.
- (Secondary) Engineers building controlled kernel experiments on a stable base.

## 3. Target hardware classes (Phase 0 hypotheses; revisit in Phase 5)

| Profile | CPU | RAM | Disk | Intent |
|---|---|---|---|---|
| Legacy | x86_64, 2 cores, pre-2010 Intel/AMD | 2 GB | SATA HDD (80–320 GB) | Minimal desktop on old laptop |
| Standard | x86_64, 2–4 cores, 2010–2018 Intel/AMD | 4 GB | SATA SSD | Primary profile |
| Extended | x86_64, 4+ cores, modern | 8 GB+ | NVMe SSD | Headroom, modern hardware |

Detailed per-device sheets live in `TARGET_HARDWARE.md`. All three are **hypotheses**, not guarantees: numerical budgets for idle RAM and boot time are measured in Phase 5, not invented in Phase 0.

## 4. Non-goals (per §3 of `AI_MASTER_PROMPT.md`, confirmed)

- We do **not** write a new kernel from scratch.
- We do **not** rewrite scheduler, MM, VFS, network stack, drivers, libc, compiler, or init before a working baseline + profiling exist.
- We do **not** claim "faster than X" without same-hardware benchmark evidence.
- We do **not** promise modern browsers on 2 GB RAM.
- We do **not** use `-march=native` for release binaries.
- We do **not** use `localmodconfig` for the generic release kernel.
- We do **not** add overlapping power-management or network daemons without justification.
- We do **not** implement a custom package manager before the package lifecycle requirements and threat model are documented.
- We do **not** support 32-bit CPUs or unusual 32-bit UEFI in the first release.
- We do **not** support non-x86_64 architectures in the first release.

## 5. Project priorities (per §2 of Project Initiation v2)

In conflict, the **higher-numbered** priority wins:

1. Reliability and safety of updates — the system must not brick.
2. Performance and responsiveness.
3. Low RAM consumption.
4. Hardware compatibility.
5. Fast boot and minimal background load.
6. Usability of everyday work.
7. Modularity and reproducibility of the build.
8. Own kernel development — only with measurable benefit.

## 6. Success criteria (per §16 of Project Initiation v2)

The project is successful if the resulting system:

- is reproducibly built from pinned sources;
- boots quickly;
- uses RAM economically;
- is responsive on legacy computers;
- supports a broad hardware set;
- has a usable GUI;
- updates safely and rolls back safely;
- has documented architecture and own build infrastructure;
- permits measurable kernel modifications where justified.

The primary metric is **a real, working system**, not the volume of plans and documentation.
