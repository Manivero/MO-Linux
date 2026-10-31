# ADR-0003 — Bootloader

- **Status:** Proposed (pending owner approval)
- **Date:** 2026-10-30
- **Phase origin:** Phase 0
- **Decision owner:** Project owner (§8 — affects hardware compatibility)
- **Confidence:** Hypothesis

## Context

§6 of Project Initiation v2 requires «GRUB vs systemd-boot vs syslinux — BIOS и UEFI, старое железо, Secure Boot». The target hardware includes pre-2010 laptops that boot only via legacy BIOS, modern laptops with UEFI, and a small set with UEFI + Secure Boot.

## Options considered

| Option | BIOS | UEFI | Secure Boot | Multi-OS chainload | Maintenance | LFS support |
|---|---|---|---|---|---|---|
| **GRUB 2** | yes (i386-pc) | yes (x86_64-efi) | via shim or MOK enrollment | strong | medium | first-class |
| **systemd-boot** | no (UEFI only) | yes | yes (built-in) | weak (only EFI entries) | low | manual |
| **syslinux / isolinux** | yes | partial (extlinux) | no | weak | low | first-class |

GRUB supports both boot modes from a single install and is the LFS 13.1 default (`grub-2.14.tar.xz` verified 2026-10-30). systemd-boot requires UEFI — it would exclude pre-2012 target hardware outright. syslinux is great for live ISOs but weak for installed systems with complex boot configurations.

## Decision

Adopt **GRUB 2.14** as the project bootloader, supporting both **legacy BIOS** and **UEFI**. Secure Boot is **out of scope for the first release**; users with Secure-Boot-only firmware will see a documented limitation. (Phase 8 will revisit; a signed shim path is the likely answer but requires key-management infrastructure.)

## Rationale

1. Hardware compatibility (§2 #4) demands supporting both BIOS and UEFI on the same target pool. GRUB is the only option here.
2. Boot reliability (§2 #1) — GRUB is mature, well-tested, and the LFS default. Custom boot configurations are easy to write and inspect.
3. systemd-boot's strict UEFI-only constraint would exclude the Legacy target profile (where most machines are pre-UEFI).
4. Secure Boot is deferred because: (a) it requires a signed shim or a self-enrolled MOK; (b) it interacts with the update trust chain (Phase 8); (c) most legacy laptops have Secure Boot off or unsupported.

## Consequences

- Positive: single bootloader config for BIOS+UEFI; LFS instructions unchanged.
- Negative: GRUB config is sometimes fragile across kernel updates; the update flow (Phase 8) must include a "GRUB config regenerate" step with a fallback to the previous menu entry.
- Risks: Secure Boot locked-out users on modern firmware cannot boot — must be clearly stated in supported-hardware matrix.

## Revisit triggers

- Owner asks for Secure Boot support → spawn ADR-0008 (Secure Boot policy) and update this ADR's Secure Boot status.
- A recurring class of GRUB update regressions on target hardware (>= 2 incidents) → evaluate systemd-boot for UEFI-only machines.

## Verification plan

- **Verified (build):** build GRUB 2.14 from LFS 13.1-systemd instructions (Phase 2).
- **Verified (QEMU):** QEMU boots via both `qemu-system-x86_64 -bios OVMF.fd` (UEFI) and the SeaBIOS default (BIOS) (Phase 3).
- **Verified (hardware):** at least one BIOS-only Legacy target and one UEFI target boot to a login prompt (Phase 4).
