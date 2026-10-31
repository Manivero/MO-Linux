#!/bin/bash
# scripts/host-version-check.sh — LFS host version checker.
#
# Mirrors the LFS "version-check.sh" script (LFS 13.1-systemd chapter 2).
# READ-ONLY. Does not install anything, does not write outside its own log.
#
# Usage:
#   bash scripts/host-version-check.sh
#   bash scripts/host-version-check.sh --json
#
# Exit codes:
#   0  all required tools present and meet minimum versions
#   1  at least one required tool missing or below minimum
#   2  script invoked incorrectly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="${PROJECT_ROOT}/bench/results"
mkdir -p "$RESULTS_DIR"

# ----------------------------------------------------------------------------
# Required tool list (LFS 13.1-systemd host requirements chapter).
# ----------------------------------------------------------------------------
LFS_HOST_REQUIREMENTS=(
  "bash|3.2"
  "binutils|2.13.1"
  "bison|2.7"
  "bzip2|1.0.8"
  "coreutils|8.1"
  "diffutils|2.8.1"
  "findutils|4.2.31"
  "gawk|4.0.1"
  "gcc|5.4"
  "grep|2.5.1a"
  "gzip|1.3.12"
  "m4|1.4.10"
  "make|4.0"
  "patch|2.5.4"
  "perl|5.8.8"
  "python3|3.4"
  "sed|4.1.5"
  "tar|1.22"
  "texinfo|5.0"
  "xz|5.0.0"
)

# Extra tools we will need in later phases. 'fio' is checked specially —
# the Python package 'fiona' installs a `fio` CLI that is NOT the disk I/O
# benchmark, so we verify by --version output.
EXTRA_TOOLS=(shellcheck qemu-system-x86_64 ccache ninja meson rustc cargo git curl wget openssl)

check_extra() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "MISSING"
    return
  fi
  echo "present"
}

check_fio() {
  if ! command -v fio >/dev/null 2>&1; then
    echo "MISSING"
    return
  fi
  # Real fio prints "fio-<version>" in --version output.
  # Use `|| true` to avoid SIGPIPE-with-pipefail killing the script if the
  # fio CLI is verbose (e.g. fiona prints many Python deprecation warnings).
  local fio_out
  fio_out="$(fio --version 2>&1 || true)"
  if echo "$fio_out" | grep -qi 'fio-'; then
    local ver
    ver="$(echo "$fio_out" | grep -oE 'fio-[0-9.]+' | head -1 | cut -d- -f2)"
    echo "present (fio-${ver})"
  else
    echo "WRONG (a different 'fio' on PATH, e.g. fiona)"
  fi
}

# ----------------------------------------------------------------------------
# Utility: version comparison.
# ----------------------------------------------------------------------------
ver_ge() {
  local a="$1" b="$2"
  a="$(echo "$a" | grep -oE '^[0-9]+(\.[0-9]+)*' || echo 0)"
  b="$(echo "$b" | grep -oE '^[0-9]+(\.[0-9]+)*' || echo 0)"
  if [[ "$a" == "$b" ]]; then return 0; fi
  local IFS=.
  local i a_arr=($a) b_arr=($b)
  for ((i=0; i<${#a_arr[@]} || i<${#b_arr[@]}; i++)); do
    local av=${a_arr[i]:-0}
    local bv=${b_arr[i]:-0}
    if (( av > bv )); then return 0; fi
    if (( av < bv )); then return 1; fi
  done
  return 0
}

# ----------------------------------------------------------------------------
# Get version of a tool.
# ----------------------------------------------------------------------------
get_version() {
  local tool="$1"
  local out
  # Map package names to representative commands for `command -v` / `--version`.
  case "$tool" in
    binutils)   tool=ld ;;
    coreutils)  tool=ls ;;
    diffutils)  tool=diff ;;
    findutils)  tool=find ;;
  esac
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "MISSING"
    return
  fi
  case "$tool" in
    bash)     out="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}" ;;
    python3)  out="$("$tool" -c 'import sys;print("%d.%d.%d"%sys.version_info[:3])' 2>/dev/null || echo UNKNOWN)" ;;
    bzip2)    out="$("$tool" --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" ;;
    gcc|g++)  out="$("$tool" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" ;;
    binutils|ld|ar)
              out="$("$tool" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)" ;;
    perl)     out="$("$tool" -e 'print $]' 2>/dev/null | grep -oE '[0-9]+\.[0-9]+')" ;;
    *)        out="$("$tool" --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)" ;;
  esac
  if [[ -z "$out" ]]; then
    out="UNKNOWN"
  fi
  echo "$out"
}

# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
OUTPUT_JSON=0
[[ "${1:-}" == "--json" ]] && OUTPUT_JSON=1

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_FILE="$RESULTS_DIR/host-version-check-${TS}.txt"

{
  echo "# LFS host version check"
  echo "# Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# Host: $(uname -a)"
  echo "# Project root: $PROJECT_ROOT"
  echo ""
  echo "## LFS 13.1-systemd host requirements"
  echo ""
  printf "%-12s %-12s %-12s %-10s\n" "TOOL" "REQUIRED" "INSTALLED" "STATUS"
  printf "%-12s %-12s %-12s %-10s\n" "----" "--------" "---------" "------"
} > "$OUT_FILE"

fail_count=0
missing_count=0
results=()

for entry in "${LFS_HOST_REQUIREMENTS[@]}"; do
  tool="${entry%%|*}"
  required="${entry##*|}"
  installed="$(get_version "$tool")"
  if [[ "$installed" == "MISSING" ]]; then
    status="MISSING"
    missing_count=$((missing_count+1))
    fail_count=$((fail_count+1))
  elif [[ "$installed" == "UNKNOWN" ]]; then
    status="UNKNOWN"
    fail_count=$((fail_count+1))
  elif ver_ge "$installed" "$required"; then
    status="OK"
  else
    status="TOO_OLD"
    fail_count=$((fail_count+1))
  fi
  printf "%-12s %-12s %-12s %-10s\n" "$tool" "$required" "$installed" "$status" >> "$OUT_FILE"
  results+=("{\"tool\":\"$tool\",\"required\":\"$required\",\"installed\":\"$installed\",\"status\":\"$status\"}")
done

echo "" >> "$OUT_FILE"
echo "## Additional tools we will need in later phases" >> "$OUT_FILE"
echo "" >> "$OUT_FILE"
printf "%-22s %-12s\n" "TOOL" "STATUS" >> "$OUT_FILE"
printf "%-22s %-12s\n" "----" "------" >> "$OUT_FILE"
extra_results=()
for tool in "${EXTRA_TOOLS[@]}"; do
  status="$(check_extra "$tool")"
  printf "%-22s %-12s\n" "$tool" "$status" >> "$OUT_FILE"
  extra_results+=("{\"tool\":\"$tool\",\"status\":\"$status\"}")
done
# Special-case fio.
status="$(check_fio)"
printf "%-22s %-12s\n" "fio (disk bench)" "$status" >> "$OUT_FILE"
extra_results+=("{\"tool\":\"fio (disk bench)\",\"status\":\"$status\"}")

echo "" >> "$OUT_FILE"
echo "## Summary" >> "$OUT_FILE"
echo "LFS-required failures: $fail_count" >> "$OUT_FILE"
echo "LFS-required missing: $missing_count" >> "$OUT_FILE"

if [[ $OUTPUT_JSON -eq 1 ]]; then
  printf '{"timestamp":"%s","host":"%s","lfs_requirements":[' "$TS" "$(uname -sr)" >> "$OUT_FILE.json"
  printf '%s' "$(IFS=,; echo "${results[*]}")" >> "$OUT_FILE.json"
  printf '],"extra_tools":[' >> "$OUT_FILE.json"
  printf '%s' "$(IFS=,; echo "${extra_results[*]}")" >> "$OUT_FILE.json"
  printf '],"failures":%d,"missing":%d}\n' "$fail_count" "$missing_count" >> "$OUT_FILE.json"
  cat "$OUT_FILE.json"
else
  cat "$OUT_FILE"
fi

echo ""
echo "Wrote: $OUT_FILE"
[[ $OUTPUT_JSON -eq 1 ]] && echo "Wrote: $OUT_FILE.json"

if (( fail_count > 0 )); then
  exit 1
fi
exit 0
