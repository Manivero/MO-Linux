# GPL_COMPLIANCE — обязательства, firmware-режим, процесс релиза

Статус: **Implemented** (спецификация; рекреирован 2026-10-31 после recycle песочницы).

## 1. Применимые лицензии

Дистрибутив распространяет:
- **Linux kernel** (GPL-2.0-only) — kernel image, modules, headers.
- **glibc** (LGPL-2.1+) — libc.
- **gcc runtime** (GPL-3.0+ with GCC Runtime Library Exception) — libgcc, libstdc++.
- **systemd** (LGPL-2.1+) — init system.
- **GRUB** (GPL-3.0+) — bootloader.
- **Xorg, Xfce** (GPL, LGPL, MIT, BSD — mixed) — desktop.
- **coreutils, binutils, bash, findutils, gzip, …** (GPL-3.0+) — base utils.

Большинство компонентов — GPL-family. **Source offer обязателен.**

## 2. Обязательства GPL

Per GPL-3.0 §6 (и аналогичные для GPL-2.0 §3):

1. **Convey binary with source** — при распространении бинарников нужно предоставить исходники.
2. **Written offer valid for 3 years** — если передаётся физический носитель (DVD, USB) — written offer действует 3 года для любого третьего лица.
3. **Individual commercial redistribution** — если дистрибутив коммерческий, для каждого downstream распространителя действует тот же offer.

## 3. Source offer — процесс

### 3.1 Что включать

Для каждого GPL-family пакета в релизе:
- Полный исходный tarball (тот, что использовался для сборки — с patches, если есть).
- Build instructions (ссылка на LFS 13.1 + наши scripts/).
- Build scripts (наши Makefile, config files).
- «Corresponding source» definition (GPL-3.0 §1): scripts, build configs, NOT general-purpose tools (gcc, make, binutils).

### 3.2 Как распространять

**Вариант A (online, default):**
- Website `https://distro.example.org/sources/<version>/` — все .tar.xz файлы.
- `sources.lock` манифест с SHA256 — checksum integrity.
- Online offer: «Written offer valid for 3 years» — на website, со ссылкой.

**Вариант B (offline, on request):**
- По запросу — DVD/USB с source tarballs (за стоимость носителя + пересылка).
- Request email: `sources-request@distro.example.org`.

**Вариант C (accompanying physical media):**
- Если релиз распространяется на DVD/USB — source DVD/USB прилагается (или written offer с URL).

### 3.3 Retention

- Sources для каждого релиза хранятся минимум 6 лет (3 года GPL + 3 года safety margin).
- После EOL релиза — архивируются и остаются доступными онлайн.

## 4. Firmware-режим

### 4.1 Linux firmware

- `linux-firmware` пакет (микрокоды для Wi-Fi, GPU, audio) — различные лицензии (многие non-free, но redistributable).
- Стратегия:
  - **Default:** включать `linux-firmware` в образ (как делает большинство дистрибутивов).
  - **Alternative (planned, опционально):** «free-only» образ без firmware; только для hardware, не требующего firmware (i915 работает без firmware для большинства старых Intel iGPU; HD 4000 в i5-3320M — без firmware).
- License manifest для firmware: `docs/FIRMWARE_LICENSES.md` (planned).

### 4.2 Binary blobs ядра

- Linux kernel включает несколько binary blobs (для некоторых Wi-Fi drivers).
- `CONFIG_FW_LOADER` + `linux-firmware` — стандартный путь.
- Deblobbed kernel (Debian/Linux-libre approach) — **не** для первого релиза (некоторые драйверы перестают работать).

## 5. License manifest

`docs/LICENSE_MANIFEST.md` (planned) — полный список:
- Package name
- Version
- License (SPDX identifier)
- Source URL
- Source SHA256
- Binary path in rootfs

Генерируется из `sources.lock` + `metadata.json` пакетов.

## 6. Тесты (Phase 10)

- `tests/gpl-source-offer.sh` (planned):
  - Для каждого GPL-family пакета в `LICENSE_MANIFEST.md`:
    - Source tarball существует на website/DVD.
    - SHA256 совпадает с manifest.
    - Build instructions доступны.
- `tests/license-scan.sh` (planned):
  - Сканирует все binaries в rootfs.
  - Для каждого: соответствующий source package в manifest.

## 7. Process checklist для релиза

- [ ] `sources.lock` обновлён для всех пакетов релиза.
- [ ] Все .tar.xz sources опубликованы (website + mirrors).
- [ ] `LICENSE_MANIFEST.md` готов.
- [ ] `FIRMWARE_LICENSES.md` готов (если firmware включён).
- [ ] `RELEASE_NOTES-<version>.md` готов.
- [ ] Written offer документ на website.
- [ ] Sources retention policy применена (6 лет).

## 8. Связанные документы

- `sources.lock` — манифест исходников.
- `RELEASE_POLICY.md` — каналы, версии, критерии.
- `PACKAGE_FORMAT.md` — metadata fields (license, source_url, source_sha256).
