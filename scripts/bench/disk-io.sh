#!/bin/bash
# scripts/bench/disk-io.sh — quick disk I/O baseline.
#
# Uses fio if available (preferred, reproducible). Falls back to dd for hosts
# without fio, but the dd fallback is clearly marked as non-authoritative.
#
# Tests performed:
#   1. Sequential read (1 MB block, 1 GiB total) — single-thread
#   2. Sequential write (1 MB block, 1 GiB total) — single-thread
#   3. Random 4K read — QD1, 60s (fio only)
#   4. Random 4K write — QD1, 60s (fio only)
#
# Per Project Initiation v2 §11: each benchmark script must have fixed
# parameters and save raw output.
#
# TCG caveat (req #9): I/O numbers collected under QEMU TCG are NOT valid
# performance benchmarks — software emulation distorts throughput/latency.
# TCG is for functional boot verification only; benchmark numbers require
# KVM or real hardware. Mark TCG-collected output as "functional-only".

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/bench/results"
WORKDIR="$RESULTS_DIR/io-workdir"
mkdir -p "$WORKDIR"

TARGET="$WORKDIR"
RUNTIME=60
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)  TARGET="$2"; shift 2 ;;
    --runtime) RUNTIME="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--target <dir>] [--runtime <sec>]"
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

TARGET_CANON="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"
case "$TARGET_CANON" in
  "$PROJECT_ROOT"*) : ;;
  /tmp/*)              : ;;
  *) echo "Refusing to write benchmark data outside the project or /tmp: $TARGET_CANON" >&2; exit 2 ;;
esac
mkdir -p "$TARGET_CANON"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$RESULTS_DIR/${TS}-disk-io.txt"
TESTFILE="$TARGET_CANON/io-test.bin"

have_fio=0
# Verify the real fio (the disk I/O benchmark) — not a Python `fio` from a
# venv like 'fiona'. The real fio prints "fio-<version>" in --version output.
if command -v fio >/dev/null 2>&1; then
  fio_out="$(fio --version 2>&1 || true)"
  if echo "$fio_out" | grep -qi 'fio-'; then
    have_fio=1
  else
    echo "WARNING: 'fio' on PATH is not the disk I/O benchmark; output was:" >&2
    echo "$fio_out" | head -2 >&2
    echo "WARNING: falling back to dd (non-authoritative)." >&2
    have_fio=0
  fi
fi

{
  echo "# Disk I/O baseline"
  echo "# Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# Host: $(uname -a)"
  echo "# Target dir: $TARGET_CANON"
  echo "# fio available: $have_fio"
  echo "# Test file: $TESTFILE"
  echo ""
  echo "## Filesystem on target"
  df -hT "$TARGET_CANON" | head -5
  echo ""
  echo "## Block device info"
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL 2>/dev/null | head -20 || echo "lsblk unavailable"
} > "$OUT"

trap 'rm -f -- "$TESTFILE" 2>/dev/null || true' EXIT

if [[ $have_fio -eq 1 ]]; then
  {
    echo ""
    echo "## fio: sequential read (1 MB block, 1 GiB)"
    fio --name=seqread --rw=read --bs=1M --size=1G --numjobs=1 \
        --iodepth=1 --direct=1 --filename="$TESTFILE" \
        --output-format=text 2>&1 || echo "fio seqread failed"

    echo ""
    echo "## fio: sequential write (1 MB block, 1 GiB)"
    fio --name=seqwrite --rw=write --bs=1M --size=1G --numjobs=1 \
        --iodepth=1 --direct=0 --filename="$TESTFILE" \
        --output-format=text 2>&1 || echo "fio seqwrite failed"

    echo ""
    echo "## fio: random 4K read (QD1, ${RUNTIME}s)"
    fio --name=randread --rw=randread --bs=4K --size=1G --numjobs=1 \
        --iodepth=1 --direct=1 --filename="$TESTFILE" --time_based \
        --runtime="$RUNTIME" --output-format=text 2>&1 || echo "fio randread failed"

    echo ""
    echo "## fio: random 4K write (QD1, ${RUNTIME}s)"
    fio --name=randwrite --rw=randwrite --bs=4K --size=1G --numjobs=1 \
        --iodepth=1 --direct=0 --filename="$TESTFILE" --time_based \
        --runtime="$RUNTIME" --output-format=text 2>&1 || echo "fio randwrite failed"
  } >> "$OUT"
else
  {
    echo ""
    echo "## fio not available — falling back to dd (NON-AUTHORITATIVE)"
    echo ""
    echo "### dd sequential write (1 MiB block, 1 GiB)  — must run first"
    dd if=/dev/zero of="$TESTFILE" bs=1M count=1024 conv=fdatasync status=progress 2>&1 || \
      dd if=/dev/zero of="$TESTFILE" bs=1M count=1024 conv=fdatasync 2>&1
    echo ""
    echo "### dd sequential read (1 MiB block, 1 GiB)"
    sync
    dd if="$TESTFILE" of=/dev/null bs=1M count=1024 status=progress 2>&1 || \
      dd if="$TESTFILE" of=/dev/null bs=1M count=1024 2>&1
    echo ""
    echo "## NOTE: dd numbers include buffer-cache effects and are NOT comparable"
    echo "##       to fio direct=1 numbers. Install fio for authoritative measurements."
  } >> "$OUT"
fi

cat "$OUT"
echo ""
echo "Wrote: $OUT"
exit 0
