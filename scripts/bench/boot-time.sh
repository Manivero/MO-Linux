#!/bin/bash
# scripts/bench/boot-time.sh — boot-time measurement template.
#
# On a system that is already booted, this script CANNOT measure boot time
# directly. It documents the procedure to use and reads what `systemd-analyze`
# can tell us about the *current* boot, plus captures a snapshot of kernel
# messages from this boot.
#
# Per Project Initiation v2 §5: separate firmware/POST time from OS boot time.
#
# TCG caveat (req #9): results collected under QEMU TCG are NOT valid
# performance benchmarks — software emulation distorts timing. TCG is for
# functional boot verification only; benchmark numbers require KVM or real
# hardware. Mark TCG-collected output as "functional-only".

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/bench/results"
mkdir -p "$RESULTS_DIR"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$RESULTS_DIR/${TS}-boot-time.txt"

{
  echo "# Boot-time measurement (host snapshot + procedure)"
  echo "# Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# Host: $(uname -a)"
  echo ""
  echo "## systemd-analyze (current boot)"
  if command -v systemd-analyze >/dev/null 2>&1; then
    systemd-analyze 2>&1 || true
    echo ""
    echo "## systemd-analyze blame (top 20 by startup time)"
    systemd-analyze blame 2>&1 | head -25 || true
    echo ""
    echo "## systemd-analyze critical-chain"
    systemd-analyze critical-chain 2>&1 | head -40 || true
  else
    echo "systemd-analyze: not available (host is not a systemd host, or not installed)"
  fi
  echo ""
  echo "## dmesg from this boot (head + tail)"
  if [[ -r /dev/kmsg ]] || [[ -r /var/log/dmesg ]]; then
    dmesg 2>/dev/null | head -30 || true
    echo "..."
    dmesg 2>/dev/null | tail -30 || true
  else
    echo "(no access to kernel ring buffer — needs root or CAP_SYSLOG)"
  fi
  echo ""
  echo "## Procedure for target-system measurement (Phase 5)"
  echo ""
  echo "1. Power-cycle the target machine."
  echo "2. With a stopwatch, measure time from power-on to GRUB menu visible."
  echo "   This is the FIRMWARE time (POST + firmware init)."
  echo "3. Press Enter on the default GRUB entry; start a second stopwatch."
  echo "4. Measure time from GRUB handoff to login prompt."
  echo "   This is the OS BOOT time."
  echo "5. After login, log in and measure time to 'desktop ready' (panel appears,"
  echo "   no hourglass / spinner). This is the DESKTOP READY time."
  echo "6. Run \`systemd-analyze\` on the target to get the kernel+userspace breakdown."
  echo "7. Repeat 5 cold-boot cycles; report median and spread."
  echo ""
  echo "Output: bench/results/<date>-boot-time-<hostname>.txt with raw numbers"
  echo "        for each of the 5 runs."
} > "$OUT"

cat "$OUT"
echo ""
echo "Wrote: $OUT"
exit 0
