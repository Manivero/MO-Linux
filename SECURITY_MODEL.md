# SECURITY_MODEL — границы доверия, угрозы, меры

Статус: **Implemented** (спецификация; рекреирован 2026-10-31 после recycle песочницы).

## 1. Границы доверия

```
┌─────────────────────────────────────────────────┐
│  Build VM (trusted)                              │
│  ├─ admin user (semi-trusted: apt-install, disk) │
│  ├─ lfs user (trusted for build, no sudo)        │
│  └─ /mnt/lfs workspace (trusted build output)   │
└─────────────────────────────────────────────────┘
              │ (signed sources, verified SHA256)
              ▼
┌─────────────────────────────────────────────────┐
│  Target system (QEMU / hardware)                 │
│  ├─ root (trusted within system)                 │
│  ├─ regular user (untrusted: browser, network)   │
│  └─ /home (user data — untrusted)                │
└─────────────────────────────────────────────────┘
              │ (signed updates, if A/B is approved)
              ▼
┌─────────────────────────────────────────────────┐
│  Update repository (trusted if signed)           │
│  └─ package metadata + payload (signed)          │
└─────────────────────────────────────────────────┘
```

## 2. Угрозы и меры

| # | Угроза | Вектор | Мера | Статус |
|---|---|---|---|---|
| SEC-1 | Compromised build VM | malware on host, supply-chain | VM isolation; lfs без sudo; sources SHA256 verified | Implemented |
| SEC-2 | Tampered sources | MITM on download | SHA256 verification against sources.lock; HTTPS | Planned (Phase 2 S2) |
| SEC-3 | Privilege escalation via build | malicious Makefile runs as root | Build от lfs (no sudo); lfs-safety.sh path checks | Implemented |
| SEC-4 | Arbitrary code in packages | postinst scripts with root | Hooks whitelist (PACKAGE_FORMAT.md §6); no arbitrary scripts | Planned (Phase 7) |
| SEC-5 | Unsigned updates | MITM on repo | Signed repository metadata; key rotation policy | Planned (Phase 8) |
| SEC-6 | Bootkit (MBR/EFI tampering) | physical access, malware | GRUB + (future) Secure Boot; MBR protection | Secure Boot deferred (ADR-0003) |
| SEC-7 | Kernel modules from untrusted source | rootkit | Module signing (future); restrict module loading | Phase 8 |
| SEC-8 | Data exfiltration via /home | malware | No automatic cloud sync; user-controlled | by design |
| SEC-9 | Side-channel (Spectre/Meltdown) | local exploit | Kernel mitigations (CONFIG_RETPOLINE etc.); not disabled | Implemented (kernel config) |
| SEC-10 | Brute-force SSH | network | sshd: AllowUsers, fail2ban (future), key-only auth (future) | Phase 6 |

## 3. CVE-процесс

| Шаг | Действие | Кто |
|---|---|---|
| 1 | Monitor NVD (https://nvd.nist.gov/) + kernel.org CVE feed | automated (future) / owner |
| 2 | Triage: critical (RCE, priv-esc) → patch immediately; high → next security-cadence; medium/low → batch | owner |
| 3 | Patch в kernel (если upstream fix available) + rebuild kernel | Phase 8 (update path) |
| 4 | Patch в userspace packages (glibc, systemd, openssl, browser) | Phase 8 |
| 5 | Release security update через package manager (signed) | Phase 8 |
| 6 | Document CVE ID + fix commit в `docs/CVE_HISTORY.md` (future) | owner |

Security-cadence: см. `RELEASE_POLICY.md` §4 — критические CVE немедленно, остальные monthly.

## 4. Cryptography

- **SHA256** для верификации исходников и пакетов.
- **Ed25519** (planned) для подписи repository metadata.
- **RSA-4096** (fallback, planned) для подписи если Ed25519 недоступен.
- Ключи хранятся offline; rotation — по графику (см. RELEASE_POLICY.md).

## 5. Безопасность build process

- `set -euo pipefail` во всех скриптах сборки.
- `$LFS` проверяется перед каждой критической операцией.
- `lfs-safety.sh` library: `lfs_safe_path`, `lfs_safe_rm`, `lfs_die`.
- Self-test: `bash scripts/lib/lfs-safety.sh --self-test` → OK (5/5).
- Запрещённые пути: `/`, `/usr`, `/boot`, `/etc`, `/var`, `/home`, `/lib*`, `/sbin`, `/bin`.
- Все операции с путями — через библиотеку; прямой `rm -rf` запрещён.

## 6. Связанные документы

- `ADR-0003` (GRUB + Secure Boot deferred) — Accepted.
- `ADR-0007` (package manager — signed metadata requirement) — Deferred.
- `ADR-0008` (A/B + signed updates) — Proposed.
- `PACKAGE_FORMAT.md` (hooks whitelist) — рекреирован.
- `RELEASE_POLICY.md` (security-cadence) — рекреирован.
- `scripts/lib/lfs-safety.sh` — библиотека безопасности.
