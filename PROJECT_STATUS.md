# PROJECT_STATUS

- Project: Lightweight Linux Distribution (own, source-based, x86_64)
- Current phase: **Phase 2 — AUTHORIZED, awaiting permanent Build VM** (Owner decision 2026-10-31: Option A — isolated Linux VM). **Phase 1 restoration: CLOSED (2026-10-31, финальная проверка пройдена)**
- Repository path: /home/z/my-project/download/distro
- Branch: локальный git re-init после recycle песочницы; **коммитов нет** (§10)
- Build host (текущая sandbox): Debian 13, 2 cores, 4 GB RAM, 9.3 GB disk — **НЕ является build-средой** (решение владельца Q3 + OWNER DECISION Phase 2: вариант B отклонён)
- Permanent build environment: target VM spec получен (Debian 13, 8 vCPU, 12–16 GB RAM, 40+60 GB disks, admin+lfs users, nested virt); инструкция развёртывания — `docs/BUILD_ENV_SETUP.md`; развёртывается владельцем
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

BUILD_ENV_SETUP.md v3 (2026-10-31): дополнительные решения владельца — **Nested KVM НЕ обязательна**; VMware или VirtualBox оба рекомендуются; QEMU TCG — полноценный fallback (не деградация): **пригоден для функциональной проверки загрузки, но НЕ для достоверных performance benchmarks** (TCG-тайминги искажены эмуляцией; benchmark-замеры — только KVM/реальное железо); никаких изменений Hyper-V/VBS/Memory Integrity/BCD/Defender/BIOS-настроек безопасности Windows.

BUILD_ENV_SETUP.md v2 (исправления владельца): lsblk-first disk identification (испр. #1), UUID в /etc/fstab (испр. #2), admin не в группе lfs без необходимости (испр. #3), lfs не в libvirt без обоснования (испр. #4), не требовать отключения Hyper-V/VBS (испр. #5), разделение build/test tools (испр. #6), TCG как first-class fallback (испр. #7).

Сохранены Phase 0 документы и скрипты (README, PROJECT_VISION, ARCHITECTURE, TARGET_HARDWARE, KERNEL_POLICY, sources.lock, Makefile, ADR-0001..0007, scripts/adr-lint.py, host-version-check.sh, sources-verify.py, scripts/bench/*, scripts/lib/lfs-safety.sh, .github/workflows, .gitignore).

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

**Phase 2 AUTHORIZED** (решение владельца 2026-10-31). Шаги:

1. **Владелец:** развёртывание permanent Build VM по `docs/BUILD_ENV_SETUP.md` (≈40–70 мин).
2. **Владелец:** после развёртывания VM — заполнить и прислать чек-лист `docs/BUILD_ENV_SETUP.md` §6.1 + вывод `bash scripts/host-version-check.sh` на VM (как admin, в sandbox-репозитории проекта).
3. **Я (после получения отчёта):** S0 preflight на VM (через транзитивный доступ: владелец копирует выводы команд, или через SSH-доступ). Если VM готова — snapshot «after-S0-preflight», продолжение S1.
4. **Я:** S1–S8 в permanent Build VM. После каждой стадии — checkpoint + обновление PROJECT_STATUS.md и IMPLEMENTATION_LOG.md. (Рекреация Phase 1 документов уже завершена — CLOSED.)
5. **Я:** после S8 — полный REPORT.md с точными версиями, командами, результатами, журналами ошибок, тестами, ограничениями, состоянием репозитория, предложением следующего этапа.

## Open questions для владельца

1. Готов ли отчёт о развёртывании VM по `docs/BUILD_ENV_SETUP.md` §6.1?
2. Какой способ доступа к VM: SSH-доступ (рекомендуется) или транзитивный (владелец копирует выводы команд)?
3. (Опционально) Имя дистрибутива — можно отложить до Phase 11.
4. (Опционально) Доступ к целевому ноутбуку для инвентаризации — параллельно с Phase 2.
