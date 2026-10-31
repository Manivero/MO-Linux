# bench/results/ — raw benchmark outputs

Raw benchmark outputs go here. Per `..gitignore`, files ending in `.raw`
are not tracked in git — keep summaries only.

## Naming convention

- `host-version-check-<UTC-timestamp>.txt` — from `scripts/host-version-check.sh`
- `<UTC-timestamp>-idle-ram.txt`           — from `scripts/bench/idle-ram.sh`
- `<UTC-timestamp>-boot-time.txt`          — from `scripts/bench/boot-time.sh`
- `<UTC-timestamp>-disk-io.txt`            — from `scripts/bench/disk-io.sh`
- `<date>-init-comparison/`                — Phase 5: init system comparison
- `<date>-reboot-stress/`                  — Phase 4/5: 50-reboot stress test
- `<date>-boot-time-<hostname>.txt`        — Phase 5: per-host boot time series

## Status

Files in this directory are **build artifacts**, not source. They are not
tracked by git individually (see top-level `.gitignore`). The directory
exists so scripts have a place to write.
