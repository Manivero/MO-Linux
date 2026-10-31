# config/system/ — system-wide configuration directory (Phase 0 stub)

Holds system-wide configuration: sysctl defaults, systemd unit overrides, locale list, NetworkManager defaults, etc. Phase 0 stub; first real configs land in Phase 1 / Phase 6.

## Files planned

- `sysctl/`          — sysctl defaults (per ADR-0006 §3: sysctl tuning before patches)
- `systemd/`         — systemd unit overrides and default target
- `locale.conf`      — list of supported locales (ru, en by default per §6 of Project Initiation v2)
- `networkmanager/`  — NetworkManager default config
- `pipewire/`        — PipeWire user-session defaults (Phase 6)

## Status

- **Planned.** No real config files yet.
