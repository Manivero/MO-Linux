#!/bin/bash
# scripts/bench/idle-ram.sh — measure idle RAM.
#
# Captures several views of memory state:
#   - /proc/meminfo (full breakdown)
#   - free -h and free -b (human and bytes)
#   - smem if available (per-process PSS, top 30 by PSS)
#   - ps top 30 by RSS
#
# Records hardware + kernel version for context. Per §5 of Project Initiation
# v2 we separate MemAvailable from RSS/PSS and from cache.
#
# TCG caveat (req #9): RAM figures collected under QEMU TCG are NOT valid
# performance benchmarks — software emulation changes memory layout/behavior.
# TCG is for functional boot verification only; benchmark numbers require
# KVM or real hardware. Mark TCG-collected output as "functional-only".

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/bench/results"
mkdir -p "$RESULTS_DIR"

SETTLE=10
while [[ $# -gt 0 ]]; do
  case "$1" in
    --settle) SETTLE="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--settle <seconds>]"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$RESULTS_DIR/${TS}-idle-ram.txt"

{
  echo "# Idle RAM measurement"
  echo "# Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# Settle: ${SETTLE}s (idle before measurement)"
  echo "# Host: $(uname -a)"
  echo "# CPU:  $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
  echo "# Cores: $(nproc 2>/dev/null || echo '?')"
  echo "# Total RAM (kB): $(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
  echo ""
  echo "## Settling for ${SETTLE}s ..."
} > "$OUT"

sleep "$SETTLE"

{
  echo ""
  echo "## /proc/meminfo"
  cat /proc/meminfo
  echo ""
  echo "## free -b (bytes)"
  free -b
  echo ""
  echo "## free -h (human)"
  free -h
  echo ""
  if command -v smem >/dev/null 2>&1; then
    echo "## smem top 30 by PSS"
    smem -t -k -s pss -r 2>/dev/null | head -35 || echo "smem failed"
  else
    echo "## smem: not installed (skipped)"
  fi
  echo ""
  echo "## ps top 30 by RSS (kB)"
  ps -eo pid,user,rss,comm --sort=-rss | head -31
  echo ""
  echo "## systemd services memory (where systemd is PID 1)"
  if [[ "$(ps -p 1 -o comm= 2>/dev/null | tr -d ' ')" == "systemd" ]]; then
    systemd-cgtop -b -n 1 --order=memory 2>/dev/null | head -20 || echo "systemd-cgtop failed"
  else
    echo "systemd is not PID 1 on this host ($(ps -p 1 -o comm= 2>/dev/null | tr -d ' ')); skipped"
  fi
} >> "$OUT"

echo "" >> "$OUT"
echo "## Summary numbers" >> "$OUT"
MEM_TOTAL=$(awk '/^MemTotal:/     {print $2}' /proc/meminfo)
MEM_AVAIL=$(awk '/^MemAvailable:/  {print $2}' /proc/meminfo)
MEM_FREE=$(awk  '/^MemFree:/      {print $2}' /proc/meminfo)
CACHED=$(awk    '/^Cached:/       {print $2}' /proc/meminfo)
BUFFERS=$(awk   '/^Buffers:/      {print $2}' /proc/meminfo)
{
  printf "%-20s %12s\n" "MemTotal"     "$MEM_TOTAL"
  printf "%-20s %12s\n" "MemAvailable" "$MEM_AVAIL"
  printf "%-20s %12s\n" "MemFree"      "$MEM_FREE"
  printf "%-20s %12s\n" "Cached"       "$CACHED"
  printf "%-20s %12s\n" "Buffers"      "$BUFFERS"
  echo ""
  echo "All values in kB. Per Project Initiation v2 §5: MemAvailable, RSS/PSS, and cache are reported separately."
} >> "$OUT"

cat "$OUT"
echo ""
echo "Wrote: $OUT"
exit 0
