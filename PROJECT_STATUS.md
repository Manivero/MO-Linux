# PROJECT_STATUS

- Project: Lightweight Linux Distribution (own, source-based, x86_64)
- Current phase: **Phase 2 — AUTHORIZED, awaiting permanent Build VM** (Owner decision 2026-10-31: Option A — isolated Linux VM). **Phase 1 restoration: CLOSED (2026-10-31, финальная проверка пройдена)**. **Phase 2 docs audit 2026-11-02: contradictions S0/S1, snapshots, UEFI/BIOS, SSH/security — устранены (см. ниже).**
- Repository path: /home/z/my-project/download/distro
- Branch: локальный git re-init после recycle песочницы; **коммитов нет** (§10)
- Build host (текущая sandbox): Debian 13, 2 cores, 4 GB RAM, 9.3 GB disk — **НЕ является build-средой** (решение владельца Q3 + OWNER DECISION Phase 2: вариант B отклонён)
- Permanent build environment: target VM spec получен (Debian 13, 8 vCPU, 12–16 GB RAM, 40+60 GB disks, admin+lfs users, nested virt); инструкция развёртывания — `docs/BUILD_ENV_SETUP.md` v4 (отредактирована 2026-11-02); развёртывается владельцем
- Physical target hardware: предварительный Legacy-таргет — ноутбук с Intel Core i5-3320M; инвентаризация не проведена
- Pinned LFS/BLFS baseline: LFS 13.1-systemd (verified 2026-10-30)
- Pinned kernel baseline: Linux 6.18.59 LTS (verified 2026-10-30 via kernel.org/releases.json)

## Sandbox recycle note (2026-10-31) — RESOLVED

В ходе работы произошёл многократный recycle песочницы. Утрачены Phase 1 документы: BUILD_SYSTEM.md, BOOT_AND_RECOVERY.md, SYSTEM_SERVICES.md, TESTING_STRATEGY.md, SECURITY_MODEL.md, PACKAGE_FORMAT.md, UPDATE_ROLLBACK.md, RELEASE_POLICY.md, GPL_COMPLIANCE.md, docs/HARDWARE_INVENTORY.md, docs/CODING_CONVENTIONS.md, ADR-0008, ADR-0009, scripts/disk-budget.py, scripts/hardware-inventory.sh, 8 module stubs (bootstrap/, kernel/, system/, desktop/, hardware/, installer/, package-manager/, build-system/), а также обновления PROJECT_STATUS.md, IMPLEMENTATION_LOG.md, REPORT.md.

**Статус: RECREATED (этот цикл, 2026-10-31).** Все утраченные документы рекреированы с учётом owner-review решений (ADR-0008: 5 схем, 7 gate-conditions G1–G7, failure scenarios PLANNED, 64 GB threshold не утверждён, grubenv snapshot в /var не утверждён). ADR-0009 рекреирован как Accepted. 8 module stubs рекреированы. scripts/hardware-inventory.sh и scripts/disk-budget.py рекреированы.

**Полная резервная копия создана (ФИНАЛЬНАЯ, после закрытия Phase 1 restoration):**
- `/home/z/my-project/download/lightweight-linux-distro-phase1-final-20261031T092620Z.tar.gz` (≈140 КБ)
- `/home/z/my-project/download/lightweight-linux-distro-phase1-final-20261031T092620Z.zip` (≈177 КБ)
- **Состав: 67 файлов + 22 каталога = 89 записей** (относительно корня `distro/`); рабочий репозиторий, ZIP и TAR.GZ попозиционно идентичны (скрипт phase1_final_check.py, exit 0).
- `bench/results/` (README + host-version-check evidence Phase 0) включены; `scripts/__pycache__` удалён из репозитория.
- **Финальная проверка (2026-10-31):** `unzip -t` → exit 0; `tar -tzf` → exit 0; `gzip -t` → exit 0; `PHASE1_FILES.md` присутствует в обоих архивах; `bash -n` → 6/6 shell-скриптов exit 0; `sha256sum -c SHA256SUMS` → 2/2 OK.
- Контрольные суммы: `/home/z/my-project/download/SHA256SUMS`.
- Промежуточные бэкапы 20261030T185344Z (67 файлов, включая 3 артефакта `__pycache__/*.pyc` — дефект) и 20261031T091235Z (65 файлов, отсутствовали `bench/results/`) удалены после верификации финальной версии.

**Phase 1 restoration: CLOSED.** Восстановление документации прекращено; следующий шаг — отчёт владельца о готовности Build VM (`docs/BUILD_ENV_SETUP.md` §6.1).

BUILD_ENV_SETUP.md v4 (2026-11-02, аудит консистентности Phase 2): (1) S0/S1 разделены — S0 = host preflight без disk work, без /mnt/lfs, без lfs user; S1 = disk + workspace + lfs user + lfs-safety (с owner approval gate перед fdisk); (2) §6 snapshot table очищена от дубликатов (`before-S1` убран как дубликат `after-S0-preflight`); (3) §7.2 SSH/security — абсолютный запрет на передачу ИИ паролей/ключей, для S0 рекомендуется транзитивный доступ; (4) UEFI/OVMF явно отложен до Phase 3 (Phase 2 = BIOS/SeaBIOS path); (5) lfs user creation — идемпотентные проверки через `getent`/`id`, lfs в kvm только при наличии `/dev/kvm`.

BUILD_ENV_SETUP.md v3 (2026-10-31): Nested KVM НЕ обязательна; VMware/VirtualBox оба рекомендуются; QEMU TCG — полноценный fallback (не деградация): **пригоден для функциональной проверки загрузки, но НЕ для достоверных performance benchmarks** (TCG-тайминги искажены эмуляцией; benchmark-замеры — только KVM/реальное железо); никаких изменений Hyper-V/VBS/Memory Integrity/BCD/Defender/BIOS-настроек безопасности Windows.

BUILD_ENV_SETUP.md v2 (исправления владельца): lsblk-first disk identification (испр. #1), UUID в /etc/fstab (испр. #2), admin не в группе lfs без необходимости (испр. #3), lfs не в libvirt без обоснования (испр. #4), не требовать отключения Hyper-V/VBS (испр. #5), разделение build/test tools (испр. #6), TCG как first-class fallback (испр. #7).

Сохранены Phase 0 документы и скрипты (README, PROJECT_VISION, ARCHITECTURE, TARGET_HARDWARE, KERNEL_POLICY, sources.lock, Makefile, ADR-0001..0007, scripts/adr-lint.py, host-version-check.sh, sources-verify.py, scripts/bench/*, scripts/lib/lfs-safety.sh, .github/workflows, .gitignore).

## Phase 2 docs audit (2026-11-02)

**Scope:** устранить противоречия в последовательности подготовки Build VM, S0, S1 и дальнейших этапов; согласовать snapshots; выровнять инструкции по lfs user (идемпотентность); явно разделить BIOS/UEFI; ужесточить правила SSH/security (без передачи паролей/ключей).

**Файлы изменены:** PHASE2_PLAN.md, docs/BUILD_ENV_SETUP.md, docs/adr/0009-build-environment-vm.md, PROJECT_STATUS.md, IMPLEMENTATION_LOG.md.

**Ключевые изменения (по 5 проблемам владельца):**

| # | Проблема (было) | Решение (стало) |
|---|---|---|
| A | S0 требует /mnt/lfs + lfs-safety self-test + free space на /mnt/lfs — но это создаёт S1; круговая зависимость | **S0** = host preflight без disk work, без /mnt/lfs, без lfs user; **S1** = disk ID + partition + format + mount + lfs user + lfs env + lfs-safety. S0 → S1 → S2 без круговых зависимостей. S1 разбит на 5 подэтапов (S1.1–S1.5) с owner approval gate перед fdisk. |
| B | Snapshot table содержала дубликаты: `before-S1` = `after-S0-preflight` (между ними нет работы); `before-S2` не был привязан к S1 done | Snapshot table v4: 10 канонических snapshot'ов; `before-S1` убран как дубликат; `before-S2` явно = S1 done; каждому snapshot соответствует уникальное состояние VM. |
| C | `adduser lfs` не идемпотентен; `groupadd -f lfs` после `adduser` избыточен (Debian adduser создаёт группу автоматически); `usermod -aG kvm lfs` без проверки /dev/kvm | `sudo groupadd -f lfs` (idempotent на уровне утилиты; exit 0 и в случае существования группы, и в случае создания) + `if ! id lfs >/dev/null 2>&1; then sudo adduser lfs; fi` (Debian adduser использует существующую группу `lfs` как primary) + `sudo usermod -aG lfs lfs` (harmless idempotent) + `if [ -e /dev/kvm ]; then sudo usermod -aG kvm lfs; fi`; явные «НЕ добавлять в sudo/wheel/libvirt». **Fix #3 (доп. 2026-11-02):** учтено, что Debian `adduser lfs` сам создаёт одноимённую группу; `groupadd -f` сначала создаёт группу (если её нет), а `adduser` её использует. |
| D | Phase 2 completion criterion требовал «SeaBIOS **и** OVMF», но S6/S7 покрывали только BIOS; OVMF был «опционально» | UEFI/OVMF явно отложен до Phase 3 (отметка в §1 критериев, S6 шаг 8, S7 заголовок, §4 ограничения); Phase 2 = только BIOS/SeaBIOS path. |
| E | §7.2 содержал «Пароль lfs передаётся мне (или создаётся SSH-ключ)» — запрещено владельцем 2026-11-02 | Абсолютный запрет на передачу ИИ паролей/приватных ключей/токенов; для S0/S1 — только транзитивный доступ (владелец запускает команды, присылает вывод); SSH-доступ (если понадобится позже) — настраивается владельцем локально, без передачи учётных данных ИИ. |

**Не изменено:** архитектура проекта, ADR-0001..0008, ADR-0009 Decision (только wording в Context/Consequences/Verification plan), sources.lock, scripts/, Makefile, kernel-line, package-manager, update-rollback стратегия.

**Git patch:** `download/phase2-docs-audit-20261102.patch` (применяется чисто к GitHub HEAD 27ca0bd; проверено через `git apply --check` на свежем клоне).

## Component status (per §5 Project Initiation v2)

| Компонент | Статус | Evidence |
|---|---|---|
| Phase 0 design (PROJECT_VISION, ARCHITECTURE, TARGET_HARDWARE, KERNEL_POLICY) | Implemented | files exist |
| ADR-0001..0006 (базовая линия) | Accepted (sign-off Q1, 2026-10-31) | files exist (не переутверждались) |
| ADR-0007 (пакетный менеджер) | Deferred (подтверждён Q2, 2026-10-31) | file exists |
| **ADR-0008 (A/B + откат)** | **Proposed (рекреирован)** | docs/adr/0008-update-rollback-ab.md; 5 схем для сравнения, 7 gate-conditions G1–G7, failure scenarios PLANNED, 64 GB threshold не утверждён, grubenv snapshot в /var не утверждён |
| **ADR-0009 (build VM)** | **Accepted (рекреирован в этом цикле)** | docs/adr/0009-build-environment-vm.md |
| **docs/BUILD_ENV_SETUP.md** | **Implemented (рекреирован, v2)** | финальная инструкция развёртывания VM с 7 исправлениями владельца |
| **PHASE2_PLAN.md** | **Implemented (рекреирован в этом цикле)** | детальный план S0–S8 |
| Phase 1 дизайн-документы (BUILD_SYSTEM, BOOT_AND_RECOVERY, SYSTEM_SERVICES, TESTING_STRATEGY, SECURITY_MODEL, PACKAGE_FORMAT, UPDATE_ROLLBACK, RELEASE_POLICY, GPL_COMPLIANCE, docs/CODING_CONVENTIONS, docs/HARDWARE_INVENTORY) | **Implemented (рекреированы)** | все 11 документов воссозданы с учётом owner-review |
| Module stubs (bootstrap/, kernel/, system/, desktop/, hardware/, installer/, package-manager/, build-system/) | **Implemented (рекреированы)** | 8 каталогов с README |
| scripts/host-version-check.sh | Implemented | Phase 0; готов к запуску на VM |
| scripts/lib/lfs-safety.sh | Implemented | Phase 0; self-test OK (5/5) |
| scripts/adr-lint.py | Implemented | Phase 0 |
| scripts/sources-verify.py | Implemented | Phase 0 |
| scripts/bench/* | Implemented | Phase 0 |
| scripts/hardware-inventory.sh | **Implemented (рекреирован)** | read-only inventory, 12 категорий |
| scripts/disk-budget.py | **Implemented (рекреирован)** | disk budget calculations; ADR-0008 gate G6 |
| sources.lock | Planned (URLs verified; SHA256 UNVERIFIED → Phase 2 S2) | file exists |
| Build VM развёрнута | Planned | владелец выполняет docs/BUILD_ENV_SETUP.md |
| LFS сборка (S1–S8) | Planned (Phase 2, авторизован) | блокируется готовностью VM |
| Ядро (конфиги, сборка) | Planned (Phase 2 S5) | — |
| Slot manager / A/B реализация | NOT STARTED (Phase 8; ADR-0008 Proposed) | запрещено до утверждения |
| Установщик / ISO | Planned (Phase 9) | — |

## Completed

### Phase 0 (этот репозиторий, 2026-10-30)

См. предыдущие записи в IMPLEMENTATION_LOG.md.

### Этот цикл (2026-10-31, Phase 2 Build Environment)

1. Принято OWNER DECISION — Phase 2 Build Environment (вариант A: постоянная изолированная Build VM).
2. Получена целевая конфигурация VM: Debian 13, 8 vCPU, 12–16 GB RAM, 40+60 GB disks, admin+lfs, nested virt.
3. Рекреированы утраченные документы:
   - `docs/BUILD_ENV_SETUP.md` (финальная инструкция развёртывания VM).
   - `docs/adr/0009-build-environment-vm.md` (Accepted ADR).
   - `PHASE2_PLAN.md` (детальный план S0–S8).
4. Утверждённые ограничения соблюдены: вариант B (sandbox attempt) отклонён; никаких установок в текущую sandbox; git commits/push не выполнялись.

## Test evidence

- `bench/results/host-version-check-*.txt` (Phase 0 sandbox) — 3 missing LFS-tools (bison, gawk, texinfo) + 6 extra missing. Sandbox НЕ готов к S1–S8.
- `scripts/lib/lfs-safety.sh --self-test` → OK (5/5) — рекреация не требуется, файл survived.
- `python3 scripts/adr-lint.py docs/adr` → 9 ADR (после рекреации ADR-0009), 0 issues.

## Known limitations / risks

1. **Permanent Build VM не развёрнута** — владелец выполняет `docs/BUILD_ENV_SETUP.md` (≈40–70 мин). До готовности VM Phase 2 S0 (на VM) не проводится.
2. ~~**Phase 1 документы утрачены**~~ — **RESOLVED (2026-10-31):** все 11 документов + ADR-0008 рекреированы (см. PHASE1_FILES.md); восстановление прекращено.
3. ~~**ADR-0008 утрачен**~~ — **RESOLVED (2026-10-31):** рекреирован, статус Proposed (5 схем, 7 gate-conditions G1–G7, failure scenarios PLANNED, 64 GB threshold не утверждён, grubenv snapshot в /var не утверждён).
4. ~~**scripts/hardware-inventory.sh утрачен**~~ — **RESOLVED (2026-10-31):** рекреирован (read-only, 12 категорий). Сама инвентаризация целевого ноутбука по-прежнему не проведена — выполнить в Phase 4.
5. **Имя дистрибутива не выбрано** (влияет на артефакты Phase 11, не блокирует Phase 2).
6. **sources.lock sha256 — UNVERIFIED** (заполняются при первом скачивании в Phase 2 S2 на VM).

## Next action

**Phase 2 AUTHORIZED** (решение владельца 2026-10-31; docs audit 2026-11-02). Шаги:

1. **Владелец:** применить patch `download/phase2-docs-audit-20261102.patch` к локальному клону `Manivero/MO-Linux` на своей машине (`git apply --check phase2-docs-audit-20261102.patch` → если OK, `git apply phase2-docs-audit-20261102.patch`). commit/push — по решению владельца.
2. **Владелец:** развёртывание permanent Build VM по `docs/BUILD_ENV_SETUP.md` v4 §1–§2 (создание VM, Debian install). Сразу после Debian install (ДО apt-install) — snapshot `clean-base`. Затем apt install категорий A+B+C. ~40–70 мин.
3. **Владелец:** провести S0 host preflight (см. PHASE2_PLAN.md §2 S0) — `bash scripts/host-version-check.sh` + `python3 scripts/sources-verify.py sources.lock` (ПОЛНЫЙ вывод включая Summary `N OK, N FAIL, N SKIPPED`; exit code НЕ подавлять; интерпретация: exit 0 = нет FAIL среди проверенных URL — но SKIPPED может быть > 0, если URL содержит "UNVERIFIED"; в текущем sources.lock все URL реальные, ожидаемо 22 OK / 0 FAIL / 0 SKIPPED) + `lsblk` + `qemu-system-x86_64 --version` + `ping -c1 kernel.org` + `ls -la /dev/kvm 2>/dev/null`. **Snapshot `after-S0-preflight` НЕ создавать до моего явного «S0 PASS».** Передать вывод мне (транзитивно — копия вывода, БЕЗ паролей/ключей).
4. **Я (после отчёта S0):** аудит выводов; явное решение «**S0 PASS**» (можно делать snapshot `after-S0-preflight` и переходить к S1) либо «**S0 FAIL**» (с указанием, что доработать). Если «S0 PASS» — даю конкретные команды для S1 (S1.1 lsblk ID → owner approval gate → S1.2 fdisk → S1.3 mkfs+mount → S1.4 lfs user idempotent через `groupadd -f lfs` + `adduser lfs` → S1.5 lfs-safety install + final readiness gate).
5. **Владелец (после «S0 PASS»):** создать snapshot `after-S0-preflight`. Выполнить S1 шаги с моим аудитом каждого вывода. Owner approval gate перед fdisk — обязательное явное подтверждение владельца. Сделать snapshot `before-S2`.
6. **Я:** S2 (sources download) — транзитивно через владельца. После каждой стадии — checkpoint + обновление PROJECT_STATUS.md и IMPLEMENTATION_LOG.md.
7. **Я:** S3–S8 в permanent Build VM (транзитивно или, при необходимости, через SSH, настроенный владельцем локально — без передачи учётных данных ИИ).
8. **Я:** после S8 — полный REPORT.md с точными версиями, командами, результатами, журналами ошибок, тестами, ограничениями, состоянием репозитория, предложением следующего этапа (Phase 3 — modular kernel config + QEMU OVMF UEFI boot).

## Open questions для владельца

1. Применить patch `download/phase2-docs-audit-20261102.patch` к локальному репозиторию и сделать commit/push? (Patch проверен через `git apply --check` на свежем клоне GitHub main = 27ca0bd.)
2. Начать развёртывание permanent Build VM по `docs/BUILD_ENV_SETUP.md` v4 §1–§2?
3. (Опционально) Имя дистрибутива — можно отложить до Phase 11.
4. (Опционально) Доступ к целевому ноутбуку для инвентаризации — параллельно с Phase 2.
