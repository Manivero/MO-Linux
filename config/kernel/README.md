# config/kernel/ — kernel configuration directory (Phase 0 stub)

This directory will hold kernel configurations per profile. In Phase 0 it is intentionally empty except for this README; the first real configs are produced in Phase 3.

## Files planned (Phase 3)

- `legacy.config`     — kernel config for the Legacy profile (2 GB RAM, HDD).
- `standard.config`   — kernel config for the Standard profile (4 GB RAM, SSD).
- `extended.config`   — kernel config for the Extended profile (8 GB+ RAM, NVMe).
- `qemu-common.config` — baseline shared by all QEMU tests.

## Rules (per `KERNEL_POLICY.md` and ADR-0006)

- Each config starts from a verbatim `make defconfig` of the pinned LTS source.
- `localmodconfig` is **forbidden** for release kernels.
- `-march=native` is **forbidden** for release kernels.
- Configurations are reviewed with `make olddefconfig` (no unrequested changes) and `scripts/diffconfig` between versions.

## Status

- **Planned.** No config files exist yet.
