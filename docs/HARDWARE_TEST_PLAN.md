# Hardware test plan

Per Project Initiation v2 §5: «Всё, что нельзя проверить без железа, получает план проверки в `docs/HARDWARE_TEST_PLAN.md`». This document lists every hardware-dependent verification we cannot perform in Phase 0 and prescribes the test that must be run when target hardware becomes available (Phase 4).

## 1. Verification ladder (recap)

| Status | Meaning |
|---|---|
| Planned | Described in design; code/tests not written. |
| Implemented | Code/config exists; not yet verified. |
| Verified (build) | Reproducible build (compile + checksum). |
| Verified (QEMU) | Boots and passes QEMU tests. |
| Verified (hardware) | Tested on a real device, with model recorded. |

## 2. Hardware-dependent verifications deferred from Phase 0

| ID | What to verify | Test procedure | Pass criterion | Where to record |
|---|---|---|---|---|
| HW-01 | BIOS boot to login | Boot from legacy BIOS laptop with SeaBIOS-equivalent firmware | Reaches `login:` prompt within 60 s of power-on; `dmesg` shows no `BUG:` / `WARN:` | `docs/devices/<model>.md` |
| HW-02 | UEFI boot to login | Boot from pre-2018 UEFI laptop, Secure Boot OFF | Same as HW-01 | `docs/devices/<model>.md` |
| HW-03 | UEFI + Secure Boot | (Phase 8) Boot from a Secure-Boot-enforcing UEFI laptop | Either boots with project-signed shim, OR documented as unsupported | `SECURITY_MODEL.md` |
| HW-04 | Intel iGPU modesetting | On a Sandy Bridge or newer Intel iGPU laptop, boot to Xfce | `glxinfo` reports direct rendering; `xrandr` lists native panel mode | `docs/devices/<model>.md` |
| HW-05 | AMD iGPU modesetting | On an AMD A-series or Ryzen laptop, boot to Xfce | Same as HW-04 | `docs/devices/<model>.md` |
| HW-06 | NVIDIA legacy | On a laptop with a GeForce 6–9-series GPU, test nouveau | `glxinfo` reports direct rendering on nouveau; document closed-source 304/340 driver as separate case | `docs/devices/<model>.md` |
| HW-07 | SATA HDD boot | Boot from 5400-rpm HDD | Reaches login within 90 s; `fio` 4K random read ≥ 0.5 MB/s | `docs/devices/<model>.md` |
| HW-08 | SATA SSD boot | Boot from SATA SSD | Reaches login within 30 s; `fio` 4K random read ≥ 5 MB/s | `docs/devices/<model>.md` |
| HW-09 | NVMe boot | Boot from NVMe SSD | Reaches login within 25 s; `nvme smart-log` shows healthy | `docs/devices/<model>.md` |
| HW-10 | Wi-Fi connect | Connect to WPA2/3 AP via NetworkManager | `nmcli` shows connected; ping 8.8.8.8 succeeds | `docs/devices/<model>.md` |
| HW-11 | Bluetooth | Pair a BT speaker or phone | `bluetoothctl` shows paired; audio test passes | `docs/devices/<model>.md` |
| HW-12 | Audio output | Play a test tone | `aplay` test tone audible | `docs/devices/<model>.md` |
| HW-13 | Touchpad | Tap, two-finger scroll, three-finger swipe | All three gestures work in Xfce | `docs/devices/<model>.md` |
| HW-14 | Brightness control | Adjust brightness via `xfce4-power-manager` slider | Screen brightness visibly changes; `cat /sys/class/backlight/.../brightness` reflects change | `docs/devices/<model>.md` |
| HW-15 | Battery reporting | Unplug AC; check `upower -d` | Battery percentage decrements realistically over 30 min | `docs/devices/<model>.md` |
| HW-16 | Lid open/close | Close lid for 5 s, open | System suspends on close, resumes on open; no `dmesg` errors | `docs/devices/<model>.md` |
| HW-17 | Suspend to RAM (s3) | `systemctl suspend`, wake after 30 s | Resumes; network reconnects; audio works | `docs/devices/<model>.md` |
| HW-18 | Suspend to disk (s4) | `systemctl hibernate`, wake | Resumes from swap partition | `docs/devices/<model>.md` |
| HW-19 | USB mass storage | Plug USB stick | Auto-mounts under `/run/media/<user>/`; read/write succeed | `docs/devices/<model>.md` |
| HW-20 | Webcam | `cheese` or `ffplay /dev/video0` | Live image displayed | `docs/devices/<model>.md` |
| HW-21 | Reboot stress | 50 reboot cycles | All 50 reach login; no fsck errors | `bench/results/<date>-reboot-stress/` |
| HW-22 | Idle RAM | 5-min idle, then `smem -t -k` | Idle MemAvailable ≥ 1024 MB on Legacy; ≥ 2048 MB on Standard | `bench/results/<date>-idle-ram/` |
| HW-23 | Boot time | Cold boot from GRUB to login, median of 5 | ≤ 30 s on Standard SSD; ≤ 60 s on Legacy HDD | `bench/results/<date>-boot-time/` |

## 3. Device sheet template

```markdown
# <Manufacturer> <Model> — <profile>

- **Date tested:** YYYY-MM-DD
- **Tester:** <name>
- **Profile:** Legacy | Standard | Extended
- **Phase:** 4 | 5 | 6+

## Hardware
- CPU: ...
- RAM: ...
- Disk: ...
- GPU: ...
- Wi-Fi: ... (PCI ID)
- Audio: ...
- BIOS/UEFI: ... (version, Secure Boot status)
- Battery: ...
- Suspend: s3 yes/no, s4 yes/no

## PCI/USB IDs
\`\`\`
$ lspci -nnk
$ lsusb
\`\`\`

## Test results
| ID | Result | Notes |
|---|---|---|
| HW-01 | PASS | ... |
| ... | ... | ... |

## Known issues
- ...

## Driver / firmware notes
- ...
```

## 4. Owner-provided hardware

As of Phase 0, **no target hardware has been provided**. All HW-* tests are listed as "not run, awaiting hardware". The owner's first Phase 4 message should name the target laptop(s).

## 5. Pre-Phase-4 QEMU substitutes

Where QEMU can substitute for hardware testing before Phase 4, the test is listed in `TESTING_STRATEGY.md` (Phase 1) as a QEMU test, not here. This document is exclusively for tests that **require** physical hardware.
