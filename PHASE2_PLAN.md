# PHASE2_PLAN — Build of a reproducible base Linux system

Статус: **Implemented** (спецификация плана; рекреирован после recycle песочницы). S0 preflight ждёт развёртывания permanent Build VM.

Авторизация Phase 2 (решение владельца 2026-10-31): «Итогом должна стать реально загружаемая базовая Linux-система с собственным собранным ядром из выбранной LTS-ветки; корректным initramfs; root filesystem; рабочей консолью; базовыми системными утилитами; журналированием загрузки; возможностью диагностики ошибок. Phase 2 считается завершённой не после создания файлов, а после успешной сборки и демонстрации фактической загрузки ОС в QEMU.»

Build VM выбрана как среда выполнения (OWNER DECISION — Phase 2 Build Environment, 2026-10-31: вариант A). Развёртывание VM — по `docs/BUILD_ENV_SETUP.md`.

## 1. Цели и критерии завершения Phase 2

| Критерий | Где проверяется | Статус готовности |
|---|---|---|
| Воспроизводимая сборка (двойной прогон даёт идентичные бинарники в рамках allowed reproductions) | S4 | Planned → Verified Build |
| Собственное ядро Linux 6.18.59 LTS собирается из исходников | S5 | Planned → Verified Build |
| Initramfs корректно генерируется (монтирует root, имеет нужные модули) | S6 | Planned → Verified Build |
| Root filesystem содержит LFS 13.1-systemd базовую систему | S4 | Planned → Verified Build |
| Загрузчик GRUB 2.14 устанавливается на виртуальный диск (НЕ на физический) | S6 | Planned → Verified Build |
| QEMU успешно грузит систему (SeaBIOS и OVMF) до login prompt | S7 | Planned → Verified QEMU |
| Консоль работает: login, базовые команды (ls, cat, dmesg, journalctl) | S8 | Planned → Verified QEMU |
| Журналирование загрузки работает (`journalctl -b`) | S8 | Planned → Verified QEMU |
| Системные утилиты доступны: coreutils, util-linux, procps, iproute2 | S8 | Planned → Verified QEMU |
| CPU/RAM/disk детектируются корректно (/proc/cpuinfo, free, df) | S8 | Planned → Verified QEMU |
| systemd достигает default target (multi-user.target для base) | S8 | Planned → Verified QEMU |
| Все версии исходников и SHA256 проверены | S2 | Planned → Verified |
| Все этапы сборки воспроизводимы (snapshot + rebuild) | S4 | Planned → Verified Build |

**Phase 2 НЕ завершена, пока S7 (QEMU boot to login) не пройдена.** Это явное условие владельца.

Статусы по §5 Project Initiation v2:
- **Planned** — описано в плане, не начато.
- **Implemented** — код/конфиг существует, не проверено.
- **Verified (build)** — собирается воспроизводимо.
- **Verified (QEMU)** — загружается в QEMU и проходит тесты.
- **Verified (hardware)** — проверено на реальном железе (НЕ для Phase 2; QEMU ≠ hardware, явное указание владельца).

## 2. Стадии S0–S8

### S0 — Build environment preflight (на permanent Build VM)

**Цель:** убедиться, что permanent Build VM соответствует требованиям LFS 13.1-systemd + проектным требованиям (QEMU, диск, RAM, nested KVM).

**Чек-лист:**
1. Версия ядра VM ≥ 5.10 (требование LFS 13.1).
2. Bash ≥ 3.2, binutils ≥ 2.13.1, gcc ≥ 5.4, … — 20 LFS-required tools (через `scripts/host-version-check.sh`).
3. Дополнительные: qemu-system-x86_64 (критично для S7), shellcheck, libelf-dev, libssl-dev.
4. Дисковое пространство: ≥ 15 GB free на Disk 2 (/mnt/lfs) для полной LFS-сборки.
5. RAM: ≥ 4 GB free (с учётом VM allocation; 12–16 GB выделено).
6. /dev/kvm существует (nested virt); если нет — TCG с явным указанием медленности (req #9).
7. Сетевой доступ к kernel.org, ftp.lfs-matrix.net, mirrors.kernel.org.
8. lfs-safety.sh self-test OK.
9. sources.lock: URL проверены; SHA256 = UNVERIFIED до S2.
10. Snapshot «after-S0-preflight» сделан (если preflight OK).

**Результат S0:** отчёт `bench/results/host-version-check-<ts>.txt` (на VM) + запись в `IMPLEMENTATION_LOG.md` + решение «VM готова к S1 / нужно доработать».

### S1 — Развёртывание VM и безопасной файловой структуры

Выполняется частично владельцем (создание VM, установка Debian, apt-install, создание lfs user — см. `docs/BUILD_ENV_SETUP.md` §2–§5), частично мной (lfs-safety.sh setup, disk structure validation, snapshot naming).

**Контрольные точки S1:**
- VM создана (гипервизор, vCPU=8, RAM=12–16 GB).
- Debian 13 установлен; apt full-upgrade выполнен.
- 28 пакетов установлены (см. `docs/BUILD_ENV_SETUP.md` §2.3).
- Пользователь `lfs` создан, без sudo, в группах `lfs` и `kvm` (если /dev/kvm).
- /mnt/lfs смонтирован (Disk 2, ext4, owner lfs:lfs, /mnt/lfs/sources 1777).
- /mnt/lfs/{sources,tools,test-disk,build-logs,checkpoints} созданы.
- lfs-safety.sh установлен и self-test OK (5/5).
- Snapshot «before-S1» сделан.

**Результат S1:** заполненный чек-лист `docs/BUILD_ENV_SETUP.md` §6.1 (от владельца); snapshot VM; запись в `IMPLEMENTATION_LOG.md`.

### S2 — Подготовка LFS user и sources

**Цель:** окружение пользователя `lfs`, переменные окружения, скачивание всех исходников, верификация SHA256.

**Шаги:**
1. `~lfs/.bash_profile` и `~lfs/.bashrc` настроены (см. `docs/BUILD_ENV_SETUP.md` §4).
2. Переменные `LFS=/mnt/lfs`, `LFS_TGT=x86_64-lfs-linux-gnu`, `LC_ALL=POSIX`, `PATH=...` установлены и проверены.
3. Все исходники скачаны в `/mnt/lfs/sources/` (~2 GB): linux-6.18.59.tar.xz + 13 LFS пакетов + 8 патчей.
4. `sources.lock` обновлён: реальный SHA256 каждого архива после скачивания.
5. Контрольная сумма всего манифеста вычислена и записана.
6. Snapshot «before-S2» сделан.

**Результат S2:** `sources.lock` с реальными SHA256, `/mnt/lfs/sources/` полностью укомплектован, пользователь `lfs` готов к компиляции. Статус Verified (sources).

### S3 — Сборка temporary toolchain

**Цель:** компиляция временного кросс-тулчейна и temp-tools (~16 пакетов).

Пакеты: Binutils pass 1, GCC pass 1, glibc, libstdc++, m4, ncurses, bash, coreutils, diffutils, file, findutils, gawk, gettext, grep, gzip, make, patch, sed, tar, xz, binutils pass 2, gcc pass 2.

**Контрольные точки:**
- `$LFS_TGT-gcc --version` работает.
- `$LFS_TGT-ldd --version` показывает glibc.
- Chroot-ready: `$LFS_TGT-gcc` компилирует hello.c в статический бинарник.
- Логи сборки сохранены в `/mnt/lfs/build-logs/S3/`.
- Snapshot «before-S4» сделан.

**Время оценки:** 2–4 часа на 8 cores (vs 4–8 часов на 2 cores sandbox).

**Результат S3:** `/mnt/lfs/tools/bin/` содержит полный кросс-тулчейн. Статус Verified Build.

### S4 — Сборка базовой системы LFS

**Цель:** финальная корневая ФС LFS 13.1-systemd: ~70 пакетов.

Категории: базовые утилиты, системные библиотеки (glibc 2.44, zlib, xz, bzip2), компиляторы (gcc 16.2.0, binutils 2.47, make, m4, perl 5.40), системное окружение (systemd 261.2, dbus, util-linux, procps), сеть (iproute2, iputils), boot infra (GRUB 2.14).

**Контрольные точки:**
- Chroot в `/mnt/lfs` работает.
- glibc final pass: `ldd --version` → 2.44.
- systemd final pass: `systemctl --version` → 261.2.
- /etc/passwd, /etc/group, /etc/fstab, /etc/hostname созданы.
- /dev, /proc, /sys, /run mount points готовы.
- **Воспроизводимость:** rebuild всех пакетов → diff 0 различий в критичных бинарниках (или documented допустимые различия: timestamps, build paths).
- `du -sh /mnt/lfs` записан (фактический размер rootfs — для ADR-0008 G6).
- Snapshot «before-S5» сделан.

**Время оценки:** 4–8 часов на 8 cores.

**Результат S4:** `/mnt/lfs/` — полная корневая ФС LFS 13.1-systemd. Статус Verified Build.

### S5 — Установка и конфигурация Linux Kernel 6.18.y

**Цель:** собрать ядро Linux 6.18.59 LTS.

**Шаги:**
1. Скачать `linux-6.18.59.tar.xz`, проверить SHA256.
2. Распаковать в `/mnt/lfs/sources/linux-6.18.59/`.
3. Применить проектные патчи (если есть; ADR-0006 minimal patch policy).
4. Конфигурация: `make defconfig` (x86_64 generic) + ручная правка:
   - CONFIG_64BIT=y, CONFIG_X86_64=y
   - CONFIG_EXT4_FS=y (built-in)
   - CONFIG_VIRTIO_BLK=y, CONFIG_VIRTIO_PCI=y, CONFIG_VIRTIO_NET=y
   - CONFIG_SERIAL_8250=y, CONFIG_SERIAL_8250_CONSOLE=y
   - CONFIG_TTY=y, CONFIG_VT=y, CONFIG_VT_CONSOLE=y, CONFIG_FRAMEBUFFER_CONSOLE=y
   - CONFIG_PROC_FS=y, CONFIG_SYSFS=y, CONFIG_TMPFS=y, CONFIG_DEVTMPFS=y, CONFIG_DEVTMPFS_MOUNT=y
   - CONFIG_BINFMT_ELF=y, CONFIG_BINFMT_SCRIPT=y
   - CONFIG_UNIX=y, CONFIG_INET=y
   - CONFIG_CGROUPS=y, CONFIG_INOTIFY_USER=y, CONFIG_SIGNALFD=y, CONFIG_TIMERFD=y, CONFIG_EPOLL=y, CONFIG_FHANDLE=y
5. `make -j8 bzImage` — компиляция ядра (15–30 мин на 8 cores).
6. `make -j8 modules` (если модульная конфигурация).
7. `make modules_install INSTALL_MOD_PATH=/mnt/lfs`.
8. `cp arch/x86/boot/bzImage /mnt/lfs/boot/vmlinuz-6.18.59-lts`.
9. `cp System.map /mnt/lfs/boot/System.map-6.18.59-lts`.
10. `cp .config /mnt/lfs/boot/config-6.18.59-lts`.
11. Воспроизводимость: rebuild → идентичный vmlinuz.
12. Snapshot «before-S6» сделан.

**Результат S5:** ядро 6.18.59 LTS собрано и установлено в `/mnt/lfs/boot/`. Статус Verified Build.

### S6 — Подготовка initramfs, GRUB и тестового root filesystem

**Цель:** создать загрузочную связку для QEMU.

**Шаги:**
1. `qemu-img create -f qcow2 /mnt/lfs/test-disk/disk.qcow2 5G`.
2. Подключить через `qemu-nbd`: `sudo qemu-nbd --connect=/dev/nbd0 /mnt/lfs/test-disk/disk.qcow2`.
3. Разметить: один primary partition `/dev/nbd0p1` (ext4, root) — **БЕЗ A/B** (Phase 2; ADR-0008 Proposed).
4. `mkfs.ext4 /dev/nbd0p1`.
5. Смонтировать: `mount /dev/nbd0p1 /mnt/test-disk/root`.
6. Скопировать rootfs: `cp -a /mnt/lfs/* /mnt/test-disk/root/`.
7. Создать `/etc/fstab` в rootfs.
8. Установить GRUB 2.14:
   - BIOS: `grub-install --target=i386-pc --boot-directory=/mnt/test-disk/root/boot /dev/nbd0`.
   - UEFI (опционально): отдельная процедура с OVMF.
9. `grub-mkconfig -o /mnt/test-disk/root/boot/grub/grub.cfg`.
10. Создать минимальный initramfs (busybox + modules для ext4 и virtio + /init).
11. `umount`, `qemu-nbd --disconnect /dev/nbd0`.
12. Snapshot «before-S7» сделан.

**Результат S6:** `/mnt/lfs/test-disk/disk.qcow2` — загрузочный виртуальный диск. Статус Verified Build.

### S7 — Первая загрузка в QEMU

**Цель:** успешно загрузить собранную систему в QEMU и достичь login prompt.

**Команды:**
```bash
# BIOS boot (с KVM, если доступен)
qemu-system-x86_64 \
  -enable-kvm -m 1024 -smp 1 \
  -drive file=/mnt/lfs/test-disk/disk.qcow2,format=qcow2,if=virtio \
  -netdev user,id=net0 -device virtio-net,netdev=net0 \
  -nographic -serial mon:stdio \
  -append "console=ttyS0 root=/dev/vda1 rw"

# Без KVM (TCG)
qemu-system-x86_64 \
  -m 1024 -smp 1 \
  -drive file=/mnt/lfs/test-disk/disk.qcow2,format=qcow2,if=virtio \
  -netdev user,id=net0 -device virtio-net,netdev=net0 \
  -nographic -serial mon:stdio \
  -append "console=ttyS0 root=/dev/vda1 rw"
```

**Контрольные точки:**
- GRUB выводит меню.
- Ядро грузится.
- dmesg показывает корректное определение CPU, RAM, virtio.
- initramfs монтирует root.
- systemd запускается (PID 1).
- `multi-user.target` достигается.
- Login prompt появляется.
- Вход как root (без пароля или с простым паролем для Phase 2).

**Время:** 1–10 минут boot time (измеряется и записывается).

**Результат S7:** QEMU boot to login — Verified QEMU. Журналы сохранены в `tests/results/phase2-qemu-boot-<ts>/`. Snapshot «after-S7-success» сделан.

### S8 — Проверка консоли, памяти, CPU, диска и системных служб

**Тесты (10 пунктов):**
1. Консоль: `ls`, `cat /etc/os-release`, `dmesg | tail`.
2. CPU: `cat /proc/cpuinfo`, `nproc`, `lscpu`.
3. RAM: `free -h`, `cat /proc/meminfo`.
4. Disk: `df -h`, `lsblk`, `mount | grep vda`.
5. Сеть: `ip a`, `systemctl status systemd-networkd` (если есть).
6. systemd: `systemctl is-system-running` → `running` или `degraded`.
7. Журналирование: `journalctl -b --no-pager | head -50`.
8. Diag: `systemctl --failed` → пусто.
9. Базовые утилиты: `bash --version`, `coreutils --version`, `systemctl --version`.
10. Завершение: `systemctl poweroff` — корректное завершение.

**Результат S8:** Все 10 тестов пройдены. Статус Verified QEMU. Журналы сохранены в `tests/results/phase2-qemu-verification-<ts>/`. Snapshot «after-S8-success» сделан.

## 3. Контрольные точки (checkpoints)

После каждой стадии S1–S8:
- Обновить `PROJECT_STATUS.md` (статус стадии → Verified Build / Verified QEMU).
- Добавить запись в `IMPLEMENTATION_LOG.md` с фактическими командами, временем, ошибками.
- Сохранить snapshot виртуальной машины (см. `docs/BUILD_ENV_SETUP.md` §7).
- Если стадия провалена — восстановить snapshot предыдущей стадии, диагностика, повтор.

После Phase 2 (S8 OK):
- Полный `REPORT.md` с: точные версии компонентов; команды сборки; результаты каждого этапа; журналы ошибок; результаты тестирования; текущие ограничения; состояние репозитория; предложение следующего этапа (Phase 3 — modular kernel config + QEMU OVMF UEFI boot).

## 4. Ограничения Phase 2 (явные)

- **Не реализовывать A/B** (решение владельца; ADR-0008 Proposed; 5 схем для сравнения; 7 gate-conditions G1–G7 — будут рекреированы).
- **Не устанавливать загрузчик на физические диски** — только на виртуальные диски/loop-файлы для QEMU.
- **Не изменять физические разделы основного компьютера.**
- **Не выдавать QEMU-тестирование за аппаратную совместимость** — явно stated владельцем.
- **Не выполнять автоматические commits и push** (§10).
- **Не устанавливать пакеты в текущую sandbox** (запрет владельца; вариант B отклонён).
- **Разделять статусы:** Implemented / Verified Build / Verified QEMU / Verified Hardware.
- **Если KVM недоступен — не выдавать TCG за эквивалент** (req #9): TCG пригоден только для функциональной проверки загрузки, не для достоверных performance benchmarks.

## 5. Риски и митигации

| Risk | Probability | Mitigation |
|---|---|---|
| Nested KVM недоступен на хосте | medium | TCG fallback; Phase 2 S7 медленнее; функциональная проверка загрузки валидна, performance benchmarks на TCG недостоверны; владелец осведомлён (req #9). |
| Disk full на Disk 2 (60 GB) | low | Monitor `df -h /mnt/lfs`; cleanup между проходами; расширить Disk 2 при необходимости. |
| OOM при компиляции gcc/glibc | low (12–16 GB RAM) | `make -j1` для крупных пакетов при необходимости. |
| QEMU boot fails | medium | Serial console вывод для diag; iteratively править grub.cfg / initramfs; snapshot recovery. |
| Несовпадение версий исходников | low | sources.lock + SHA256 verified в S2. |
| Воспроизводимость (rebuild diff) | medium | SOURCE_DATE_EPOCH; зафиксировать build flags; documented acceptable diffs. |
| Network blocked в VM | low | mirrors.kernel.org fallback; pre-download sources. |

## 6. Связанные документы

- `docs/BUILD_ENV_SETUP.md` — финальная инструкция развёртывания VM.
- `docs/adr/0009-build-environment-vm.md` — решение о Build VM (Accepted).
- `sources.lock` — манифест исходников (URL + SHA256).
- `KERNEL_POLICY.md` — политика ядра 6.18.y LTS.
- `scripts/host-version-check.sh` — S0 preflight скрипт.
- `scripts/lib/lfs-safety.sh` — библиотека безопасности.
