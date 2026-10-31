# Module: installer

Stub directory. Contents will be added in later phases.

## Purpose

Installer module — live ISO and installer (Phase 9).
Will contain:
- iso-build.sh — xorriso wrapper to build hybrid BIOS+UEFI ISO
- installer.sh — interactive installer (partition, copy rootfs, install GRUB)
- recovery.sh — recovery mode (fsck, chroot, reinstall GRUB, slot rollback)

Status: Planned (Phase 9).
Depends on: ADR-0008 (Proposed) — installer needs to know A/B layout if approved.
