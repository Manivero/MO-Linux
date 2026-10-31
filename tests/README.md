# tests/ — test directory (Phase 0 skeleton)

This directory holds project-specific tests that go beyond what `scripts/`
already does. In Phase 0 the only "tests" are:

- `scripts/lib/lfs-safety.sh --self-test` — safety library self-test
- `scripts/host-version-check.sh`        — host meets LFS prereqs
- `scripts/sources-verify.py`            — every URL in sources.lock is reachable
- `scripts/adr-lint.py`                  — every ADR has the required sections

All of those are run via `make check` (see `../Makefile`).

## Files planned (later phases)

- `tests/build-reproducibility.sh` — Phase 2: build the same source twice and compare hashes.
- `tests/qemu-boot.sh`              — Phase 3: boot the kernel in QEMU and assert login prompt.
- `tests/qemu-shutdown.sh`          — Phase 3: assert clean shutdown / reboot.
- `tests/hw-*`                       — Phase 4: per-device hardware tests (see `docs/HARDWARE_TEST_PLAN.md`).
- `tests/package-manager/`          — Phase 7: package-manager integration tests.

## Status

- **Planned.** No tests in this directory yet; current tests live in `scripts/`.
