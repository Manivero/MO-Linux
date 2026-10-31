# ADR-0009 — Build environment: isolated Linux VM

- **Status:** Accepted (owner decision 2026-10-31 — Phase 2 Build Environment: «Выбираю вариант A: постоянная изолированная Build VM»)
- **Date:** 2026-10-31 (рекреирован после recycle песочницы; оригинальная дата создания — 2026-10-31 в Phase 1)
- **Phase origin:** Phase 1
- **Decision owner:** Project owner (§8 — build environment; sign-off Phase 0 Q3/Q4)
- **Confidence:** Verified — VM specs утверждены владельцем; фактическая проверка после развёртывания VM (S0 preflight)

## Context

Sign-off Phase 0 (2026-10-31), Q3+Q4: владелец постановил, что текущая sandbox (Debian 13 trixie, 2 cores, 4 GB RAM, 9.3 GB disk) **не является** постоянной build-средой; установка пакетов на текущий хост запрещена. Владелец утвердил изолированную Linux VM как постоянное build-окружение с разделением ролей admin/lfs, rootfs на виртуальном диске/безопасном loopback, snapshots и восстановлением, без модификации физических разделов.

Phase 1 (2026-10-31) создал первоначальный ADR-0009 (Accepted) с базовой спецификацией. После recycle песочницы ADR-0009 утрачен; рекреирован в этом цикле с уточнённой конфигурацией от владельца (Phase 2 Build Environment decision, 2026-10-31).

## Options considered

| Опция | Описание | Изоляция | Snapshots | Совместимость с §3 | Стоимость |
|---|---|---|---|---|---|
| **A. Permanent isolated Linux VM** (libvirt/KVM на Linux-хосте, или VMware/VirtualBox на Windows-хосте) | полная VM с Debian 13, отдельный lfs user, виртуальные диски | ✅ высокая | ✅ native | ✅ | средняя: развёртывание 40–70 мин |
| **B. Container (Docker/Podman)** | namespace-isolated среда; Debian base image | ⚠️ разделяет ядро с хостом | ❌ только через layer commits | ❌ | низкая |
| **C. chroot на текущей sandbox** | изоляция файловой системы, но shared kernel | ❌ низкая | ❌ нет | ❌ | низкая |
| **D. Текущая sandbox как build-среда** | без изоляции, прямая сборка | ❌ нет | ❌ нет | ❌ нарушает Q3 | низкая, но запрещена владельцем |
| **E. Отдельная физическая машина** | dedicated hardware | ✅ высокая | нет native | ✅ | высокая; нецелесообразно для одного дистрибутива |

## Decision

Принять **опцию A: permanent isolated Linux VM** с параметрами, утверждёнными владельцем (Phase 2 Build Environment decision, 2026-10-31):

| Параметр | Значение |
|---|---|
| ОС VM | Debian 13 (trixie) amd64 |
| vCPU | 8 |
| RAM | 12–16 GB |
| Virtual Disk 1 | 40 GB — Debian host |
| Virtual Disk 2 | 60 GB — LFS workspace (/mnt/lfs + /mnt/test-disk) |
| Admin account | `admin` (для apt-install, libvirt/qemu setup, snapshots) |
| Build account | `lfs` — непривилегированный, **БЕЗ sudo** |
| Nested virtualization | включить, если доступна (для QEMU/KVM внутри VM) |
| Snapshots | обязательно перед S0, S1, S2 и каждым критическим этапом |

Финальная инструкция развёртывания — `docs/BUILD_ENV_SETUP.md`. Фактические ресурсы проверяются после создания VM (S0 preflight в самой VM).

## Rationale

1. **Изоляция (Q3):** VM полностью изолирует build-среду от хост-ОС; физические разделы хоста не затрагиваются; загрузчик не устанавливается на физические диски.
2. **Воспроизводимость (Phase 2 requirement):** snapshots позволяют checkpoint/restore между стадиями S0–S8; при провале — откат к предыдущему снимку.
3. **Ресурсы:** 8 vCPU + 12–16 GB RAM + 100 GB disk (40+60) достаточно для полной LFS-сборки (S3+S4: 4–8 часов; S5 kernel: 30–90 мин).
4. **Nested KVM:** позволяет QEMU внутри VM работать с аппаратным ускорением; если недоступен — TCG fallback (с явным указанием: TCG пригоден для функциональной проверки загрузки, но не для достоверных performance benchmarks; req #9).
5. **Роли (Q4):** разделение admin (apt-install, libvirt, snapshots) и lfs (компиляция без sudo) соответствует LFS-принципам безопасности.
6. **Контейнер (опция B) отклонён:** разделяет ядро с хостом; не даёт native snapshots; не подходит для тестов загрузки в QEMU с собственным ядром.
7. **Текущая sandbox (опция D) отклонена:** нарушает Q3; недостаточно ресурсов (4 GB RAM, 9.3 GB disk, 2 cores).

## Consequences

- **Positive:** полная изоляция от хоста; воспроизводимая среда; checkpoints между стадиями; nested KVM для QEMU; соответствует Q3/Q4 и Phase 2 requirements.
- **Negative:** требует ручного развёртывания владельцем (~40–70 минут); если хост — Windows с VirtualBox, nested KVM нестабилен (рекомендация: VMware Workstation Pro 17+ или Linux-хост с libvirt).
- **Risks:**
  - **R1** — nested KVM недоступен на хосте (AMD CPU + VirtualBox не поддерживают nested): QEMU работает в TCG, Phase 2 S7 будет медленнее; владелец осведомлён (req #9 — не выдавать TCG за эквивалент; TCG — только функциональная проверка загрузки, не performance benchmarks).
  - **R2** — фактические ресурсы VM отличаются от target (например, хост-машина имеет 8 cores, а VM получает 4): фиксируется в S0 preflight отчёте; если критично (например, 8 GB RAM вместо 12) — пересмотр ресурсов.
  - **R3** — VM теряется/портится: резервная копия базового состояния (snapshot «clean-base») + резервная копия Disk 2 (LFS workspace) — req #10.

## Revisit triggers

- Nested KVM стабильно недоступен на хосте → рассмотреть переход на dedicated Linux-хост для build VM.
- Disk 2 (60 GB) заполняется раньше S7 → расширить Disk 2 или добавить Disk 3.
- Время сборки S3+S4 превышает 12 часов на 8 vCPU → пересмотр ресурсов VM.
- Появится второй разработчик → второй VM или разделение пользователей внутри текущей VM.

## Verification plan

- **Verified (S0 preflight):** после развёртывания VM владелец присылает заполненный чек-лист `docs/BUILD_ENV_SETUP.md` §6.1; я повторяю `scripts/host-version-check.sh` на VM (через транзитивный доступ — владелец копирует вывод, или через SSH-доступ — рекомендуется).
- **Verified (S1):** Disk 2 размечен, /mnt/lfs смонтирован, lfs user настроен, lfs-safety.sh self-test OK.
- **Verified (build):** первый пакет LFS (Binutils pass 1) компилируется в S3 от lfs без ошибок; лог сохранён в /mnt/lfs/build-logs/.
