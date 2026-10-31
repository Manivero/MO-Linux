# BUILD_SYSTEM — спецификация сборки LFS

Статус: **Implemented** (спецификация; рекреирован 2026-10-31 после recycle песочницы).
Связанные решения: ADR-0009 (Build VM, Accepted), ADR-0006 (kernel line, Accepted), ADR-0001..0006 (базовая линия, Accepted), ADR-0007 (package manager, Deferred), ADR-0008 (A/B, Proposed — НЕ реализуется до утверждения).

## 1. Цель

Собрать воспроизводимую базовую Linux-систему LFS 13.1-systemd с собственным ядром Linux 6.18.59 LTS, готовую к загрузке в QEMU (Phase 2). Сборка выполняется в permanent Build VM (ADR-0009) пользователем `lfs` (без sudo).

## 2. Роли и изоляция

| Роль | Пользователь | sudo | Действия |
|---|---|---|---|
| Admin | `admin` | yes | apt-install, libvirt/qemu setup, snapshots VM, disk partitioning (Disk 2) |
| Builder | `lfs` | **NO** | скачивание исходников, компиляция S2–S5, тестирование S6–S8 |
| Test | `lfs` | NO | QEMU-запуски (если /dev/kvm доступен — lfs в группе kvm) |

`lfs` НЕ в libvirt-группе; использует raw QEMU через `qemu-system-x86_64`.

## 3. Источники и контрольные суммы

- `sources.lock` — манифест: linux-6.18.59.tar.xz + 13 LFS пакетов + 8 патчей.
- URL verified (HEAD-check) в Phase 0.
- SHA256 = UNVERIFIED до S2; вычисляются при первом скачивании на VM; обновляются в `sources.lock`.
- Fallback зеркало: mirrors.kernel.org/gnu/ (если ftpmirror.gnu.org недоступен).

## 4. Стадии S0–S8 (сводка)

| Стадия | Цель | Время (8 vCPU) | Статус |
|---|---|---|---|
| S0 | Build environment preflight на VM | 5 мин | Planned |
| S1 | Развёртывание VM и файловой структуры | 40–70 мин (владелец) | Planned |
| S2 | Подготовка LFS user + sources | 30 мин | Planned |
| S3 | Сборка temporary toolchain (16 пакетов) | 2–4 часа | Planned |
| S4 | Сборка базовой системы LFS (~70 пакетов) | 4–8 часов | Planned |
| S5 | Установка и конфигурация Linux Kernel 6.18.y | 30–90 мин | Planned |
| S6 | Подготовка initramfs, GRUB, test rootfs | 30–60 мин | Planned |
| S7 | Первая загрузка в QEMU | 1–10 мин | Planned |
| S8 | Проверка консоли/CPU/RAM/disk/служб | 5–15 мин | Planned |

Детали — в `PHASE2_PLAN.md`.

## 5. Структура каталогов LFS workspace

```
/mnt/lfs/                # Disk 2 (60 GB), ext4, owner lfs:lfs, монтирован по UUID
├── sources/             # 1777 sticky bit; .tar.xz исходники + патчи (~2 GB)
├── tools/               # temp toolchain (S3; ~3 GB) — удаляется после S4
├── test-disk/           # QEMU images (~5 GB)
│   ├── disk.qcow2       # тестовый виртуальный диск 5 GB (S6)
│   └── initramfs-staging/
├── build-logs/          # логи сборки каждого пакета
├── checkpoints/         # tar snapshots между стадиями (внутренний backup)
└── (S4 rootfs соберётся прямо в /mnt/lfs/{bin,etc,lib,...})
```

## 6. Воспроизводимость

- `SOURCE_DATE_EPOCH` установлен для каждого пакета (timestamp из sources.lock).
- Build flags зафиксированы (CFLAGS, CXXFLAGS, LDFLAGS — LFS-стандартные).
- Двойная сборка в S4: rebuild → diff критичных бинарников (allowed diffs: timestamps, build paths).
- `make` параллельный: `MAKEFLAGS=-j$(nproc)` (8 на VM).

## 7. Безопасность

- `scripts/lib/lfs-safety.sh` — библиотека с проверками путей (lfs_safe_path, lfs_safe_rm, lfs_die). Self-test OK (5/5).
- Все операции с путями — через библиотеку; прямой `rm -rf` запрещён.
- `$LFS` проверяется перед каждой критической операцией.
- Запрещённые пути: `/`, `/usr`, `/boot`, `/etc`, `/var`, `/home` — lfs_safe_path отклоняет.

## 8. Логи и журналирование

- Логи сборки каждого пакета → `/mnt/lfs/build-logs/<stage>/<package>.log`.
- Журналы QEMU (S7–S8) → `tests/results/phase2-qemu-boot-<ts>/`.
- Console output QEMU — serial (`-nographic -serial mon:stdio`).
- `dmesg`, `journalctl -b` — внутри QEMU-системы, сохраняются через `scp` или copy-paste в `tests/results/`.

## 9. Checkpoints (после каждой стадии)

- Snapshot VM в гипервизоре (см. `docs/BUILD_ENV_SETUP.md` §6 — 11 named snapshots).
- Дополнительно: tar-снимок `/mnt/lfs` в `/mnt/lfs/checkpoints/<stage>-<ts>.tar.gz` (внутренний backup; не заменяет VM snapshot).

## 10. Ограничения

- ❌ Не реализовывать A/B (ADR-0008 Proposed).
- ❌ Не устанавливать GRUB на физические диски.
- ❌ Не изменять физические разделы.
- ❌ Не выполнять git commits/push.
- ❌ Не устанавливать пакеты в текущую sandbox (вариант B отклонён).
- ❌ TCG-тесты не выдавать за эквивалент KVM по скорости (req #9).

## 11. Связанные документы

- `docs/BUILD_ENV_SETUP.md` — инструкция развёртывания VM.
- `docs/adr/0009-build-environment-vm.md` — ADR (Accepted).
- `PHASE2_PLAN.md` — детальный план S0–S8.
- `sources.lock` — манифест исходников.
- `scripts/lib/lfs-safety.sh` — библиотека безопасности.
- `scripts/host-version-check.sh` — S0 preflight.
