# PACKAGE_FORMAT — формат пакетов .lpkg

Статус: **Implemented** (спецификация; рекреирован 2026-10-31 после recycle песочницы).
Зависит от **ADR-0007 (Deferred)** — фактический выбор менеджера пакетов в Phase 7. Формат .lpkg — проектная спецификация, может быть пересмотрен при выборе существующего менеджера (apk, dpkg, pacman).

## 1. Требования к формату

1. **Атомарная установка** — staging во временный каталог + atomic rename; не оставляет полусостояний.
2. **Поддержка `--root`** — обязательна (ADR-0007 требование №10; для A/B-install в неактивный слот).
3. **Signed metadata** — package metadata подписаны; payload верифицируется по SHA256.
4. **Hooks whitelist** — только декларативные hooks (update-mime-database, gtk-update-icon-cache и т.п.); произвольные скрипты запрещены.
5. **Reproducibility** — `SOURCE_DATE_EPOCH` + pinned build flags; rebuild → bit-identical.
6. **Small footprint** — metadata в JSON/SQLite; payload в tar.zst.

## 2. Структура .lpkg

```
package-name-1.2.3-x86_64.lpkg
├── metadata.json         # JSON: name, version, deps, conflicts, license, source_url, sha256
├── payload.tar.zst        # файлы пакета
├── hooks.list             # whitelist of hooks to run (декларативно)
└── signature.sig          # Ed25519 signature over (metadata.json + payload.sha256)
```

### 2.1 metadata.json schema

```json
{
  "name": "bash",
  "version": "5.2.32",
  "release": "1",
  "architecture": "x86_64",
  "description": "GNU Bourne Again SHell",
  "license": "GPL-3.0-or-later",
  "source_url": "https://ftp.gnu.org/gnu/bash/bash-5.2.32.tar.gz",
  "source_sha256": "...",
  "depends": ["glibc>=2.44", "ncurses>=6.5"],
  "conflicts": [],
  "provides": ["shell"],
  "installed_size": 12345678,
  "payload_sha256": "...",
  "build_epoch": 1735689600,
  "build_flags": "-O2 -pipe -march=x86-64"
}
```

### 2.2 hooks.list

```
# Whitelisted hooks for this package
update-mime-database
gtk-update-icon-cache
update-desktop-database
# (произвольные скрипты запрещены; только стандартные декларативные операции)
```

## 3. Установка

```bash
pkg install --root /mnt/slotB bash-5.2.32-x86_64.lpkg
# 1. Verify signature.sig against repository key
# 2. Verify payload_sha256 against metadata
# 3. Stage: extract payload.tar.zst → /mnt/slotB/.staging/bash-5.2.32/
# 4. Pre-install hooks (whitelist)
# 5. Atomic rename: staging → final paths (rename(2) per file)
# 6. Update package DB: /mnt/slotB/var/lib/pkg/db (atomic: db.tmp + rename)
# 7. Post-install hooks (whitelist)
# 8. Done — atomic; on failure: rollback staging, db unchanged
```

## 4. Атомарность

| Операция | Механизм |
|---|---|
| Staging | extract во временный каталог `.staging/<pkg>/` |
| Atomic install | `rename(2)` per file (atomic per-file); в крайнем случае — `linkat`+`unlink` |
| Package DB | `db.tmp` + `rename` (atomic) |
| Hooks | декларативный whitelist; сбой hook → rollback всей установки |
| Initramfs regeneration | отдельный шаг (не внутри пакета); state machine в `slotmgr` |

## 5. Зависимости

- Format: `name[>=version]` (например, `glibc>=2.44`).
- Resolver: SAT-class (planned) или topological (fallback).
- Cycle detection: required; цикл → отказ установки с диагностикой.
- Conflicts: явные; `conflicts: ["old-package"]`.

## 6. Hooks whitelist

| Hook | Что делает | Разрешён |
|---|---|---|
| `update-mime-database` | обновляет /usr/share/mime/database | ✅ |
| `gtk-update-icon-cache` | кэш иконок GTK | ✅ |
| `update-desktop-database` | обновляет .desktop | ✅ |
| `glib-compile-schemas` | GSettings schemas | ✅ |
| `update-mime-database` | MIME types | ✅ |
| `fontconfig-cache-update` | шрифты | ✅ |
| `mkinitramfs-trigger` | помечает initramfs для регенерации (не запускает!) | ✅ |
| **произвольные скрипты** | — | ❌ запрещены |

## 7. Мета-пакеты профилей

| Мета-пакет | Зависимости | Профиль |
|---|---|---|
| `meta-core` | systemd, glibc, coreutils, util-linux, iproute2, bash | core |
| `meta-desktop` | meta-core + Xorg + Xfce + lightdm + PipeWire + NetworkManager | desktop |
| `meta-extended` | meta-desktop + bluetooth + extra apps | extended |

## 8. БД пакетов

- Path: `/var/lib/pkg/db` (в каждом слоте отдельно, если A/B утверждён).
- Format: SQLite (planned) или JSON (fallback).
- Schema: name, version, installed_files[], install_time, build_epoch.
- Backup: db.bak перед каждой транзакцией; db.tmp + rename.

## 9. Воспроизводимость

- `SOURCE_DATE_EPOCH` в metadata.
- Build flags pinned: `CFLAGS="-O2 -pipe -march=x86-64"`, `CXXFLAGS="${CFLAGS}"`, `LDFLAGS=""`.
- `-march=native` **запрещён** для релизов (ADR-0006 §kernel policy).
- Rebuild test: `pkg rebuild bash-5.2.32` → diff payload_sha256 == 0 (или documented acceptable diffs).

## 10. Связанные документы

- `ADR-0007` (package manager — Deferred) — кандидаты: Rust/C from-scratch, apk, opkg, dpkg+apt, pacman, dnf/rpm.
- `ADR-0008` (A/B — `--root` requirement) — Proposed.
- `SECURITY_MODEL.md` §4 — signed metadata.
- `RELEASE_POLICY.md` — release channels и подписи.
