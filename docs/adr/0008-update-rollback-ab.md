# ADR-0008 — Схема обновлений и отката (рекреация после recycle)

- **Status:** Proposed (рекреирован 2026-10-31 после recycle песочницы; статус соответствует решениям владельца из Phase 1 + owner-review 2026-10-31). Реализация любой схемы **запрещена** до отдельного утверждения.
- **Date:** 2026-10-31 (Phase 1 создание; рекреация 2026-10-31)
- **Phase origin:** Phase 1
- **Decision owner:** Project owner (§8 — схема обновлений входит в список решений владельца)
- **Confidence:** Hypothesis — качественные выводы о GRUB env block основаны на GNU GRUB Manual 2.14 §15.2; числовые оценки подтверждаются измерениями Phase 5/8.

## Context

Sign-off Phase 0 (2026-10-31), Q1: владельцем утверждена базовая линия (ext4, systemd, GRUB, …), но A/B-архитектура обновлений НЕ утверждена. Phase 1 исследовала 6 осей владельца: A/B root filesystem; Rollback strategy; Atomic updates; Disk space overhead; Совместимость со старыми HDD/SSD; Recovery после прерванных обновлений.

Phase 1 technical review (2026-10-31): ADR-0008 расширен с §4.7–§4.11 (GRUB env block ограничения; boot entry switch ≠ atomic update; shared /boot layout; disk budget 64 GB threshold; failure testing FT-1…FT-6).

Owner review (2026-10-31, вместе с Phase 2 authorization): ADR-0008 остаётся **Proposed**; A/B-ext4 **не утверждена** как окончательная архитектура. 5 схем остаются для сравнения. 7 gate-conditions (G1–G7) для будущего утверждения. Порог 64 GB **не утверждён**. Failure scenarios — PLANNED, не VERIFIED. Восстановимость grubenv через snapshot в /var **не утверждена**.

Приоритет §2 #1 — «надёжность и безопасность обновлений (система не должна "кирпичиться")» — главный критерий.

## Options considered (5 схем для сравнения)

| Опция | Откат | Атомарность | Зависимости | Стоимость | Зрелость |
|---|---|---|---|---|---|
| **A. A/B partitions** (два root ext4, общий /boot) | перезагрузка в предыдущий слот | пишем только в неактивный слот | GRUB + grubenv | низкая | высокая (аналог Android A/B) |
| **B. Btrfs snapshots** | откат snapshot в initramfs | snapshot мгновенный, откат через fs-tools | Btrfs в ядре и initramfs | средняя; противоречит ADR-0005 | средняя на старом железе |
| **C. Single-root + recovery** (read-only base image + восстановление) | загрузка в recovery + dd образа | атомарная запись образа | recovery-раздел 2–4 ГБ | низкая–средняя | средняя (Raspberry Pi OS) |
| **D. OSTree-based deployments** (как Fedora Silverblue) | атомарный переключатель deployments | высокая; проверена индустрией | libostree | высокая; ломает FHS-флоу LFS | высокая |
| **E. Image-based system** (squashfs root + overlay) | восстановление из образа | atomic image swap | squashfs + overlayfs в initramfs | средняя; ограничивает /etc | высокая (OpenWrt, Endless) |

**Ни одна из этих схем не реализуется** до отдельного утверждения владельцем.

## Analysis (по 6 осям владельца из Phase 1)

### Ось 1. A/B root filesystem
Два root-раздела ext4 + общий /boot + swap + общий /home. Обновление ставится в неактивный слот через `pkg --root` (ADR-0007 требование №10). Сильные стороны: откат не зависит от ФС, логика в userspace + GRUB. Слабые: две копии /etc — локальные правки не переносятся автоматически (политика drop-in override-файлов).

### Ось 2. Rollback strategy
| Аспект | A/B | Btrfs | Single-root+recovery | OSTree |
|---|---|---|---|---|
| Точка отката | предыдущий слот | snapshot | предыдущий образ | предыдущий deployment |
| Время отката | 1 перезагрузка | перезагрузка + rollback | reboot + dd (~5–15 мин на HDD) | 1 перезагрузка |
| Глубина отката | 1 шаг | N snapshots | N=1–2 образов | N deployments |

### Ось 3. Atomic updates
State machine: `IDLE → FETCHING → VERIFIED → STAGING → PREPARED → REBOOT_PENDING → BOOTING_NEW → COMMITTED | FAILED`. Коммит — единственная атомарная операция (запись grubenv 1024 байта через `grub-editenv`). До коммита — пишем в неактивный слот; после — health-check решает.

### Ось 4. Disk space overhead
Размер слота (оценка): 12 ГБ (рекомендация) / 8 ГБ (минимум). Накладные расходы A/B: +12 ГБ (~7.5% диска 160 ГБ). Подробный пересчёт с реальными размерами — gate G6 (после Phase 2 измерения фактического rootfs).

### Ось 5. Совместимость со старыми HDD/SSD
ext4 + GRUB + grubenv: ничего нового с 2012 года; работает на SATA HDD 5400 rpm, SATA SSD, NVMe. Btrfs: документированные проблемы на SMR-дисках (многие внешние/бюджетные HDD 2015+). Обновление в неактивный слот = последовательная запись, не влияет на отзывчивость активной системы.

### Ось 6. Recovery после прерванных обновлений
| Сценарий | Восстановление |
|---|---|
| Обрыв при скачивании | staging-каталог очищается, повтор |
| Обрыв при записи в неактивный слот | health-check провалится → fallback на активный |
| Обрыв при обновлении grub.cfg | grub.cfg пишется через tmp+rename — атомарно |
| Питание снято при загрузке нового слота | после N неудач — автовозврат к старому |
| Health-check завис/провален | дефолт остаётся старым слотом |
| Оба слота повреждены | recovery через live ISO (Phase 9) |

## Owner review 2026-10-31 — future approval gates

Решение владельца: ADR-0008 остаётся Proposed; A/B-ext4 **не утверждена** как окончательная архитектура. 5 схем (A/B partitions ext4; Single-root + recovery; OSTree; Image-based; Btrfs snapshots) остаются для сравнения. **Ни одна схема не реализуется** до отдельного утверждения.

Семь gate-conditions к будущему утверждению любой схемы:

| # | Требование | Что должно быть сделано | Когда |
|---|---|---|---|
| **G1** | Подтверждение поддержки конкретных ФС GRUB 2.14 и разделение /boot и ESP | Эмпирическая проверка на собранной в Phase 2 GRUB 2.14: какие ФС поддерживают save_env (ext4, XFS, Btrfs reserved-area); ESP (FAT32) — read-only для GRUB; /boot и ESP на разных разделах. Тесты в QEMU (Phase 8). | Phase 8 |
| **G2** | Поведение grubenv при прерывании записи и невозможности чтения | Эмпирические тесты: (a) kill grub-editenv во время write; (b) truncate grubenv до 0/512/2048 байт; (c) read-only mount; (d) повреждённые комментарии. Ожидаемое: GRUB игнорирует и грузит дефолт — подтвердить или опровергнуть. | Phase 8 |
| **G3** | Необходимость boot attempt counter при наличии next_entry | Анализ: достаточно ли next_entry (one-shot semantics GRUB) или нужен дополнительный boot_attempts в /boot/slotmgr/attempts. Эмпирически проверить поведение grub-reboot при kernel panic. | Phase 8 |
| **G4** | Гарантия сохранения последнего рабочего default entry | Доказать, что ни один шаг транзакции не может потерять `default=<рабочий слот>`: (a) default пишется только grub-set-default после health-check PASS; (b) до этого default нетронут; (c) при FT-5e (grubenv corrupted) GRUB fallback'ит к первой menuentry — убедиться, что это slot A. | Phase 8 |
| **G5** | Безопасность общей /var и миграций пользовательских данных | Анализ: общий /home, но /var в каждом слоте. Что с /var/lib/... (БД пакетов, NetworkManager, systemd, journal)? Варианты: (a) общий /var (отдельный раздел); (b) /var/lib в каждом слоте с миграцией; (c) смешанный (/var/log общий, /var/lib в каждом). Исследовать и предложить. | Phase 1 rev / Phase 8 |
| **G6** | Пересчёт disk budget с указанием GB/GiB, EFI, swap, резерва, реального rootfs | После Phase 2 — измерить реальный размер rootfs. Пересчитать budget с: (a) GB vs GiB — указать явно; (b) ESP 512 MiB; (c) swap = RAM для hibernate; (d) 10–15% свободный резерв; (e) измеренный root size + headroom. Обновить scripts/disk-budget.py. | Phase 2/5 |
| **G7** | Проверка возможности отката после обновления ядра, initramfs, glibc | Эмпирически: (a) обновить только ядро в slot B → загрузиться → откат; (b) обновить initramfs → загрузиться → откат; (c) обновить glibc → загрузиться → откат. Убедиться, что slot A остаётся незатронутым. | Phase 8 |

### Дополнительные условия владельца (не gate, но ограничения)

1. **Восстановимость grubenv через snapshot в /var НЕ утверждена** как автоматическая. Snapshot в /var/lib/slotmgr/grubenv.snapshot недоступен, если система не загрузилась (var на root разделе, который не смонтирован). Альтернативы для исследования: snapshot на отдельном /boot (доступен в initramfs); ручное восстановление через live ISO. Решение — после Phase 8.

2. **Все failure scenarios — PLANNED, не VERIFIED.** Описанное «ожидаемое поведение» — проектная гипотеза, основанная на документации GRUB и баг-трекерах, не на измерениях. Фактическая проверка — в QEMU на этапе Phase 8, при наличии собранной в Phase 2 системы. До тех пор «Ожидаемое поведение» = «проектируемое поведение, требующее эмпирической проверки».

3. **Порог 64 GB не утверждён.** Не вводить обязательное правило automatic rollback removal below 64 GB. В дальнейшем использовать реальные показатели размера установленной системы (после Phase 2) и свободного пространства. Таблицы disk budget — оценки, не критерии применимости.

## Decision (предложение — не окончательное)

**Рекомендуется опция A: A/B partitions на ext4** с параметрами:
- общий /boot (ext4, 1 ГБ) с ядрами обоих слотов (имена с суффиксом слота и timestamp), grubenv, grub.cfg.prev, grub.cfg.recovery;
- GRUB: `GRUB_DEFAULT=saved`, переключение через `grub-reboot` (разовая) и `grub-set-default` (фиксация после health check);
- userspace health-check (systemd oneshot после default target);
- двухслойный boot attempt counter (grub-reboot one-shot + boot_attempts в /boot/slotmgr/attempts, инкрементируется в initramfs);
- пакетный менеджер с обязательным `--root` (ADR-0007 требование №10);
- snapshot grubenv для восстановления после FT-5e — **МЕСТО ХРАНЕНИЯ НЕ УТВЕРЖДЕНО** (snapshot в /var недоступен, если система не загрузилась); alternatives: /boot (доступен в initramfs) или ручное восстановление через live ISO.

**Реализация до утверждения этого ADR запрещена.** Утверждение требуется до Phase 9 (установщик); рекомендуется до Phase 2, чтобы разметка build-окружения учитывала layout. **Не считается окончательно утверждённой** — ожидает решения владельца.

## Rationale

1. §2 #1 (не кирпичится): A/B — единственная схема, где отказоустойчивость не зависит от ФС/LVM-инструментов в момент сбоя; откат — одна перезагрузка.
2. ADR-0005 уже выбрал ext4; A/B не требует пересмотра; Btrfs требует.
3. Накладные расходы диска (~12 ГБ) приемлемы для целевого класса машин (160 ГБ+); для дисков 32–64 ГБ — single-root + recovery (опция C) как fallback.
4. Стоимость сопровождения минимальна: GRUB, grub-editenv, systemd-служба — всё в базовой системе.
5. OSTree отвергнут по стоимости и чужой сложности; Btrfs — по надёжности на старом железе.
6. Single-root + recovery — жизнеспособная альтернатива для малых дисков; сохранена как опция fallback.
7. Ограничения GRUB env block (см. ниже) — известные проектные ограничения; A/B-слоты на plain partitions (без LVM/RAID), grubenv на ext4 /boot.
8. «Boot entry switch ≠ atomic update» (см. ниже): атомарность = «отсутствие смешанных состояний», не «одна неделимая ACID-транзакция».

## GRUB environment block — ограничения (краткое резюме)

Источник: GNU GRUB Manual 2.14 §15.2 «The GRUB environment block».

> «For safety reasons, this storage is only available when installed on a **plain disk (no LVM or RAID)**, using a **non-checksumming filesystem (no ZFS)**, and using **BIOS or EFI functions (no ATA, USB or IEEE1275)**.»

| Ограничение | Влияние | Митигация |
|---|---|---|
| Не работает на LVM/RAID | Запрещает root-on-LVM и mdraid-root с A/B | A/B-слоты на обычных разделах ext4 |
| Не работает на USB-boot | Live USB без отката | Degraded-режим для live USB |
| 1024 байта max | Не подходит для истории | Только current state; история в /var/lib/slotmgr/state |
| Write может частично провалиться при crash | grubenv может стать неконсистентным | GRUB fallback к дефолтам; snapshot — **НЕ УТВЕРЖДЁН** |
| Нет нативного boot attempt counter | Зацикливание на плохом слоте | Двухслойный: grub-reboot one-shot + boot_attempts в /boot |
| save_env может молча пропустить write | Обновление «потерялось» | slotmgr-healthcheck проверяет grubenv после editenv |

## Boot entry switch ≠ atomic update

Уровни атомарности:
- **L1. boot entry switch** (запись grubenv 1024 байта) — atomic с точки зрения GRUB; не гарантирует, что slot B полностью установлен и валиден.
- **L2. slot-коммит** (запись в grubenv + гарантия, что slot B VERIFIED и STAGED) — state-machine доходит до REBOOT_PENDING только после проверки.
- **L3. запись пакетов в slot B** (через pkg --root) — внутри пакета atomic (tmp+rename), но группа пакетов — не atomic целиком.
- **L4. health-check** — факт «система здорова» определяется одним systemctl is-system-running + чек-списком; не все скрытые дефекты обнаруживаются.

**«Атомарность» = «отсутствие смешанных состояний» (либо старая, либо новая версия целиком), а не «одна неделимая ACID-транзакция».**

## Failure scenarios (PLANNED, не VERIFIED)

> **Status (решение владельца 2026-10-31):** все сценарии FT-1…FT-6 — **PLANNED**. Описанное «ожидаемое поведение» — проектная гипотеза. Фактическая проверка — в QEMU на этапе Phase 8.

| # | Сценарий | Ожидаемое поведение (PLANNED) | Восстановление |
|---|---|---|---|
| FT-1 | Питание снято при загрузке slot B | после max_attempts — fallback на slot A | auto (если митигация работает) или manual через GRUB-меню |
| FT-2 | Питание снято во время staging | slot A жив, slot B partial, dirty | auto (rootA жив, повтор обновления) |
| FT-3 | Повреждение rootB до commit | STAGING_ABORTED, slot A жив | auto (slotmgr PREPARED-validation FAIL → abort) |
| FT-4 | Kernel panic в slot B | после max_attempts — fallback на slot A | auto или manual через GRUB-меню |
| FT-5a/b/c | Повреждение MBR/ESP/core | не загружается | live ISO (Phase 9): grub-install |
| FT-5d | Повреждение grub.cfg | загрузка через grub.cfg.prev | live ISO или manual restore |
| FT-5e | Повреждение grubenv | GRUB игнорирует, грузит slot A | auto-restore **НЕ УТВЕРЖДЁН**; alternatives исследуются |
| FT-5f | Повреждение vmlinuz-* | загрузка в другой слот или live ISO | medium manual |
| FT-6 | Health-check FAIL в slot B | reboot → slot A; FAILED в журнале | auto |

## Consequences

- **Positive:** обновления, не способные убить работающую систему; откат за одну перезагрузку; recovery-ядро всегда доступно.
- **Negative:** +12 ГБ диска (для опции A); две копии /etc; обновления требуют перезагрузки; ограничение «no LVM, no mdraid root» для первого релиза; live USB-режим без отката.
- **Risks:**
  - R1 — расхождение конфигурации между слотами; митигировано переносом /etc-override'ов.
  - R2 — health-check false-negative; параметры настраиваются в Phase 8.
  - R3 — grubenv corruption (FT-5e); митигация snapshot — **НЕ УТВЕРЖДЕНА**; alternatives в Phase 8.
  - R4 — boot attempt counter race condition (если initramfs-B не может написать в /boot); fallback к grub-reboot one-shot semantics.
  - R5 — disk overhead на 32 ГБ дисках; degraded-режим (один слот, документировано). **Порог 64 GB не утверждён** — использовать реальные измерения (gate G6).
  - R6 — disk wear на SSD/NVMe из-за двойной записи; обновления нечасты; для HDD — неактуально.

## Revisit triggers

- Phase 5/8: измерения покажут, что 12 ГБ слот избыточен/недостаточен → пересмотр размера.
- Появится требование глубины отката >1 шага → рассмотреть Btrfs только на Standard/Extended.
- Деградация записи на HDD 5400 rpm → рассмотреть дельта-обновления.
- Появится требование LVM-root или mdraid-root → рассмотреть опцию C (single-root + recovery) или Android BCB (требует U-Boot).
- Появится требование live USB с поддержкой отката → рассмотреть опцию E (image-based).
- Phase 8 failure-testing выявит категорию сценариев, не покрываемых митигациями (FT-1..FT-6) → пересмотр механизма отката.

## Verification plan

- **Verified (build):** скрипт создания A/B layout на loop-файле проходит; grubenv пишется/читается. Snapshot-mechanism — **место хранения не утверждено**; после решения владельца — тест (Phase 8).
- **Verified (QEMU):** Phase 8 — обновление slot B → reboot → health check OK → commit; health-check FAIL → fallback на slot A; kernel panic → после max_attempts fallback; повреждение grubenv → GRUB fallback (FT-5e); повреждение grub.cfg → загрузка через grub.cfg.prev (FT-5d).
- **Verified (hardware):** 30 циклов «обновление-откат» на Legacy-ноутбуке (Intel Core i5-3320M) без ручного вмешательства; плюс FT-1, FT-2, FT-6 — по 5 циклов каждый (Phase 8).
- **Phase 9 (live ISO):** процедуру восстановления FT-5a/b/c/f протестировать вручную через live ISO на тестовом железе.

## References

1. GNU GRUB Manual 2.14, §15.2 «The GRUB environment block» — https://www.gnu.org/software/grub/manual/grub/grub.html
2. Android Open Source Project, «A/B (seamless) system updates» — https://source.android.com/docs/core/ota/ab
3. U-Boot Documentation, «Android A/B updates» — https://docs.u-boot.org/en/v2023.04/android/ab.html
4. Fedora Silverblue documentation — https://fedoramagazine.org/pieces-of-fedora-silverblue/
5. OSInside/kiwi Issue #2986 (2026-04-21) — grubenv corruption on Btrfs.
6. Fedora Discussion (2024-06-12) — «grub error loadenv sparse files not allowed».
7. Ubuntu bug #788298 (2011-05-25) — LVM/mdraid write limitation.
8. Внутренние документы: ADR-0003 (GRUB), ADR-0005 (ext4), ADR-0007 (package manager — --root requirement).
