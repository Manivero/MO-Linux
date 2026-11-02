# PHASE2_PLAN — Build of a reproducible base Linux system

Статус: **Implemented** (спецификация плана; рекреирован после recycle песочницы; **отредактирован 2026-11-02 — аудит консистентности S0/S1, snapshots, UEFI/BIOS, SSH/security**). S0 preflight ждёт развёртывания permanent Build VM.

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
| QEMU успешно грузит систему через **SeaBIOS** до login prompt | S7 | Planned → Verified QEMU |
| Консоль работает: login, базовые команды (ls, cat, dmesg, journalctl) | S8 | Planned → Verified QEMU |
| Журналирование загрузки работает (`journalctl -b`) | S8 | Planned → Verified QEMU |
| Системные утилиты доступны: coreutils, util-linux, procps, iproute2 | S8 | Planned → Verified QEMU |
| CPU/RAM/disk детектируются корректно (/proc/cpuinfo, free, df) | S8 | Planned → Verified QEMU |
| systemd достигает default target (multi-user.target для base) | S8 | Planned → Verified QEMU |
| Все версии исходников и SHA256 проверены | S2 | Planned → Verified |
| Все этапы сборки воспроизводимы (snapshot + rebuild) | S4 | Planned → Verified Build |

**Phase 2 НЕ завершена, пока S7 (QEMU boot to login через SeaBIOS) не пройдена.** Это явное условие владельца.

**UEFI/OVMF boot — НЕ критерий завершения Phase 2.** OVMF/UEFI-загрузка явно перенесена на Phase 3 (modular kernel config + QEMU OVMF UEFI boot); Phase 2 покрывает только BIOS/SeaBIOS path. В S6 шаг UEFI помечен как «отложен до Phase 3».

Статусы по §5 Project Initiation v2:
- **Planned** — описано в плане, не начато.
- **Implemented** — код/конфиг существует, не проверено.
- **Verified (build)** — собирается воспроизводимо.
- **Verified (QEMU)** — загружается в QEMU и проходит тесты.
- **Verified (hardware)** — проверено на реальном железе (НЕ для Phase 2; QEMU ≠ hardware, явное указание владельца).

## 2. Стадии S0–S8

### S0 — Build VM host preflight (без disk work, без /mnt/lfs, без lfs user)

**Цель:** убедиться, что permanent Build VM соответствует host-уровневым требованиям LFS 13.1-systemd + проектным требованиям (QEMU, диск, RAM, nested KVM). **S0 НЕ требует /mnt/lfs, НЕ требует lfs-safety.sh self-test, НЕ требует свободного места на /mnt/lfs** — эти артефакты создаются в S1.

**Чек-лист S0 (только host-level проверки):**
1. ОС VM = Debian 13 (trixie) amd64 (`cat /etc/os-release`).
2. Ядро VM ≥ 5.10 (требование LFS 13.1) — `uname -r`.
3. vCPU = 8 (`nproc`); RAM ≥ 12 GB выделено VM (`free -h`).
4. Bash ≥ 3.2, binutils ≥ 2.13.1, gcc ≥ 5.4, … — 20 LFS-required tools (через `scripts/host-version-check.sh`).
5. Дополнительные: qemu-system-x86_64 (критично для S7), shellcheck, libelf-dev, libssl-dev.
6. Disk 2 (60 GB LFS workspace) виден в `lsblk` как отдельное блочное устройство (~60G, TYPE=disk, MOUNTPOINTS пустой, FSTYPE пустой). **Идентификация (модель, размер, vendor, UUID) записывается, но разметка и форматирование НЕ выполняются на S0** — это задача S1.
7. /dev/kvm существует (nested virt) — фиксируется факт наличия/отсутствия; **не требуется**, TCG полноценный fallback (req #9).
8. Сетевой доступ к kernel.org, ftp.lfs-matrix.net, mirrors.kernel.org (`ping -c1` или `curl -I`).
9. sources.lock: URL проверены (`python3 scripts/sources-verify.py sources.lock`); SHA256 в `sources.lock` = UNVERIFIED до S2. **Корректная интерпретация exit code** (fix от 2026-11-02):
   - **exit 0** = нет FAIL среди проверенных URL (но **НЕ гарантирует**, что все URL проверены — записи, в которых URL содержит строку `"UNVERIFIED"`, **пропускаются** и считаются как SKIPPED; в текущем `sources.lock` все URL реальные, поэтому SKIPPED = 0 ожидаемо, но это нужно явно видеть в Summary).
   - **exit 1** = есть хотя бы один FAIL (HTTP error, network error, timeout).
   - **exit 2** = `sources.lock` не найден.
   - Exit code НЕ подавлять через `|| echo` — фиксировать фактический.
   - **Обязательно вывести и сохранить полную строку Summary** (`Summary: N OK, N FAIL, N SKIPPED (placeholder)`) — она печатается в stdout последней строкой; для S0 PASS требуется: exit 0 AND FAIL = 0 AND явный анализ SKIPPED (если SKIPPED > 0 — каждый SKIP должен быть объяснён как ожидаемый UNVERIFIED placeholder, а не упущенная проверка).
10. **Владелец присылает мне вывод всех команд S0.** Я провожу аудит и даю явное решение: «**S0 PASS**» (можно делать snapshot `after-S0-preflight` и переходить к S1) либо «**S0 FAIL**» (с указанием, что доработать). **Snapshot `after-S0-preflight` создаётся ТОЛЬКО после моего явного подтверждения «S0 PASS»** — до этого snapshot НЕ создаётся (в случае FAIL он бесполезен, т.к. состояние VM нужно менять).

**Что НЕ проверяется на S0:** /mnt/lfs (ещё не смонтирован), свободное место на /mnt/lfs (ещё не существует), lfs-safety.sh self-test (ещё не установлен), lfs user group membership (ещё не создан).

**Результат S0:** отчёт `bench/results/host-version-check-<ts>.txt` (на VM) + полный вывод `python3 scripts/sources-verify.py sources.lock` (включая Summary строку `N OK, N FAIL, N SKIPPED`; фактический exit code) + запись в `IMPLEMENTATION_LOG.md` + решение «**S0 PASS** / **S0 FAIL**» (от меня, после аудита выводов владельца). Snapshot `after-S0-preflight` — **только после S0 PASS**. **Только S0 PASS разрешает начало S1** (владелец подтверждает disk identity и даёт явное разрешение на fdisk/mkfs).

### S1 — LFS workspace & lfs user setup (владелец + AI; owner approval gate перед fdisk)

**Цель:** разметить Disk 2, смонтировать /mnt/lfs, создать lfs user с idempotent-проверками, установить lfs-safety.sh и пройти self-test. **S1 требует успешного S0** (Disk 2 идентифицирован, host tools готовы).

**Подэтапы S1 (5 шагов — разделены по требованию владельца 2026-11-02):**

**S1.1 — Идентификация Disk 2 (read-only, перед fdisk):**
- `lsblk --output NAME,SIZE,MODEL,VENDOR,TYPE,MOUNTPOINTS,FSTYPE` — полный список блочных устройств.
- Найти устройство: SIZE ≈ 60G, TYPE=disk, MOUNTPOINTS пустой, FSTYPE пустой, MODEL/VENDOR указывает на виртуальный диск гипервизора.
- Дополнительная проверка: `sudo fdisk -l /dev/sdX` + `sudo udevadm info --query=all --name=/dev/sdX | grep -E 'ID_MODEL|ID_VENDOR|ID_BUS|ID_TYPE'`.
- **OWNER APPROVAL GATE:** владелец явно подтверждает (печатает «yes, /dev/sdX is Disk 2, proceed») — без этого подтверждения fdisk НЕ выполняется.

**S1.2 — Разметка Disk 2:**
- `LFS_DISK=/dev/sdX` (заменить на найденное устройство).
- Safety checks: `[ -z "$LFS_DISK" ] && exit 1`; `[ "$LFS_DISK" = "/dev/sda" ] && exit 1`.
- `sudo fdisk $LFS_DISK` — один primary partition на весь диск.
- `sudo partprobe $LFS_DISK`; `lsblk $LFS_DISK` — подтвердить появление `${LFS_DISK}1`.

**S1.3 — Форматирование и монтирование:**
- `sudo mkfs.ext4 -L lfsws ${LFS_DISK}1`.
- `LFS_UUID=$(sudo blkid -s UUID -o value ${LFS_DISK}1)`.
- `sudo mkdir -p /mnt/lfs`; `sudo mount ${LFS_DISK}1 /mnt/lfs`.
- `/etc/fstab` entry через UUID (НЕ device name): `UUID=$LFS_UUID /mnt/lfs ext4 defaults,noatime 0 0`.
- Verify: `sudo umount /mnt/lfs`; `sudo mount /mnt/lfs` (через fstab); `df -h /mnt/lfs` (~58 GB); `mount | grep /mnt/lfs`.

**S1.4 — LFS workspace + lfs user (idempotent):**
- `sudo mkdir -p /mnt/lfs/{sources,tools,test-disk,build-logs,checkpoints}`.
- `sudo chown -R lfs:lfs /mnt/lfs`; `sudo chmod -R 0755 /mnt/lfs`; `sudo chmod 1777 /mnt/lfs/sources`.
- **Создание lfs user (идемпотентное; Debian `adduser` сам создаёт одноимённую группу):**
  ```bash
  # 1. Группа lfs (idempotent — `groupadd -f` выходит 0 и в случае, если группа
  #    уже существует, и в случае, если только что создана; не падает ни в каком сценарии)
  sudo groupadd -f lfs

  # 2. Пользователь lfs (idempotent — пропускает создание, если уже существует).
  #    Debian `adduser lfs` (без --ingroup) использует существующую группу `lfs`
  #    как primary; если группа была создана шагом выше — это нормально.
  if ! id lfs >/dev/null 2>&1; then
    sudo adduser lfs   # интерактивно: владелец задаёт пароль и записывает в менеджер паролей
  fi

  # 3. Убедиться, что lfs — член группы lfs (idempotent: `usermod -aG` не дублирует
  #    существующее членство; harmless, если lfs уже primary member)
  sudo usermod -aG lfs lfs

  # 4. Добавить lfs в kvm ТОЛЬКО если /dev/kvm существует (idempotent)
  if [ -e /dev/kvm ]; then
    sudo usermod -aG kvm lfs
  fi

  # НЕ ВЫПОЛНЯТЬ:
  #   sudo usermod -aG sudo lfs     (lfs — непривилегированный, без sudo)
  #   sudo usermod -aG wheel lfs    (lfs — непривилегированный, без sudo)
  #   sudo usermod -aG libvirt lfs  (libvirt не используется)
  ```
  **Почему `groupadd -f` вместо `getent group lfs || groupadd`:** флаг `-f` делает `groupadd` идемпотентным на уровне самой утилиты — нет гонок между проверкой и созданием, и код короче. Debian `adduser` после этого использует существующую группу `lfs` как primary (поведение по умолчанию).
- `~lfs/.bash_profile` и `~lfs/.bashrc` настроены (см. `docs/BUILD_ENV_SETUP.md` §4.1–§4.2): `LFS=/mnt/lfs`, `LFS_TGT=x86_64-lfs-linux-gnu`, `LC_ALL=POSIX`, `PATH=$LFS/tools/bin:$PATH`, `MAKEFLAGS=-j$(nproc)`.
- Verify (от root): `sudo -u lfs bash -lc 'echo "LFS=$LFS LFS_TGT=$LFS_TGT PATH=$PATH"'`.
- Verify groups: `groups lfs` — ожидается `lfs lfs` (или `lfs lfs kvm` если /dev/kvm); НЕ должно быть `sudo`/`wheel`/`libvirt`.

**S1.5 — lfs-safety.sh установка + final readiness gate:**
- `sudo install -m 0755 /path/to/scripts/lib/lfs-safety.sh /usr/local/lib/lfs-safety.sh`.
- `sudo -u lfs bash -c 'echo "source /usr/local/lib/lfs-safety.sh" >> ~/.bashrc'`.
- Self-test: `sudo -u lfs bash -lc '/usr/local/lib/lfs-safety.sh --self-test'` → ожидается `self-test OK (5/5)`.
- **Final readiness gate S1:**
  - `/mnt/lfs` смонтирован по UUID (`grep lfs /etc/fstab`).
  - `df -h /mnt/lfs` показывает ≥ 15 GB free.
  - `ls -ld /mnt/lfs/sources` → mode `1777`, owner `lfs:lfs`.
  - `groups lfs` не содержит `sudo`/`wheel`/`libvirt`.
  - `groups lfs` содержит `kvm` IFF `/dev/kvm` существует.
  - `lfs-safety.sh --self-test` OK.
- Snapshot «before-S2» сделан.

**Результат S1:** заполненный чек-лист `docs/BUILD_ENV_SETUP.md` §7.1 (от владельца); snapshot VM; запись в `IMPLEMENTATION_LOG.md`. **Только S1 OK разрешает начало S2** (скачивание исходников).

### S2 — Скачивание sources и верификация SHA256

**Цель:** скачать все исходники в `/mnt/lfs/sources/` (~2 GB), верифицировать SHA256, обновить `sources.lock`. **S2 требует успешного S1** (/mnt/lfs смонтирован, lfs user готов, lfs-safety.sh OK). Шаги настройки окружения lfs, выполнявшиеся ранее на стыке S1/S2, теперь полностью в S1 (см. S1.4); S2 только скачивает и верифицирует.

**Шаги:**
1. `~lfs/.bash_profile` и `~lfs/.bashrc` уже настроены в S1.4 — повторная настройка НЕ требуется. Проверить: `sudo -u lfs bash -lc 'echo LFS=$LFS LFS_TGT=$LFS_TGT'` должно показать `LFS=/mnt/lfs LFS_TGT=x86_64-lfs-linux-gnu`.
2. Все исходники скачаны в `/mnt/lfs/sources/` (~2 GB): linux-6.18.59.tar.xz + 13 LFS пакетов + 8 патчей.
3. `sources.lock` обновлён: реальный SHA256 каждого архива после скачивания.
4. Контрольная сумма всего манифеста вычислена и записана.
5. Snapshot «before-S3» сделан.

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
8. Установить GRUB 2.14 (только BIOS path; UEFI — Phase 3):
   - **BIOS (обязательно для Phase 2):** `grub-install --target=i386-pc --boot-directory=/mnt/test-disk/root/boot /dev/nbd0`.
   - **UEFI/OVMF (отложено до Phase 3):** отдельная процедура с OVMF; НЕ критерий завершения Phase 2; см. §1 «UEFI/OVMF boot — НЕ критерий завершения Phase 2» и Phase 3 ROADMAP.
9. `grub-mkconfig -o /mnt/test-disk/root/boot/grub/grub.cfg`.
10. Создать минимальный initramfs (busybox + modules для ext4 и virtio + /init).
11. `umount`, `qemu-nbd --disconnect /dev/nbd0`.
12. Snapshot «before-S7» сделан.

**Результат S6:** `/mnt/lfs/test-disk/disk.qcow2` — загрузочный виртуальный диск. Статус Verified Build.

### S7 — Первая загрузка в QEMU (только BIOS/SeaBIOS path; UEFI — Phase 3)

**Цель:** успешно загрузить собранную систему в QEMU через **SeaBIOS** и достичь login prompt. UEFI/OVMF-загрузка явно отложена до Phase 3 (см. §1 и S6 шаг 8); Phase 2 покрывает только BIOS path.

**Команды (только BIOS path; обе команды — BIOS, различаются только backend KVM/TCG):**
```bash
# BIOS boot с KVM (если /dev/kvm доступен)
qemu-system-x86_64 \
  -enable-kvm -m 1024 -smp 1 \
  -drive file=/mnt/lfs/test-disk/disk.qcow2,format=qcow2,if=virtio \
  -netdev user,id=net0 -device virtio-net,netdev=net0 \
  -nographic -serial mon:stdio \
  -append "console=ttyS0 root=/dev/vda1 rw"

# BIOS boot на TCG (если /dev/kvm недоступен)
qemu-system-x86_64 \
  -m 1024 -smp 1 \
  -drive file=/mnt/lfs/test-disk/disk.qcow2,format=qcow2,if=virtio \
  -netdev user,id=net0 -device virtio-net,netdev=net0 \
  -nographic -serial mon:stdio \
  -append "console=ttyS0 root=/dev/vda1 rw"
```

**Контрольные точки:**
- GRUB выводит меню (BIOS/SeaBIOS path).
- Ядро грузится.
- dmesg показывает корректное определение CPU, RAM, virtio.
- initramfs монтирует root.
- systemd запускается (PID 1).
- `multi-user.target` достигается.
- Login prompt появляется.
- Вход как root (без пароля или с простым паролем для Phase 2).

**Время:** 1–10 минут boot time (измеряется и записывается; backend KVM vs TCG фиксируется в `tests/results/phase2-qemu-boot-<ts>/backend.txt` — req #9; TCG-время НЕ эквивалентно KVM).

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

После каждой стадии S0–S8:
- Обновить `PROJECT_STATUS.md` (статус стадии → Verified Build / Verified QEMU).
- Добавить запись в `IMPLEMENTATION_LOG.md` с фактическими командами, временем, ошибками.
- Сохранить snapshot виртуальной машины (см. `docs/BUILD_ENV_SETUP.md` §6 — каноническая таблица snapshot'ов).
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
- **Не передавать ИИ пароли или приватные SSH-ключи** (правило владельца 2026-11-02): для S0 используется транзитивный доступ — владелец выполняет команды и передаёт вывод. SSH-доступ (если используется на более поздних стадиях) настраивается владельцем локально; ИИ получает только выводы команд.
- **Не требовать изменений Windows Defender/Firewall/SmartScreen/Hyper-V/VBS/Memory Integrity/BCD/BIOS-настроек безопасности** (абсолютный запрет).
- **UEFI/OVMF-загрузка — НЕ критерий Phase 2:** только BIOS/SeaBIOS path; OVMF отложен до Phase 3.
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
