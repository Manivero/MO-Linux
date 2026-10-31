# HARDWARE_INVENTORY — процедура инвентаризации целевого железа

Статус: **Implemented** (рекреирован 2026-10-31 после recycle песочницы).
Скрипт инвентаризации: `scripts/hardware-inventory.sh` (рекреирован).

## 1. Цель

Собрать полную информацию о целевом ноутбуке (предварительный таргет: Intel Core i5-3320M, Ivy Bridge) для:
- заполнения карточки устройства в `docs/devices/<model>.md`;
- проверки совместимости перед Phase 4 (HW tests);
- уточнения RAM/disk/storage profile (Legacy / Standard / Extended).

## 2. Что собирается (12 категорий, по решению владельца Q5)

| # | Категория | Источник | Что именно |
|---|---|---|---|
| 1 | CPU | `/proc/cpuinfo`, `lscpu` | model, cores, threads, frequency, flags (vt-x, lm) |
| 2 | RAM | `/proc/meminfo`, `dmidecode -t memory` | total, slots, type (DDR3/DDR4), speed |
| 3 | GPU | `lspci -nn \| grep -i vga`, `lshw -C display` | model, driver (i915/amdgpu/nouveau), VRAM |
| 4 | Wi-Fi | `lspci -nn \| grep -i net`, `lspci -v -d ::0280` | chipset, driver (iwlwifi, ath9k, rtl818x, brcmsmac), firmware |
| 5 | Bluetooth | `lsusb`, `hciconfig` | USB BT adapter, BlueZ compatibility |
| 6 | Storage | `lsblk`, `smartctl -a /dev/sdX` (если root), `hdparm -I` | model, size, type (HDD/SSD/NVMe), interface (SATA/NVMe), SMART |
| 7 | Audio | `lspci -nn \| grep -i audio`, `aplay -l`, `cat /proc/asound/cards` | codec (Realtek/Conexant/Cirrus), driver (snd_hda_intel) |
| 8 | ACPI | `cat /proc/acpi/...`, `acpi -V` | battery, lid, brightness, thermal, fan |
| 9 | Battery | `upower -d`, `cat /sys/class/power_supply/BAT*/...` | model, capacity, health, charge cycles |
| 10 | Touchpad | `xinput list`, `libinput list-devices`, `cat /proc/bus/input/devices` | protocol (PS/2, I2C, USB), driver (libinput, synaptics) |
| 11 | Firmware | BIOS/UEFI version, mode (BIOS vs UEFI), Secure Boot status | `dmidecode -t bios`, `bootctl status` (если UEFI) |
| 12 | Other | Webcam (`lsusb`), Card reader, Fingerprint, Ethernet | per device |

## 3. Процедура

### 3.1 Подготовка

Запускать с Live USB любого современного Linux (Debian 13, Ubuntu 24.04, Fedora 41 — любой, что загружается на целевом ноутбуке). НЕ устанавливать на диск.

### 3.2 Запуск скрипта

```bash
# Скопировать scripts/hardware-inventory.sh на Live USB
# Запустить от root (для dmidecode, smartctl):
sudo bash hardware-inventory.sh /tmp/hw-inventory
# Output: /tmp/hw-inventory/inventory.md + raw-файлы в /tmp/hw-inventory/raw/
```

### 3.3 Что скрипт делает (неинвазивно, read-only)

- `cat /proc/cpuinfo /proc/meminfo /proc/bus/input/devices`
- `lscpu`, `lsblk`, `lspci -nn -vv`, `lsusb -v`
- `dmidecode -t bios`, `dmidecode -t memory`, `dmidecode -t system`
- `upower -d`
- `xinput list` (если есть X)
- `aplay -l`, `cat /proc/asound/cards`
- `acpi -V`
- `smartctl -a /dev/sdX` (для каждого блочного устройства)
- `bootctl status` (если UEFI)

Все выводы сохраняются в raw-файлы; собирается summary в `inventory.md`.

### 3.4 Smoke-тест

В текущей sandbox Debian 13 (без реального железа) — smoke-тест пройден в предыдущих циклах (39 raw-файлов); секции root-only корректно деградируют если нет прав.

## 4. Карточка устройства (после инвентаризации)

После получения данных инвентаризации — заполнить карточку в `docs/devices/<model>.md` по шаблону:

```markdown
# Device: <manufacturer> <model>

- CPU: <model>, <cores>c/<threads>t, <freq>
- RAM: <total> (<slots> × <size>, <type>, <speed>)
- GPU: <model>, driver <name>, <vram>
- Wi-Fi: <chipset>, driver <name>, firmware <version>
- Bluetooth: <adapter>, BlueZ <version>
- Storage: <model>, <size>, <type> (<interface>)
- Audio: <codec>, driver <name>
- Touchpad: <protocol>, driver <name>
- Battery: <model>, <capacity> Wh, health <percent>
- BIOS/UEFI: <version>, mode <BIOS|UEFI>, Secure Boot <on|off|unsupported>
- Webcam: <model> (if present)
- Tested with: distro <name> <version>, kernel <version>
- Compatibility: works / partial / fail (per subsystem)

## Test results (Phase 4)

(заполняется после HW тестов)
```

## 5. Совместимость (предварительная оценка)

Для Intel Core i5-3320M (Ivy Bridge, 2012, HD 4000):
- ✅ CPU: x86_64, vt-x, поддерживается 6.18.y LTS (i915 driver mature для HD 4000).
- ⚠️ Wi-Fi/BT: зависит от конкретной модели ноутбука (Centrino Advanced-N 6235 — iwlwifi, хорошо; Broadcom BCM4313 — brcmsmac/b43, частично).
- ✅ GPU: HD 4000 — i915 driver, работает без firmware.
- ✅ Storage: SATA HDD или SSD (зависит от конкретного устройства).
- ✅ Audio: HDA codec (Realtek/Conexant), snd_hda_intel.
- ⚠️ Touchpad: зависит от модели (PS/2 synaptics, I2C ELAN, USB).
- ✅ Battery, brightness, lid: ACPI standard.

Точная совместимость НЕ фиксируется до инвентаризации и тестов Phase 4.

## 6. Связанные документы

- `scripts/hardware-inventory.sh` — скрипт инвентаризации (рекреирован).
- `docs/HARDWARE_TEST_PLAN.md` — HW-тесты (Phase 4).
- `TARGET_HARDWARE.md` — profiles + device sheet placeholder.
- `ADR-0009` (Accepted) — build VM (если инвентаризация проводится внутри VM, не на Live USB).
