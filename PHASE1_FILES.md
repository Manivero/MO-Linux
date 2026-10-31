# PHASE1_FILES — полный список рекреированных файлов Phase 1

Статус: **Implemented** (2026-10-31; рекреация после recycle песочницы; проверка 9+2+1+2+8=22).

## Сводка

**22 файла рекреировано** из Phase 1 (утрачены при recycle песочницы).

| Категория | Кол-во | Строк (сумма) |
|---|---|---|
| Top-level дизайн-документы | 9 | 886 |
| docs/ файлы | 2 | 254 |
| ADR | 1 | 187 |
| Scripts | 2 | 316 |
| Module stubs | 8 | 8 × ~50 = 400 |
| **Итого** | **22** | **~2043** |

Проверка арифметики: 9 + 2 + 1 + 2 + 8 = **22** (в более раннем сообщении в разговоре была ошибка «21» в заголовке отчёта при корректных данных в таблице; несоответствие устранено).

## Полный список (по категориям)

### 1. Top-level дизайн-документы (9 файлов)

| # | Файл | Строк | Содержимое |
|---|---|---|---|
| 1 | `BUILD_SYSTEM.md` | 99 | спецификация сборки LFS (роли, стадии S0–S8, каталоги, воспроизводимость, безопасность) |
| 2 | `BOOT_AND_RECOVERY.md` | 108 | цепочка загрузки, разметка (базовая + A/B), GRUB config, initramfs, recovery-процедуры |
| 3 | `SYSTEM_SERVICES.md` | 67 | инвентаризация системных служб по профилям (core/desktop/extended), RAM-оценки |
| 4 | `TESTING_STRATEGY.md` | 78 | уровни L0–L5, матрица тестов по фазам, гейты фаз, тест-скрипты |
| 5 | `SECURITY_MODEL.md` | 81 | границы доверия, 10 угроз (SEC-1..SEC-10), CVE-процесс, криптография |
| 6 | `PACKAGE_FORMAT.md` | 128 | формат .lpkg, metadata.json schema, hooks whitelist, атомарность, БД пакетов |
| 7 | `UPDATE_ROLLBACK.md` | 119 | state machine транзакции, health check, 9 сценариев прерывания, тест-план Phase 8 |
| 8 | `RELEASE_POLICY.md` | 86 | версии (SemVer), каналы (stable/testing/unstable), критерии, security-cadence, подписи, EOL |
| 9 | `GPL_COMPLIANCE.md` | 108 | обязательства GPL, source offer (3 варианта), firmware-режим, retention, license manifest |

### 2. docs/ файлы (2 файла)

| # | Файл | Строк | Содержимое |
|---|---|---|---|
| 10 | `docs/CODING_CONVENTIONS.md` | 147 | языковая политика (§15, AUDIT-013), bash/python/Makefile/Markdown/git style |
| 11 | `docs/HARDWARE_INVENTORY.md` | 107 | процедура инвентаризации (12 категорий), карточка устройства, предварительная совместимость i5-3320M |

### 3. ADR (1 файл)

| # | Файл | Строк | Статус | Содержимое |
|---|---|---|---|---|
| 12 | `docs/adr/0008-update-rollback-ab.md` | 187 | **Proposed** | 5 схем для сравнения (A/B partitions ext4, single-root+recovery, OSTree, image-based, Btrfs snapshots); 7 gate-conditions G1–G7; failure scenarios FT-1…FT-6 **PLANNED, не VERIFIED**; порог 64 GB **не утверждён**; grubenv snapshot в /var **не утверждён** |

**Примечание:** ADR-0008 рекреирован в **упрощённой форме** (187 строк) по сравнению с оригиналом Phase 1 (~700 строк). Рекреированная версия сохраняет все ключевые решения владельца, но не включает детальный разбор GRUB env block по подразделам (4.7.1–4.7.7), layout /boot с 8 инвариантами, сводную матрицу FT-1…FT-6 с тест-планом. Если потребуется детальный анализ до Phase 8 — будет расширен.

### 4. Scripts (2 файла)

| # | Файл | Строк | Содержимое |
|---|---|---|---|
| 13 | `scripts/hardware-inventory.sh` | 122 | read-only инвентаризация железа, 12 категорий, smoke-тест OK (26 raw-файлов в sandbox) |
| 14 | `scripts/disk-budget.py` | 194 | расчёт disk budget для A/B / single-root+recovery / image-based; 3 layout × 4 disks = 16 rows; пометка «64 GB threshold не утверждён» |

### 5. Module stubs (8 файлов)

Каждый README описывает содержимое будущих фаз:

| # | Файл | Содержимое |
|---|---|---|
| 15 | `bootstrap/README.md` | temp toolchain build scripts (Phase 2 S3) |
| 16 | `kernel/README.md` | Linux 6.18.59 LTS configs (Phase 2 S5) |
| 17 | `system/README.md` | base LFS system configs (Phase 2 S4) |
| 18 | `desktop/README.md` | Xorg + Xfce config (Phase 6) |
| 19 | `hardware/README.md` | device-specific configs (Phase 4) |
| 20 | `installer/README.md` | live ISO + installer (Phase 9) |
| 21 | `package-manager/README.md` | .lpkg manager (Phase 7) |
| 22 | `build-system/README.md` | LFS build orchestrator (Phase 2) |

## Не включены в «рекреированные Phase 1» (были утрачены, но созданы заново в других циклах)

| Файл | Цикл создания | Статус |
|---|---|---|
| `docs/BUILD_ENV_SETUP.md` | Phase 2 Build Environment | Implemented (v3) |
| `docs/adr/0009-build-environment-vm.md` | Phase 2 Build Environment | Accepted |
| `PHASE2_PLAN.md` | Phase 2 Build Environment | Implemented |

Эти 3 файла НЕ считаются «рекреированными Phase 1», так как относятся к Phase 2 подготовке, а не к Phase 1 анализу A/B-схемы.

## Backup (за пределами sandbox) — ФИНАЛЬНЫЙ, Phase 1 restoration закрыт

| Файл | Размер (≈) | Содержимое |
|---|---|---|
| `lightweight-linux-distro-phase1-final-20261031T092620Z.tar.gz` | ≈140 КБ | 67 файлов + 22 каталога = 89 записей |
| `lightweight-linux-distro-phase1-final-20261031T092620Z.zip` | ≈177 КБ | то же в zip |

Числа записей указаны относительно корня `distro/` (сам корневой каталог архива не считается). Контрольные суммы — в `SHA256SUMS` рядом с архивами (см. также PROJECT_STATUS.md).

Финальная проверка закрытия Phase 1 restoration (2026-10-31, требование владельца):
- сверка состава: рабочий репозиторий = ZIP = TAR.GZ — **67 файлов + 22 каталога, попозиционно идентичны** (скрипт `scripts/phase1_final_check.py` в песочнице; exit 0);
- `unzip -t` → exit 0 (OK); `tar -tzf` → exit 0 (OK); `gzip -t` → exit 0 (OK);
- `PHASE1_FILES.md` присутствует в обоих архивах (проверено через `unzip -l` / `tar -tzf`);
- `bash -n` — все 6 shell-скриптов (`lfs-safety.sh`, `hardware-inventory.sh`, `host-version-check.sh`, `bench/boot-time.sh`, `bench/idle-ram.sh`, `bench/disk-io.sh`) → exit 0;
- `sha256sum -c SHA256SUMS` → 2/2 OK (exit 0).

**Отличия от промежуточного бэкапа 20261031T091235Z (87 записей):** добавлены `bench/results/README.md` и `bench/results/host-version-check-20261030T110027Z.txt` (test evidence Phase 0 — были ошибочно исключены из промежуточного архива); `scripts/__pycache__/*.pyc` удалён из рабочего репозитория (артефакт компиляции; в архивы не входит). Промежуточные пары 20261030T185344Z и 20261031T091235Z удалены после верификации финальной.

**Примечание:** 67 файлов в архиве — это **весь репозиторий** (Phase 0 + Phase 1 рекреация + Phase 2 подготовка), включая 3 файла Phase 2 подготовки. Число «22» — это только рекреированные Phase 1 файлы, а «67» — весь репозиторий в архиве.

## Что осталось сделать перед S1

- Ничего — Phase 1 восстановлен полностью (22 файла рекреированы + 3 файла Phase 2 подготовки = 25 новых файлов в этом цикле).
- Файлы Phase 1 готовы к использованию.
- Разница «оригинальный Phase 1 ADR-0008 ~700 строк» vs «рекреированный ADR-0008 ~187 строк» — при необходимости расширения до Phase 8 будет сделано.

## Связанные документы

- `docs/adr/0008-update-rollback-ab.md` — рекреированный ADR (Proposed).
- `docs/adr/0009-build-environment-vm.md` — Accepted ADR.
- `docs/BUILD_ENV_SETUP.md` — v3 финальная инструкция.
- `PHASE2_PLAN.md` — детальный план S0–S8.
- `IMPLEMENTATION_LOG.md` — записи циклов.
- `PROJECT_STATUS.md` — текущий статус.
