# ADR-0004 — Desktop environment / display stack

- **Status:** Proposed (pending owner approval)
- **Date:** 2026-10-30
- **Phase origin:** Phase 0
- **Decision owner:** Project owner (§8 — affects product UX)
- **Confidence:** Hypothesis — measured revisit in Phase 5

## Context

§6 of Project Initiation v2 requires «Xfce/Xorg vs LXQt vs Wayland-композиторы — RAM, старые GPU, поддержка NVIDIA legacy». The kit pre-selects Xorg + Xfce. This ADR confirms the choice against the criteria and sets the revisit triggers.

The §2 priorities here favor **UX (§2 #6)** and **hardware compatibility (§2 #4)** — old Intel/AMD GPUs work best with Xorg + modesetting or classic DDX drivers, and Xfce is the lightest mainstream desktop that still has full power-management, network, and audio applets.

## Options considered

| Option | Idle RAM (typical) | Legacy GPU support | NVIDIA legacy | Touchpad / gestures | Power applets | Network applet | Audio applet |
|---|---|---|---|---|---|---|---|
| **Xorg + Xfce** | 200–350 MB | excellent (modesetting, intel, amdgpu, radeon, nouveau) | partial (nouveau + legacy 340/304 driver cases) | libinput | xfce4-power-manager | nm-applet | pavucontrol |
| **Xorg + LXQt** | 150–250 MB | excellent | partial | libinput | lxqt-powermanagement | nm-tray | pavucontrol |
| **Wayland (Sway)** | 100–200 MB | partial — many legacy GPUs lack working DRM-KMS for wlroots | weak — nouveau Wayland is unstable | sway-input | sway-config | nmtui / waybar | pactl |
| **Wayland (GNOME/KDE)** | 600 MB+ | partial | partial | first-class | first-class | first-class | first-class |

## Decision

Adopt **Xorg + Xfce** as the primary desktop profile. Wayland is a **later optional profile** — explicitly not a first-release goal. LXQt is **not** chosen for the first release, but a revisit is open if Phase 5 measurement shows Xfce idle RSS > 250 MB on the Legacy 2 GB target.

Pin versions (verified 2026-10-30 against LFS/BLFS 13.1-systemd package lists):
- Xorg server: version provided by BLFS 13.1-systemd
- Xfce: version provided by BLFS 13.1-systemd

(Exact versions to be pinned in `sources.lock` at Phase 6 entry; deferred to avoid bloating the Phase 0 lock manifest with desktop packages.)

## Rationale

1. UX (§2 #6): Xfce provides a familiar, task-oriented desktop with panels, file manager, terminal, settings GUI — no terminal expertise needed for basic tasks.
2. Hardware compatibility (§2 #4): Xorg + modesetting + classic DDX drivers covers the widest set of legacy Intel/AMD GPUs. Wayland on legacy GPUs is hit-or-miss for KMS support.
3. Module modularity (§2 #7): Xfce components are individually replaceable — we can ship without the panel, with a different terminal, etc.
4. NVIDIA legacy support: documented as a separate case; not a blocker.
5. Wayland has known regressions on legacy GPUs and lacks good power-management integration on most compositors. Not first-release material.

## Consequences

- Positive: broadest hardware support; predictable; modular; well-documented upstream.
- Negative: X11 has known security limitations (any client can grab global input); mitigated by running X server as the logged-in user only.
- Risks: Wayland evangelists may push to switch earlier — we resist until Phase 5 evidence supports the switch on at least the Standard profile.

## Revisit triggers

- Phase 5 measurement shows Xfce idle RSS > 250 MB on Legacy 2 GB → consider LXQt or a window-manager-only `legacy` profile.
- A target GPU's modesetting-on-Xorg path is broken in our pinned kernel, with no Wayland-equivalent path either → that GPU is documented as unsupported, not the desktop swapped out.
- A user-visible power-management regression that Xfce cannot handle but Wayland can.

## Verification plan

- **Verified (build):** Xorg + Xfce built from BLFS 13.1-systemd instructions (Phase 6).
- **Verified (QEMU):** QEMU with `-display gtk` boots to Xfce login (Phase 6).
- **Verified (hardware):** on at least one Legacy target with Intel iGPU and one with AMD iGPU (Phase 6).
