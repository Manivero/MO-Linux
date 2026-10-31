#!/usr/bin/env bash
# scripts/hardware-inventory.sh — read-only hardware inventory
# Recreated 2026-10-31 after sandbox recycle.
#
# Usage: sudo bash hardware-inventory.sh [output_dir]
#   output_dir defaults to ./hw-inventory
#
# Exit codes:
#   0 — partial or full inventory collected
#   1 — fatal error (cannot create output dir)
#   2 — bad args

set -euo pipefail
IFS=$'\n\t'

OUTPUT_DIR="${1:-./hw-inventory}"
RAW_DIR="${OUTPUT_DIR}/raw"

mkdir -p "${RAW_DIR}"

# Save a command's output to a raw file, capturing errors.
# Args: command_name, command...
save_raw() {
    local name="$1"; shift
    local out_file="${RAW_DIR}/${name}.txt"
    if "$@" >"${out_file}" 2>&1; then
        echo "OK   ${name}"
    else
        echo "FAIL ${name} (exit $?) — see ${out_file}"
    fi
}

# Run a command that may be absent; capture nothing if absent.
save_optional() {
    local name="$1"; shift
    if command -v "$1" >/dev/null 2>&1; then
        save_raw "${name}" "$@"
    else
        echo "MISS ${name} (command '$1' not installed)"
        : >"${RAW_DIR}/${name}.missing"
    fi
}

echo "# Hardware inventory — $(date -u +'%Y-%m-%dT%H:%M:%SZ')" >"${OUTPUT_DIR}/inventory.md"
echo "" >>"${OUTPUT_DIR}/inventory.md"
echo "Host: $(uname -a)" >>"${OUTPUT_DIR}/inventory.md"
echo "" >>"${OUTPUT_DIR}/inventory.md"

echo "=== Collecting read-only inventory to ${RAW_DIR} ==="

# 1. CPU
save_raw cpuinfo cat /proc/cpuinfo
save_optional lscpu lscpu

# 2. RAM
save_raw meminfo cat /proc/meminfo
save_optional dmidecode-memory dmidecode -t memory

# 3. GPU
save_optional lspci-vga lspci -nn
save_optional lshw-display lshw -C display

# 4. Wi-Fi
save_optional lspci-net lspci -nn
save_optional lspci-wifi lspci -v -d ::0280

# 5. Bluetooth
save_raw lsusb lsusb
save_optional hciconfig hciconfig -a

# 6. Storage
save_raw lsblk lsblk --output NAME,SIZE,MODEL,VENDOR,TYPE,MOUNTPOINTS,FSTYPE
save_optional hdparm hdparm -I /dev/sda
save_optional smartctl sda smartctl -a /dev/sda

# 7. Audio
save_raw asound-cards cat /proc/asound/cards
save_optional aplay aplay -l

# 8. ACPI
save_raw acpi-battery cat /proc/acpi/battery/BAT0/info 2>/dev/null || true
save_optional acpi-V acpi -V

# 9. Battery (upower)
save_optional upower upower -d

# 10. Touchpad / input
save_raw input-devices cat /proc/bus/input/devices
save_optional xinput-list xinput list
save_optional libinput-list libinput list-devices

# 11. Firmware
save_optional dmidecode-bios dmidecode -t bios
save_optional dmidecode-system dmidecode -t system
save_optional bootctl bootctl status

# 12. Other
save_raw kernel-version uname -a
save_raw os-release cat /etc/os-release 2>/dev/null || true

echo ""
echo "=== Summary ==="
echo "Output dir: ${OUTPUT_DIR}"
echo "Raw files:  $(ls "${RAW_DIR}" | wc -l)"

cat >>"${OUTPUT_DIR}/inventory.md" <<EOF

## Files collected

$(ls raw/ | sed 's/^/- /')

## Notes

- This is a READ-ONLY inventory. Nothing is written to disk or hardware.
- Some commands require root (dmidecode, smartctl). If not root, those files
  will contain an error message and the corresponding section degrades.
- Fill in the device card in docs/devices/<model>.md after collection.
EOF

echo ""
echo "Summary: ${OUTPUT_DIR}/inventory.md"
echo "Done."
