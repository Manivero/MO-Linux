# BUILD_ENV_SETUP — Final instruction: deployment of permanent isolated Build VM

Статус: **Implemented** (финальная инструкция v2; владелец выполняет развёртывание VM).
Целевая конфигурация утверждена владельцем 2026-10-31 (см. ADR-0009, Accepted; OWNER DECISION — Phase 2 Build Environment).
Исправления v2 (2026-10-31): 7 пунктов владельца — lsblk-first disk identification, UUID в /etc/fstab, admin не в группе lfs без необходимости, lfs не в libvirt без обоснования, не требовать отключения Hyper-V/VBS, разделение build/test tools, TCG как первоклассный fallback.
Исправления v3 (2026-10-31, дополнительное решение владельца): Nested KVM **НЕ является обязательным условием**; использовать VMware или VirtualBox для Debian VM; QEMU TCG — полноценный fallback (не «деgraded», а эквивалентная функциональность с другой скоростью).

## 0. Целевая конфигурация VM (owner decision 2026-10-31)

| Параметр | Значение |
|---|---|
| ОС VM | Debian 13 (trixie) amd64 |
| vCPU | 8 |
| RAM | 12–16 GB |
| Virtual Disk 1 | 40 GB — Debian host (system + apt packages + admin home) |
| Virtual Disk 2 | 60 GB — LFS workspace (/mnt/lfs + /mnt/test-disk) |
| Admin account | `admin` (для apt-install, snapshots, hypervisor ops) |
| Build account | `lfs` — непривилегированный, **БЕЗ sudo, БЕЗ libvirt, БЕЗ kvm-группы без обоснования** |
| Nested virtualization | **НЕ обязательна.** Использовать если доступна; не требовать модификаций хоста (Hyper-V/VBS) ради неё |
| QEMU backend | KVM если `/dev/kvm` доступен (bonus); иначе **TCG — полноценный fallback** (функциональная проверка загрузки — да; достоверные performance benchmarks — НЕТ) |
| Сеть | NAT или bridged; доступ к kernel.org, lfs-matrix.net, mirrors.kernel.org, deb.debian.org |
| Snapshots | обязательно перед S0, S1, S2 и каждым критическим этапом |
| Хранение логов | на Virtual Disk 2 (LFS workspace) |

Это **целевая** конфигурация. Фактические ресурсы проверяются после создания VM (см. §7 Readiness checklist).

## 1. Требования к хост-машине

VM запускается на хост-машине владельца. Гипотеза: Windows (так как владелец явно упомянул «Не изменять основной Windows»). Если хост Linux — пропустите §1.1 и используйте libvirt/KVM напрямую.

### 1.1. Гипервизор (выбрать один)

**Важно (решение владельца 2026-10-31): Nested KVM НЕ является обязательным условием.** Можно использовать VMware или VirtualBox — оба работают для Debian VM. Если nested KVM недоступен — QEMU TCG является полноценным fallback: сборка LFS и QEMU boot-to-login проходят полностью.

| Гипервизор | Платформа | Nested KVM | Snapshot | Рекомендация |
|---|---|---|---|---|
| **VirtualBox 7.x** | Windows/macOS/Linux | ⚠️ частично (VT-x inside VT-x; AMD-V не поддерживается nested) | ✅ | ✅ **рекомендуется** — просто и бесплатно; TCG fallback работает |
| **VMware Workstation Pro 17+** | Windows/Linux | ✅ full (Intel VT-x/EPT) | ✅ | ✅ **рекомендуется** — даёт nested KVM на Intel-хосте без модификаций Windows |
| **Hyper-V (Windows Pro/Enterprise)** | Windows | ✅ full, **если уже включён** | ✅ checkpoint | использовать только если уже включён; **не включать ради Phase 2** (см. §1.2) |
| **libvirt + KVM** | Linux хост | ✅ full (если хост-ядро поддерживает nested=1) | ✅ | нативный путь для Linux-хоста |
| **WSL2 + nested KVM** | Windows | ⚠️ экспериментально | нет native snapshots | не рекомендуется для Phase 2 |

**Рекомендация:** VMware Workstation Pro 17+ ИЛИ VirtualBox 7.x — оба полностью подходят для Phase 2. VirtualBox проще для старта; VMware даёт nested KVM на Intel-хосте. Разницы для LFS-сборки нет — сборка (S2–S5) выполняется внутри VM без QEMU вообще; QEMU (S6–S8) работает и на KVM, и на TCG.

### 1.2. Важное уточнение по Hyper-V, VBS и защитным механизмам Windows (исправление #5 + решение владельца 2026-10-31)

**Абсолютный запрет на любые изменения настроек безопасности Windows. Не требовать и не выполнять:**
- отключение Hyper-V (если уже включён — оставить; если выключен — не включать ради Phase 2);
- отключение Windows VBS (Virtualization-Based Security);
- отключение Memory Integrity (Core Isolation);
- изменения настроек безопасности Windows (Defender, Firewall, SmartScreen, и т.д.);
- модификации BCD или `bcdedit`;
- изменения BIOS/UEFI настроек хост-машины (кроме стандартного включения VT-x/AMD-V, если ещё не включено — это hardware-feature, а не «настройка безопасности»);
- любые другие защитные механизмы.

**Если nested KVM недоступен из-за конфигурации Windows — Phase 2 работает на TCG. Это полноценный режим, не деградация:**
- сборка LFS (S2–S5) вообще не требует QEMU — компиляция идёт на CPU VM напрямую;
- QEMU boot (S7) работает на TCG функционально идентично KVM (та же система загружается, те же тесты проходят);
- разница только в скорости: TCG медленнее примерно в 3–10× на x86 boot;
- TCG подходит для **функциональной проверки загрузки** (boot to login, все функциональные тесты S7–S8), но **НЕ для достоверных performance benchmarks** — тайминги, собранные на TCG, искажены software-эмуляцией (boot-time, idle-RAM, disk I/O); численные метрики производительности собираются только на KVM или реальном железе (Phase 5+);
- req #9 соблюдён: TCG-время не выдавать за эквивалент KVM, backend задокументировать.

Ожидаемое время S7 (QEMU boot to login):
- KVM: 1–3 минуты.
- TCG: 2–10 минут.

Оба режима проходят функциональные тесты S7–S8.

### 1.3. Аппаратные требования к хост-машине

| Параметр | Минимум | Рекомендация |
|---|---|---|
| CPU cores | 8 logical (для 8 vCPU VM) | 12+ (оставить 4 для хоста) |
| RAM | 16 GB (12 GB VM + 4 GB хост) | 24+ GB |
| Disk free | 120 GB (40+60 GB виртуальные диски + overhead) | 200+ GB |
| BIOS/UEFI | VT-x/AMD-V enabled (стандарт) | — |
| ОС | Windows 10/11 (любая редакция для VirtualBox/VMware; Pro/Enterprise если Hyper-V уже включён) | — |

## 2. Создание виртуальной машины (шаг за шагом)

### 2.1. Создание VM в гипервизоре

**VirtualBox 7.x:**
1. New VM → Name: `lfs-build` → Type: Linux → Version: Debian (64-bit).
2. RAM: 12288 MB (12 GB) или 16384 MB (16 GB).
3. CPU: 8 vCPU (Settings → System → Processor).
4. **Enable Nested VT-x/AMD-V** (если хост Intel): Settings → System → Processor → «Enable Nested VT-x/AMD-V» (✓). На AMD может быть недоступно — это нормально, fallback на TCG.
5. Create Virtual Hard Disk 1: 40 GB, VDI, dynamically allocated.
6. Settings → Storage → Add SATA controller → Create second VDI 60 GB (dynamically allocated) — для LFS workspace.
7. Settings → Storage → Attach Debian 13 netinst ISO to SATA optical drive.
8. Settings → Network → Adapter 1: NAT.
9. Settings → System → Motherboard → Enable EFI (опционально, для UEFI-тестов в Phase 3; для Phase 2 не критично).
10. Settings → Acceleration → Paravirtualization: Default (Hyper-V или KVM).

**VMware Workstation Pro 17:**
1. Create a New Virtual Machine → Custom (advanced).
2. Hardware compatibility: Workstation 17.x.
3. Guest OS: Linux → Debian 12.x 64-bit (Debian 13 нет в списке — выбрать 12, это не критично).
4. VM name: `lfs-build`; location: по выбору.
5. Processors: 8.
6. **Virtualize Intel VT-x/EPT or AMD-V/RVI**: ✅ (если хост поддерживает; не требует модификаций Windows).
7. Memory: 12288 MB или 16384 MB.
8. Network: NAT.
9. SCSI Controller: LSI Logic (по умолчанию).
10. Virtual disk type: NVMe (если хост поддерживает) или SCSI.
11. Disk 1: 40 GB.
12. After creation: Edit settings → Add → Hard Disk → SCSI/NVMe → 60 GB (Disk 2 для LFS workspace).

### 2.2. Установка Debian 13

1. Скачать Debian 13 netinst ISO: https://www.debian.org/CD/netinst/ (amd64).
2. Загрузить VM с ISO.
3. Установить Debian 13 (trixie):
   - Language: English (рекомендуется для системы; для пользователя возможен любой).
   - Location: по выбору (влияет на timezone).
   - Keyboard: English (US) (рекомендуется).
   - Hostname: `lfs-build`.
   - Domain: пусто (или по выбору).
   - Root password: задать сложный, **записать в менеджер паролей**.
   - Full name for new user: `LFS Build Admin`.
   - Username for account: `admin`.
   - Password for admin: задать, **записать**.
4. Partitioning method: **Manual** (важно — см. §3). Размечается **только Disk 1** (40 GB); Disk 2 (60 GB) НЕ трогать на этом этапе.
5. Package manager: выберите зеркало по геолокации.
6. Use non-free firmware: **Yes** (важно для некоторых virtio/network drivers).
7. Software selection:
   - **✅ SSH server** (обязательно — для доступа из рабочей среды).
   - **✅ standard system utilities**.
   - ❌ Debian desktop environment (не нужен).
   - ❌ GNOME/XFCE/KDE (не нужны).
   - ❌ web server, print server (не нужны).
8. GRUB: установить на Disk 1 (виртуальный). **Никогда** на физический диск хоста. Если installer спрашивает «Install GRUB on /dev/sda?» — убедиться, что /dev/sda это виртуальный Disk 1 (проверить через `lsblk` в installer shell, если есть сомнения).
9. Finish installation, перезагрузка.

### 2.3. После первой загрузки — базовая настройка (под `admin`)

```bash
# Подключиться по SSH (если VM на NAT, использовать port forwarding) или через консоль гипервизора.
ssh admin@<vm-ip-or-localhost-portforwarded>

# 1. Обновить систему
sudo apt update && sudo apt full-upgrade -y
```

### 2.4. Установка пакетов — разделение build tools и test tools (исправление #6)

Пакеты разделены на 3 категории. Устанавливать по категориям — это упростит аудит и будущие дополнения.

#### Категория A — обязательные build tools (для LFS-сборки S2–S5)

Без этих пакетов LFS-сборка невозможна. Установка обязательна.

```bash
sudo apt install -y \
  build-essential \
  bison \
  gawk \
  texinfo \
  libelf-dev \
  libssl-dev \
  libncurses-dev \
  flex \
  bc \
  cpio \
  rsync \
  wget \
  ca-certificates \
  gnupg
```

#### Категория B — обязательные системные tools (для VM operations)

```bash
sudo apt install -y \
  sudo \
  openssh-server \
  curl \
  man-db \
  manpages-dev \
  vim \
  less \
  git
```

#### Категория C — test tools (для QEMU S6–S8)

Эти пакеты нужны для тестирования (S6–S8), но не для компиляции (S2–S5). Можно установить сразу или отложить до S6.

```bash
sudo apt install -y \
  qemu-system-x86 \
  qemu-utils \
  shellcheck
```

#### Категория D — опциональные libvirt tools (только если будет использоваться libvirt вместо raw QEMU)

**Внимание (исправление #4):** `libvirt-daemon-system`, `libvirt-clients`, `bridge-utils`, `virt-manager` НЕ нужны, если QEMU будет запускаться напрямую через `qemu-system-x86_64` (что рекомендуется для Phase 2 — проще, меньше слоёв). Устанавливать только если есть конкретная причина использовать libvirt.

```bash
# ТОЛЬКО если выбран libvirt-стек (не рекомендуется для Phase 2):
# sudo apt install -y libvirt-daemon-system libvirt-clients bridge-utils virt-manager
```

#### Сводная таблица категорий

| Категория | Назначение | Когда нужны | Кол-во пакетов |
|---|---|---|---|
| A | build tools | S2–S5 (обязательно) | 14 |
| B | system tools | всегда (обязательно) | 8 |
| C | test tools | S6–S8 (обязательно для тестов) | 3 |
| D | libvirt (опционально) | только если libvirt-стек | 4 (не устанавливать по умолчанию) |

### 2.5. Создание пользователя `lfs` (без sudo!)

```bash
sudo adduser lfs
# Задать пароль для lfs, записать в менеджер паролей.
# НЕ добавлять lfs в sudo/wheel групп.
```

### 2.6. Группа `lfs` (исправление #3)

**Создать группу `lfs` и добавить в неё ТОЛЬКО пользователя `lfs`.** Не добавлять `admin` в группу `lfs` без необходимости.

```bash
sudo groupadd -f lfs
sudo usermod -aG lfs lfs
```

Если `admin`-у понадобится читать файлы в `/mnt/lfs` (например, для диагностики) — использовать `sudo -u lfs` или `sudo cat` для конкретных файлов, а не постоянное членство в группе. Если всё же требуется постоянный доступ — добавить `admin` в `lfs` осознанно:

```bash
# ТОЛЬКО если есть конкретная причина (не по умолчанию):
# sudo usermod -aG lfs admin
```

### 2.7. KVM группа (исправление #4) — НЕ добавлять lfs в libvirt

Если `/dev/kvm` существует (см. §5.2), `lfs`-у нужен доступ к нему для запуска QEMU с `-enable-kvm`. Это делается через группу `kvm`, **НЕ через libvirt**.

```bash
# Если /dev/kvm существует:
ls -la /dev/kvm  # проверяем владельца и группу
# Ожидается: crw-rw---- 1 root kvm ...
sudo usermod -aG kvm lfs    # lfs получает доступ к /dev/kvm
# НЕ ВЫПОЛНЯТЬ: sudo usermod -aG libvirt lfs  (libvirt не используется; lfs не должен получать админ-привилегий)
```

Если `/dev/kvm` не существует — пропустить этот шаг; QEMU будет на TCG (см. §5.3).

## 3. Дисковая структура — Disk 2 (60 GB LFS workspace)

### 3.1. Идентификация диска — ОБЯЗАТЕЛЬНАЯ проверка перед fdisk (исправление #1)

**Перед любыми операциями с диском** — определить, какой именно устройство соответствует Disk 2 (60 GB). Не предполагать, что это `/dev/sdb` — это может быть `/dev/sdb`, `/dev/sdc`, `/dev/nvme0n1`, `/dev/vdb`, `/dev/xvdb`, и т.д.

#### Шаг 1. Получить полный список блочных устройств

```bash
lsblk --output NAME,SIZE,MODEL,VENDOR,TYPE,MOUNTPOINTS,FSTYPE
```

Пример вывода (VMware, 2 виртуальных диска):
```
NAME     SIZE MODEL             VENDOR   TYPE MOUNTPOINTS FSTYPE
sda       40G Virtual disk     VMware   disk
├─sda1    39G                            part /            ext4
└─sda2   977M                            part [SWAP]        swap
sdb       60G Virtual disk     VMware   disk
sr0      1.4G VMware IDE CDRom          rom
```

Пример вывода (VirtualBox с NVMe controller):
```
NAME      SIZE MODEL             VENDOR   TYPE MOUNTPOINTS FSTYPE
sda        40G                   ATA     disk
├─sda1     39G                            part /
└─sda2    977M                            part [SWAP]
nvme0n1    60G                   NVMe     disk
sr0       1.4G                            rom
```

#### Шаг 2. Сопоставить с целевой конфигурацией

Найти устройство, у которого:
- `SIZE` ≈ 60G (допускается 60.0G или ~64.4G в пересчёте GiB→GB; точное значение зависит от гипервизора);
- `TYPE` = `disk` (не `part`, не `rom`);
- `MOUNTPOINTS` пустой (ещё не смонтирован);
- `FSTYPE` пустой (ещё не отформатирован);
- `MODEL` / `VENDOR` указывает на виртуальный диск гипервизора (например, «Virtual disk» / «VMware» / «VBOX» / «QEMU»).

Если несколько устройств удовлетворяют критериям — остановиться и спросить владельца, прежде чем продолжать.

#### Шаг 3. Дополнительная проверка через `fdisk -l` и `udevadm`

```bash
# Заменить /dev/sdX на найденное устройство
sudo fdisk -l /dev/sdX
# Должно показать: Disk /dev/sdX: 60 GiB, 64424509440 bytes, 125829120 sectors
# Без partition table (если ещё не размечен): "Disk /dev/sdX doesn't contain a valid partition table"

# Проверить через udev (детальная информация о устройстве):
sudo udevadm info --query=all --name=/dev/sdX | grep -E 'ID_MODEL|ID_VENDOR|ID_BUS|ID_TYPE|DEVPATH'
# Ожидается: ID_MODEL=Virtual disk, ID_VENDOR=VMware (или аналогичное для вашего гипервизора)
# ID_TYPE=disk, ID_BUS=scsi (или nvme/virtio)

# Записать найденное имя устройства в переменную для следующих шагов:
LFS_DISK=/dev/sdX   # ЗАМЕНИТЬ на найденное устройство!
echo "LFS_DISK=$LFS_DISK"
# Пример: LFS_DISK=/dev/sdb
```

**Только после этого переходить к §3.2 (разметка).**

### 3.2. Разметка

**ВНИМАНИЕ:** во всех командах ниже заменить `$LFS_DISK` на фактическое устройство из §3.1.

```bash
# Безопасная проверка: убедиться, что переменная задана
echo "About to fdisk: $LFS_DISK"
[ -z "$LFS_DISK" ] && { echo "ERROR: LFS_DISK not set. Stop."; exit 1; }
[ "$LFS_DISK" = "/dev/sda" ] && { echo "ERROR: refusing to touch /dev/sda (system disk). Stop."; exit 1; }

# Разметка одним разделом на весь диск
sudo fdisk $LFS_DISK
# В fdisk:
#   o  (создать новую DOS partition table)
#   n  (новый раздел: p, primary, 1, default, default — весь диск)
#   w  (записать изменения)

# Перечитать partition table
sudo partprobe $LFS_DISK
lsblk $LFS_DISK
# Должен появиться раздел ${LFS_DISK}1 (например, /dev/sdb1)

# Запомнить имя раздела
LFS_PART=${LFS_DISK}1
echo "LFS_PART=$LFS_PART"
```

### 3.3. Форматирование

```bash
sudo mkfs.ext4 -L lfsws $LFS_PART
# Проверить:
sudo dumpe2fs -h $LFS_PART | grep -E 'Filesystem UUID|Filesystem volume name'
# Записать UUID (понадобится для /etc/fstab):
LFS_UUID=$(sudo blkid -s UUID -o value $LFS_PART)
echo "LFS_UUID=$LFS_UUID"
```

### 3.4. Монтирование и /etc/fstab (исправление #2 — UUID, не device name)

```bash
sudo mkdir -p /mnt/lfs
sudo mount $LFS_PART /mnt/lfs

# ВАЖНО: в /etc/fstab использовать UUID, не /dev/sdX1
echo "UUID=$LFS_UUID /mnt/lfs ext4 defaults,noatime 0 0" | sudo tee -a /etc/fstab

# Проверить fstab (без перезагрузки —тест mount):
sudo umount /mnt/lfs
sudo mount /mnt/lfs    # должно смонтироваться через fstab по UUID
df -h /mnt/lfs         # должно показать ~60 GB (с учётом ext4 overhead ~58 GB)
mount | grep /mnt/lfs  # должно показать: /dev/sdX1 on /mnt/lfs type ext4 (rw,relatime,...)
```

### 3.5. Создание подкаталогов

```bash
sudo mkdir -p /mnt/lfs/{sources,tools,test-disk,build-logs,checkpoints}
sudo chown -R lfs:lfs /mnt/lfs
sudo chmod -R 0755 /mnt/lfs
sudo chmod 1777 /mnt/lfs/sources    # sticky bit для sources, как требует LFS
sudo chmod 0755 /mnt/lfs/test-disk
ls -la /mnt/lfs/
```

### 3.6. Дерево каталогов после настройки

```
/mnt/lfs/                    # Disk 2, ext4, owner lfs:lfs, монтирован по UUID
├── sources/                 # 1777 (sticky), .tar.xz исходники + патчи (~2 GB)
├── tools/                   # temp toolchain (S3; ~3 GB)
├── test-disk/               # QEMU images, virtual disk для S7 (~5 GB)
│   ├── disk.qcow2           # тестовый виртуальный диск 5 GB (создаётся в S6)
│   └── initramfs-staging/   # подготовка initramfs
├── build-logs/              # логи сборки каждого пакета
├── checkpoints/             # tar snapshots между стадиями
└── (S4 rootfs соберётся прямо в /mnt/lfs/{bin,etc,lib,...})
```

## 4. Конфигурация пользователя `lfs`

### 4.1. /home/lfs/.bash_profile

```bash
sudo -u lfs bash -c 'cat > ~/.bash_profile << "EOF"
# LFS user environment
exec env -i HOME=${HOME} TERM=${TERM} PS1="\u:\w\$ " /bin/bash
EOF'
```

### 4.2. /home/lfs/.bashrc (LFS 13.1 §4.3)

```bash
sudo -u lfs bash -c 'cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=x86_64-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS="-j$(nproc)"
EOF'
```

### 4.3. Проверка (sudo от root)

```bash
sudo -u lfs bash -lc 'echo "LFS=$LFS LFS_TGT=$LFS_TGT PATH=$PATH MAKEFLAGS=$MAKEFLAGS"'
# Должно показать:
# LFS=/mnt/lfs LFS_TGT=x86_64-lfs-linux-gnu PATH=/mnt/lfs/tools/bin:/usr/bin:/bin MAKEFLAGS=-j8

# Проверить, что lfs НЕ в libvirt, НЕ в sudo:
groups lfs
# Ожидается: lfs lfs (никаких libvirt, sudo, wheel)
# Если /dev/kvm существует — должно быть: lfs lfs kvm
```

### 4.4. lfs-safety.sh — установка

```bash
# Скопировать из репозитория проекта (если репо доступен в VM) или скачать
sudo install -m 0755 /path/to/scripts/lib/lfs-safety.sh /usr/local/lib/lfs-safety.sh
sudo -u lfs bash -c 'echo "source /usr/local/lib/lfs-safety.sh" >> ~/.bashrc'

# Self-test
sudo -u lfs bash -lc '/usr/local/lib/lfs-safety.sh --self-test'
# Ожидается: self-test OK (5/5)
```

## 5. QEMU и KVM — финальная проверка

### 5.1. Проверить наличие QEMU

```bash
qemu-system-x86_64 --version
# Ожидается: QEMU emulator version 8.x или новее
qemu-img --version
# Ожидается: qemu-img version 8.x
```

### 5.2. Проверить /dev/kvm (nested virt)

```bash
ls -la /dev/kvm 2>/dev/null
# Если существует: crw-rw---- 1 root kvm 10, 232 ... /dev/kvm
# Если нет: файл не найден — KVM недоступен, использовать TCG (см. §5.3)
```

#### Если /dev/kvm существует

```bash
# lfs должен быть в группе kvm для доступа к /dev/kvm
groups lfs
# Если lfs не в kvm:
sudo usermod -aG kvm lfs
# (требуется re-login lfs для применения группы)
# НЕ добавлять lfs в libvirt!

# Проверить nested (если Intel):
cat /sys/module/kvm_intel/parameters/nested 2>/dev/null
# Y = nested включён; N = выключен (можно включить через modprobe kvm_intel nested=1,
# но это требует прав root в VM и не критично для Phase 2)

# Проверить nested (если AMD):
cat /sys/module/kvm_amd/parameters/nested 2>/dev/null
# 1 = nested включён; 0 = выключен
```

### 5.3. TCG — first-class fallback (исправление #7)

Если `/dev/kvm` недоступен — QEMU работает на TCG (software emulation). Это **полноценный** режим для Phase 2:

- ✅ Сборка LFS (S2–S5) НЕ требует KVM вообще — компиляция идёт на CPU VM напрямую, без QEMU.
- ✅ QEMU boot (S7) работает на TCG, но **медленнее** (примерно в 3–10× на x86 boot):
  - KVM: 1–3 минуты на boot to login.
  - TCG: 2–10 минут на boot to login.
- ✅ Все тесты S8 проходят на TCG функционально; разница только во времени.
- ⚠️ **Граница применимости TCG:** подходит для **функциональной проверки загрузки**, но **не для достоверных performance benchmarks**. Любые численные метрики производительности (boot-time, idle-RAM, disk I/O), собранные на TCG, искажены software-эмуляцией и не характеризуют целевое железо. Benchmark-замеры (Phase 5+) — только на KVM или реальном железе; результат S7 на TCG помечается как `functional-only`.

**Тестовый запуск QEMU (определяет доступный backend автоматически):**

```bash
# Тестовый запуск без -enable-kvm (работает всегда, fallback на TCG)
qemu-system-x86_64 \
  -m 256 -smp 1 -nographic -no-reboot \
  -kernel /dev/null 2>&1 | head -5 || echo "QEMU запускается (ошибка kernel — ожидаемо)"

# Если /dev/kvm существует — тест с KVM:
if [ -e /dev/kvm ]; then
  qemu-system-x86_64 \
    -enable-kvm -m 256 -smp 1 -nographic -no-reboot \
    -kernel /dev/null 2>&1 | head -5 || echo "QEMU+KVM запускается"
else
  echo "INFO: /dev/kvm не существует. Phase 2 S7 будет использовать TCG (медленнее, функционально эквивалентно)."
fi
```

#### Документирование backend для S7 (req #9)

При запуске S7 записать в `tests/results/phase2-qemu-boot-<ts>/backend.txt`:

```
qemu_backend: kvm|tcg
kvm_available: yes|no
nested_kvm_param: Y|N|n/a (AMD)
host_cpu_info: <lscpu output>
note: Если backend=tcg, время S7 boot не эквивалентно KVM. Числа не сравнивать напрямую.
```

## 6. Snapshots — стратегия

| Snapshot name | Когда | Что включает |
|---|---|---|
| `clean-base` | после установки Debian, до apt-install | чистый Debian 13 |
| `after-S0-preflight` | после моего S0 preflight (одобренного) | все пакеты установлены, lfs user готов, /mnt/lfs смонтирован |
| `before-S1` | перед началом S1 | состояние после S0 |
| `before-S2` | перед S2 (скачивание sources) | lfs workspace пуст |
| `before-S3` | перед S3 (temp toolchain) | sources скачаны, SHA256 verified |
| `before-S4` | перед S4 (базовая система LFS) | temp toolchain готов |
| `before-S5` | перед S5 (kernel build) | rootfs базовая система готова |
| `before-S6` | перед S6 (initramfs + GRUB) | ядро собрано |
| `before-S7` | перед S7 (QEMU boot) | диск подготовлен |
| `after-S7-success` | после успешного S7 (boot to login) | готовый bootable disk.qcow2 |
| `after-S8-success` | после S8 (verified QEMU) | финальное состояние Phase 2 |

Если стадия провалилась — восстановить snapshot предыдущей стадии, диагностировать, повторить.

## 7. Readiness checklist — отчёт владельца (что проверить и сообщить мне)

После завершения §2–§5 заполнить и прислать мне:

### 7.1. Чек-лист готовности VM

```
[ ] VM создана в гипервизоре (укажите каком: VirtualBox / VMware / Hyper-V / libvirt)
[ ] vCPU: ___ (target 8)
[ ] RAM: ___ GB (target 12–16)
[ ] Disk 1 (Debian host): ___ GB (target 40)
[ ] Disk 2 (LFS workspace): ___ GB (target 60)
[ ] Debian 13 trixie установлена (uname -a output: ___)
[ ] admin user создан, sudo работает
[ ] lfs user создан, БЕЗ sudo (groups lfs output: ___)
[ ] lfs НЕ в libvirt группе (groups lfs output не содержит 'libvirt'): yes / no
[ ] admin НЕ в lfs группе (если добавили — указать причину): yes / no / not added
[ ] apt full-upgrade выполнен
[ ] Build tools (категория A, 14 пакетов) установлены: yes / no
[ ] System tools (категория B, 8 пакетов) установлены: yes / no
[ ] Test tools (категория C, 3 пакета) установлены: yes / no
[ ] Libvirt tools (категория D) — НЕ установлены (или указать причину): not installed / installed
[ ] Disk 2 идентифицирован через lsblk (укажите device name и SIZE): ___
[ ] Disk 2 размечен (fdisk -l /dev/sdX output: ___)
[ ] /mnt/lfs смонтирован по UUID (grep lfs /etc/fstab output: ___)
[ ] df -h /mnt/lfs output: ___
[ ] /mnt/lfs/sources имеет sticky bit (ls -ld /mnt/lfs/sources: ___)
[ ] /mnt/lfs owner = lfs:lfs (ls -ld /mnt/lfs: ___)
[ ] lfs-safety.sh установлен и self-test OK (5/5)
[ ] qemu-system-x86_64 --version: ___
[ ] qemu-img --version: ___
[ ] /dev/kvm exists: yes / no
[ ] Если yes: groups lfs contains kvm: yes / no
[ ] Если no: TCG-only (задокументировано; Phase 2 S7 будет медленнее)
[ ] Network: ping -c1 kernel.org: yes / no
[ ] Network: ping -c1 ftp.lfs-matrix.net: yes / no
[ ] Snapshot «clean-base» сделан (до S0)
[ ] Snapshot «after-S0-preflight» сделан (после моего S0 preflight)
```

### 7.2. Доступ к VM для меня

Я буду выполнять S0 preflight на VM. Для этого мне нужен один из вариантов доступа:

**Вариант A (рекомендуется): SSH-доступ**
- VM настроена с SSH server (port 22).
- На хост-машине настроен port forwarding: host:2222 → vm:22.
- Мне передаётся команда подключения: `ssh -p 2222 lfs@<host-ip-or-localhost>` или аналогичная.
- Пароль lfs передаётся мне (или на время сессии создаётся отдельный SSH-ключ).

**Вариант B: я работаю через вас (транзитивно)**
- Вы (владелец) выполняете команды, которые я даю, и копируете вывод обратно.
- Медленно, но работает.
- Минимум: вы передаёте вывод `bash scripts/host-version-check.sh` (запущенного на VM как `admin`), плюс вывод `lsblk`, `free -h`, `nproc`, `cat /etc/os-release`, `ls -la /dev/kvm`, `groups lfs`.

**Рекомендация: Вариант B** на этапе S0 preflight — он не требует от владельца настройки port forwarding/SSH tunneling, и я могу дать конкретный список команд, которые нужно запустить и присылать вывод. После S0, если preflight OK — можно подумать о Варианте A.

## 8. Что НЕ делать

- ❌ **Не устанавливать пакеты в текущую sandbox** (запрет владельца; вариант B отклонён).
- ❌ **Не подключать физические диски** компьютера к VM.
- ❌ **Не изменять основной Windows** — никаких отключений Hyper-V/VBS, BCD-изменений, Memory Integrity toggle (исправление #5).
- ❌ **Не устанавливать GRUB на физические диски** — только на виртуальные диски внутри VM (через loopback).
- ❌ **Не давать lfs пользователю sudo** — никогда.
- ❌ **Не добавлять lfs в libvirt** (исправление #4) — только в `kvm` группу, если /dev/kvm существует.
- ❌ **Не добавлять admin в lfs группу без необходимости** (исправление #3) — используйте `sudo -u lfs` для доступа к файлам.
- ❌ **Не использовать /dev/sdb без проверки** (исправление #1) — обязательна идентификация через `lsblk --output NAME,SIZE,MODEL,VENDOR,TYPE,MOUNTPOINTS,FSTYPE` + `udevadm info`.
- ❌ **Не использовать device name в /etc/fstab** (исправление #2) — только UUID.
- ❌ **Не выполнять git commits/push** (§10).
- ❌ **Не выдавать TCG-тесты за эквивалентные по скорости KVM** (req #9); TCG-результаты использовать только как функциональную проверку загрузки, не как performance benchmarks.
- ❌ **Не начинать A/B implementation** (ADR-0008 Proposed; условие владельца).

## 9. Связанные документы

- `docs/adr/0009-build-environment-vm.md` (Accepted) — решение о Build VM.
- `PHASE2_PLAN.md` — детальный план S0–S8.
- `scripts/host-version-check.sh` — S0 preflight скрипт.
- `scripts/lib/lfs-safety.sh` — библиотека безопасности.
- `sources.lock` — манифест исходников (URL + SHA256; SHA256 заполняются в S2).
