# SYSTEM_SERVICES — инвентаризация системных служб по профилям

Статус: **Implemented** (спецификация; рекреирован 2026-10-31 после recycle песочницы).
Оценки RAM — гипотезы; заменяются измерениями Phase 5.

## 1. Профили

| Профиль | RAM target (idle) | Default target | Use case |
|---|---|---|---|
| `core` | <80 МБ | multi-user.target | CLI-only система, сервер, разработка |
| `desktop` | <250 МБ | graphical.target | Xfce-десктоп, Legacy-ноутбук |
| `extended` | <400 МБ | graphical.target | modern hardware headroom |

## 2. Состав служб по профилям

| Служба | core | desktop | extended | RAM (оценка) | Причина |
|---|---|---|---|---|---|
| systemd-journald | ✅ | ✅ | ✅ | ~5 МБ | журналирование (§2 #6) |
| systemd-udevd | ✅ | ✅ | ✅ | ~3 МБ | device events |
| dbus | ✅ | ✅ | ✅ | ~3 МБ | IPC |
| systemd-logind | ✅ | ✅ | ✅ | ~2 МБ | session management |
| systemd-networkd | ✅ | ✅ | ✅ | ~2 МБ | сеть (легче NetworkManager) |
| systemd-resolved | ✅ | ✅ | ✅ | ~2 МБ | DNS |
| cron (cronie) | ✅ | ✅ | ✅ | ~1 МБ | периодические задачи |
| agetty (×2) | ✅ | ✅ | ✅ | ~1 МБ | TTY |
| **core subtotal** | — | — | — | **~19 МБ** | |
| NetworkManager | ❌ | ✅ (опц.) | ✅ | ~10 МБ | Wi-Fi (если NM лучше для Wi-Fi; systemd-networkd для ethernet) |
| polkitd | ❌ | ✅ | ✅ | ~2 МБ | policykit для graphical |
| rtkit-daemon | ❌ | ✅ | ✅ | ~1 МБ | realtime priorities для audio |
| lightdm | ❌ | ✅ | ✅ | ~10 МБ | display manager (легче SDDM) |
| Xorg | ❌ | ✅ | ✅ | ~30–50 МБ | X server (legacy i915) |
| xfce4-session | ❌ | ✅ | ✅ | ~20 МБ | DE session |
| xfwm4 | ❌ | ✅ | ✅ | ~10 МБ | window manager |
| xfce4-panel | ❌ | ✅ | ✅ | ~10 МБ | панель задач |
| **desktop subtotal** | — | — | — | **+~95 МБ** | |
| PipeWire | ❌ | ✅ | ✅ | ~5 МБ | audio (легче PulseAudio) |
| wireplumber | ❌ | ✅ | ✅ | ~3 МБ | PipeWire session manager |
| BlueZ (bluetoothd) | ❌ | опц. | ✅ | ~5 МБ | BT — только если BT-чип есть |
| **extended subtotal** | — | — | — | **+~13 МБ** | |
| **ИТОГО (idle, оценка)** | **~19 МБ** | **~127 МБ** | **~140 МБ** | | |

Реальные числа — Phase 5 (`scripts/bench/idle-ram.sh`).

## 3. Службы, явно отключаемые на Legacy

| Служба | Почему отключить |
|---|---|
| NetworkManager-wait-online.service | блокирует boot на 30+ секунд |
| systemd-boot-update.service | не нужно (нет boot-counter) |
| apt-daily.timer, apt-daily-upgrade.timer | это Debian-специфика; у нас LFS |
| ModemManager | нет модема на Legacy-ноутбуке |
| accounts-daemon | графическое управление пользователями; не нужно |
| avahi-daemon | mDNS — отключить если нет нужды |
| cups | печать — отключить если нет принтера |

## 4. Конфигурация systemd для Legacy

- `systemd.default_timeout_start_sec=30` (вместо 90) — быстрее fail при проблемах.
- `systemd.loglevel=notice` — меньше шума в журнале.
- `journald SystemMaxUse=50M` — ограничение журнала на маленьких дисках.
- `systemd-resolved` — на Legacy можно отключить и использовать `/etc/resolv.conf` напрямую.

## 5. Связанные документы

- `ARCHITECTURE.md` — слоистая схема, dependency direction.
- `ADR-0001` (systemd), `ADR-0004` (Xfce) — Accepted.
- `scripts/bench/idle-ram.sh` — измерение idle RAM (Phase 5).
