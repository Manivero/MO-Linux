# TESTING_STRATEGY — уровни тестирования и гейты фаз

Статус: **Implemented** (спецификация; рекреирован 2026-10-31 после recycle песочницы).

## 1. Уровни тестирования

| Уровень | Где | Что проверяется | Гейт для |
|---|---|---|---|
| **L0** | sandbox / build VM | lint, syntax, self-test | code quality |
| **L1** | build VM | build verification (compiles) | each package |
| **L2** | build VM | reproducibility (rebuild diff) | S4 |
| **L3** | build VM (QEMU) | boot to login, console works | Phase 2 (S7) |
| **L4** | build VM (QEMU) | services, RAM, disk, network | Phase 3 |
| **L5** | physical hardware | HW tests (HARDWARE_TEST_PLAN) | Phase 4/5 |

**QEMU ≠ hardware.** Уровни L3/L4 не претендуют на аппаратную совместимость; это явное условие владельца.

## 2. Матрица тестов по фазам

| Фаза | Уровень | Тесты | Артефакт |
|---|---|---|---|
| Phase 2 (S0) | L0 | host-version-check, lfs-safety self-test, adr-lint | readiness report |
| Phase 2 (S2) | L1 | sources SHA256 verification | sources.lock updated |
| Phase 2 (S3) | L1+L2 | temp toolchain compiles; $LFS_TGT-gcc hello.c | Verified Build |
| Phase 2 (S4) | L1+L2 | ~70 LFS packages compile; rebuild diff = 0 | Verified Build |
| Phase 2 (S5) | L1 | kernel 6.18.59 builds; file vmlinuz-* OK | Verified Build |
| Phase 2 (S6) | L1 | initramfs generates; GRUB installs on virtual disk | Verified Build |
| Phase 2 (S7) | L3 | QEMU boot to login (BIOS; UEFI опц.) | Verified QEMU |
| Phase 2 (S8) | L3 | 10 checks: console, CPU, RAM, disk, systemd, journal | Verified QEMU |
| Phase 3 | L4 | modular kernel config; UEFI+OVMF boot; serial console | Verified QEMU |
| Phase 4 | L5 | target hardware boot (i5-3320M laptop) | Verified Hardware |
| Phase 5 | L5 | bench: idle RAM, boot time, disk IO | measurements |
| Phase 8 | L3+L5 | A/B tests (если ADR-0008 утверждён): ab-commit, ab-fallback, FT-1..FT-6 | Verified QEMU + Hardware |

## 3. Гейты фаз (Phase exit criteria)

| Фаза | Гейт | Критерий |
|---|---|---|
| Phase 2 | S8 OK | QEMU boot to login + 10 checks pass; REPORT.md готов |
| Phase 3 | modular kernel + UEFI boot | QEMU OVMF boot OK; kernel config documented |
| Phase 4 | HW boot | at least 1 target laptop boots to login (i5-3320M) |
| Phase 5 | bench complete | idle RAM, boot time, disk IO measured on HW |
| Phase 6 | desktop profile | Xfce loads, basic apps work |
| Phase 7 | package manager | ADR-0007-rev1 chosen; PACKAGE_FORMAT implemented |
| Phase 8 | A/B (если утверждён) | FT-1..FT-6 verified in QEMU + 30 cycles on HW |
| Phase 9 | installer + live ISO | installation completes; live ISO boots |

## 4. Тест-скрипты

| Скрипт | Что тестирует | Фаза |
|---|---|---|
| `scripts/host-version-check.sh` | LFS-required tools presence | S0 (Phase 2) |
| `scripts/lib/lfs-safety.sh --self-test` | lfs-safety library | S0 (Phase 2) |
| `scripts/adr-lint.py` | ADR structure | ongoing |
| `scripts/sources-verify.py` | sources.lock URLs | S0 (Phase 2) |
| `scripts/disk-budget.py` | disk budget calculations | ADR-0008 gate G6 |
| `scripts/bench/idle-ram.sh` | idle RAM | Phase 5 |
| `scripts/bench/boot-time.sh` | boot time | Phase 5 |
| `scripts/bench/disk-io.sh` | disk IO | Phase 5 |
| `scripts/hardware-inventory.sh` | HW inventory (recreated) | Phase 4 prep |
| `tests/qemu-boot.sh` (planned) | QEMU boot | Phase 2 S7 |
| `tests/ab-commit.sh` (planned) | A/B commit | Phase 8 |
| `tests/ab-fallback.sh` (planned) | A/B fallback | Phase 8 |

## 5. Статусы (per §5 Project Initiation v2)

- **Planned** — описано в плане, не начато.
- **Implemented** — код/конфиг существует, не проверено.
- **Verified (build)** — собирается воспроизводимо.
- **Verified (QEMU)** — загружается в QEMU и проходит тесты.
- **Verified (hardware)** — проверено на реальном железе, с записью модели.

## 6. Связанные документы

- `docs/HARDWARE_TEST_PLAN.md` — HW-тесты (Phase 4+).
- `docs/HARDWARE_INVENTORY.md` — процедура инвентаризации (рекреирован).
- `scripts/hardware-inventory.sh` — скрипт инвентаризации (рекреирован).
- `PHASE2_PLAN.md` — детальный план S0–S8.
