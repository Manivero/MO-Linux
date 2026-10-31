# BOOT_AND_RECOVERY — цепочка загрузки и восстановление

Статус: **Implemented** (спецификация; рекреирован 2026-10-31 после recycle песочницы).
Связанные решения: ADR-0003 (GRUB, Accepted), ADR-0008 (A/B, Proposed — layout ниже активируется только после его утверждения; Phase 2 использует **базовую разметку без A/B**).

## 1. Цепочка загрузки (детально)

```
питание
 → прошивка (BIOS: POST+MBR; UEFI: SEC→PEI→DXE→BDS, выбор загрузочной записи)
   → BIOS: GRUB stage1 (MBR) → core.img → /boot/grub/
     UEFI: ESP/EFI/BOOT/BOOTX64.EFI (grubx64.efi) → /boot/grub/grub.cfg
       → GRUB menu / grubenv (default, next_entry)
         → загрузка ядра: /boot/vmlinuz-<ver> + initramfs (Phase 3.5)
           → ядро: инициализация, монтирование root=UUID=<root-uuid> ro
             → systemd (PID 1), default target:
                 core-профиль  → multi-user.target → getty
                 desktop-профиль → graphical.target → lightdm → Xorg+Xfce
```

Разделение времени загрузки (измерение Phase 5):
- **firmware time**: питание → появление меню GRUB (секомер);
- **OS boot time**: GRUB → prompt логина (`systemd-analyze`);
- **desktop ready**: логин → панель Xfce без спиннера.

## 2. Разметка диска

### 2.1 Базовая разметка (Phase 2 — без A/B; используется в S6)

| Раздел | Размер | ФС | Назначение |
|---|---|---|---|
| p1 | 2–4 ГБ | ext4 | root (единый) |
| p2 | 1 ГБ | ext4 | /boot |
| p3 | 2–4 ГБ | swap | suspend-to-disk |
| p4 | rest | ext4 | /home |
| ESP (UEFI) | 512 МБ | FAT32 | grubx64.efi |

Используется в Phase 2 (S6): один root, без A/B. ADR-0008 не утверждён — A/B-layout не применяется.

### 2.2 A/B-layout (активируется только после утверждения ADR-0008; НЕ для Phase 2)

| Раздел | Размер | ФС | Назначение |
|---|---|---|---|
| ESP (UEFI) | 512 МБ | FAT32 | только EFI-бинарники GRUB |
| /boot | 1 ГБ | ext4 | ядра ОБЕИХ слотов + grubenv (общий) |
| rootA | 12 ГБ | ext4 | слот A |
| rootB | 12 ГБ | ext4 | слот B |
| swap | 2–4 ГБ | swap | общий |
| /home | rest | ext4 | общий |

Ядра именуются с суффиксом слота: `vmlinuz-6.18.x-<ts>-A`, `...-B`; запись в GRUB — по одному menuentry на слот. **Реализация A/B запрещена до утверждения ADR-0008.**

## 3. Конфигурация GRUB

- `GRUB_DEFAULT=saved` + управление через `grub-editenv`/`grub-reboot`/`grub-set-default`.
- Таймаут меню: 3 с (desktop), 1 с (core), показ по удержанию Shift/Esc.
- Serial console включается для QEMU-тестов (`console=ttyS0`), на железе — по умолчанию нет.
- `grub.cfg` обновляется только атомарно: запись во временный файл + `rename`.
- Всегда присутствует menuentry «Recovery mode» — загрузка в `systemd.unit=rescue.target`.

## 4. Initramfs (Phase 3.5 — пока stub в Phase 2)

- **Phase 2:** минимальный initramfs (busybox + modules для ext4 и virtio + /init). Без модульного подхода — для упрощения.
- **Phase 3.5:** initramfs с модульными драйверами (dracut или собственный генератор — решение в Phase 3 по результатам оценки размера).
- A/B-активация (если будет утверждена): initramfs резолвит `root=` по grubenv (`slot=A|B`).

## 5. Цели systemd

| Профиль | Default target | Состав |
|---|---|---|
| `core` | `multi-user.target` | CLI-система, getty, NetworkManager |
| `desktop` | `graphical.target` | + lightdm → Xorg → Xfce session |

Переключение профиля — пакетной установкой мета-пакета профиля.

## 6. Recovery

### 6.1 Не грузится новый слот/ядро (только после утверждения A/B)
1. GRUB-меню (Esc при загрузке) → выбор предыдущей записи → загрузка старого.
2. Если сломан grubenv: `grub-editenv /boot/grub/grubenv set default=<старый entry>` из любого живого слота или live ISO.

### 6.2 Не грузится GRUB
1. Live ISO (Phase 9) → mount корня и /boot → `grub-install --boot-directory=...` заново.
2. BIOS-путь: `grub rescue>`: `set prefix=(hd0,2)/grub; insmod normal; normal`.

### 6.3 Повреждение root-ФС
1. `fsck.ext4 -y /dev/<root>` из live ISO (ext4 metadata_csum укажет повреждения).
2. A/B (если утверждён): один слот умер → второй остаётся загрузочным; переустановка мёртвого слота.

### 6.4 Recovery-окружение
Phase 9: пункт «Recovery» в GRUB → загрузка того же ядра с `systemd.unit=rescue.target` (root пароль обязателен); плюс live ISO с установщиком в режиме ремонта (fsck, chroot, переустановка GRUB).

## 7. Тестирование загрузки

| Тест | Среда | Фаза | Скрипт |
|---|---|---|---|
| BIOS boot to login | QEMU (SeaBIOS) | Phase 2 (S7) | `tests/qemu-boot.sh --bios` |
| UEFI boot to login | QEMU (OVMF) | Phase 3 | `tests/qemu-boot.sh --uefi` |
| Чистые shutdown/reboot | QEMU | Phase 3 | `tests/qemu-shutdown.sh` |
| Serial console | QEMU | Phase 2 | `tests/qemu-boot.sh --serial` |
| 50 reboot cycles (HW) | железо | Phase 4/5 | HW-21 из docs/HARDWARE_TEST_PLAN.md |
| A/B: commit нового слота | QEMU | Phase 8 (если ADR-0008 утверждён) | `tests/ab-commit.sh` |
| A/B: fallback при сломанном health check | QEMU | Phase 8 (если ADR-0008 утверждён) | `tests/ab-fallback.sh` |

## 8. Открытые вопросы

- Дисплей-менеджер: lightdm (предложение, ~меньше RAM чем SDDM) — подтверждение в Phase 6 измерением.
- Splash (plymouth) — вероятно, нет: приоритет скорости загрузки (§2 #5); пересмотр по желанию владельца.
