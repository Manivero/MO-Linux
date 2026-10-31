# RELEASE_POLICY — версии, каналы, критерии, security-cadence

Статус: **Implemented** (спецификация; рекреирован 2026-10-31 после recycle песочницы).

## 1. Версия дистрибутива

Формат: `<major>.<minor>.<patch>` (SemVer).

- **major** — breaking changes (новая схема обновлений, смена init, смена libc). Утверждается владельцем (§8).
- **minor** — новые features (новый профиль, новый DE component, новая утилита).
- **patch** — bugfixes, security fixes (без новых features).

Текущая target версия первого релиза: **1.0.0** (после Phase 10).

## 2. Каналы релизов

| Канал | Целевая аудитория | Стабильность | Cadence |
|---|---|---|---|
| `stable` | конечные пользователи | high | quarterly (3 месяца) + critical security out-of-band |
| `testing` | ранние пользователи | medium | monthly |
| `unstable` | разработчики | low | weekly (rolling) |

## 3. Критерии релиза

Для перехода `testing` → `stable`:
1. Все L4 (QEMU) тесты проходят на 3+ конфигурациях.
2. Все L5 (hardware) тесты проходят на i5-3320M (Legacy target).
3. Idle RAM ≤ budget (Legacy: <250 МБ desktop; Standard: <400 МБ).
4. Boot time ≤ budget (Legacy: <30 с на HDD; Standard: <15 с на SSD).
5. 30 циклов update/rollback без ручного вмешательства (Phase 8; если ADR-0008 утверждён).
6. CVE triage: нет open critical CVEs.
7. GPL_COMPLIANCE.md чек-лист пройден (source offer готов).
8. RELEASE_NOTES.md готов.
9. Signed metadata + signed image.

## 4. Security-cadence

| Severity | SLA | Канал |
|---|---|---|
| Critical (RCE, priv-esc, remote exploit) | 24 часа (commit); 72 часа (release) | out-of-band, все каналы |
| High (local exploit, DoS) | 1 неделя | next stable + immediate testing |
| Medium | 1 месяц | next stable |
| Low | 3 месяца | batch в next minor |

## 5. Подписи

- Repository metadata: Ed25519 (primary) или RSA-4096 (fallback).
- Package payload: SHA256 (in metadata) + metadata signature.
- Release image (ISO): SHA256 + detached signature.
- Ключи:
  - `release-key` — подписывает release images; offline storage.
  - `repo-key` — подписывает repository metadata; online (на update-сервере).
  - `package-key` — подписывает пакеты; CI-managed.
- Rotation: `release-key` — 2 года; `repo-key` — 1 год; `package-key` — 6 месяцев.
- Revocation: CRL на website + в repository metadata (signed).

## 6. End-of-Life (EOL) политика

- Каждый stable релиз: 2 года support (security + critical bugfixes) + 6 месяцев EOL-период (только critical security).
- После EOL: архив на website, подпись отозвана, users уведомлены.
- Major release: announce за 6 месяцев; migration guide.

## 7. Release notes

Каждый релиз включает:
- `RELEASE_NOTES-<version>.md` — changes, new features, breaking changes, migration.
- `CHANGELOG.md` — complete list of packages changed.
- `CVE_HISTORY.md` (future) — CVE IDs fixed in this release.
- `KNOWN_ISSUES.md` — known limitations.

## 8. Артефакты релиза

| Артефакт | Формат | Подпись |
|---|---|---|
| Live ISO | .iso (hybrid BIOS+UEFI) | SHA256 + .sig |
| Rootfs tarball | .tar.zst | SHA256 + .sig |
| Repository snapshot | .tar.zst | SHA256 + .sig |
| Release notes | .md | (unsigned, in repo) |
| Source offer | .tar.zst (GPL compliance) | SHA256 + .sig |

## 9. Связанные документы

- `GPL_COMPLIANCE.md` — GPL obligations, source offer process.
- `SECURITY_MODEL.md` — CVE-процесс, ключи.
- `PACKAGE_FORMAT.md` — подпись metadata + payload.
- `ADR-0008` (Proposed) — update/rollback scheme (зависит от утверждения).
