#!/bin/bash
# scripts/lib/lfs-safety.sh — shared safety helpers for LFS-related scripts.
#
# Sourced (not executed). Provides:
#   - lfs_assert_var_set   : assert that $LFS is set, non-empty, non-/, non-relative.
#   - lfs_assert_mounted    : assert that $LFS is mounted (or fall back to directory mode).
#   - lfs_safe_path         : refuse a path that is /, empty, /usr, /boot, /etc, /var, /home.
#   - lfs_die               : print + exit non-zero.
#   - lfs_log               : timestamped log line.
#
# Per Project Initiation v2 §9: scripts MUST fail closed (set -euo pipefail) and
# MUST refuse to operate on untrusted paths.

set -euo pipefail

# ----------------------------------------------------------------------------
# Hard-refusal list. Operations on these paths are forbidden in any script
# that sources this library. Updates here propagate to all callers.
# ----------------------------------------------------------------------------
_LFS_FORBIDDEN_PATHS=(
  "/"
  "/usr"
  "/usr/local"
  "/boot"
  "/etc"
  "/var"
  "/var/lib"
  "/var/log"
  "/home"
  "/root"
  "/bin"
  "/sbin"
  "/lib"
  "/lib64"
  "/proc"
  "/sys"
  "/dev"
  "/run"
)

# ----------------------------------------------------------------------------
# lfs_die <message>
# ----------------------------------------------------------------------------
lfs_die() {
  echo "FATAL: $*" >&2
  exit 1
}

# ----------------------------------------------------------------------------
# lfs_log <message>
# ----------------------------------------------------------------------------
lfs_log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

# ----------------------------------------------------------------------------
# lfs_assert_var_set <var-name>
# Assert that the named environment variable is set, non-empty, non-/.
# ----------------------------------------------------------------------------
lfs_assert_var_set() {
  local var_name="$1"
  local var_value="${!var_name:-}"
  if [[ -z "$var_value" ]]; then
    lfs_die "environment variable $var_name is not set"
  fi
  if [[ "$var_value" == "/" ]]; then
    lfs_die "environment variable $var_name is '/' — refusing to continue"
  fi
  if [[ "$var_value" != /* ]]; then
    lfs_die "environment variable $var_name='$var_value' is not an absolute path"
  fi
}

# ----------------------------------------------------------------------------
# lfs_safe_path <path>
# Refuse the path if it matches one of _LFS_FORBIDDEN_PATHS.
# ----------------------------------------------------------------------------
lfs_safe_path() {
  local p="$1"
  if [[ -z "$p" || "$p" == "/" ]]; then
    lfs_die "refusing empty or root path"
  fi
  if [[ "$p" != /* ]]; then
    lfs_die "refusing relative path: $p"
  fi
  local canonical
  canonical="$(realpath -m "$p" 2>/dev/null || readlink -f "$p" 2>/dev/null || echo "$p")"
  for bad in "${_LFS_FORBIDDEN_PATHS[@]}"; do
    if [[ "$canonical" == "$bad" || "$canonical" == "$bad/"* ]]; then
      lfs_die "refusing to operate on protected path: $canonical (matches $bad)"
    fi
  done
  echo "$canonical"
}

# ----------------------------------------------------------------------------
# lfs_assert_mounted <path>
# ----------------------------------------------------------------------------
lfs_assert_mounted() {
  local p="$1"
  if [[ ! -e "$p" ]]; then
    lfs_die "target path does not exist: $p"
  fi
  if [[ ! -d "$p" ]]; then
    lfs_die "target path is not a directory: $p"
  fi
  if mountpoint -q "$p" 2>/dev/null; then
    lfs_log "target $p is a mountpoint (mount-mode)"
  else
    lfs_log "target $p is a plain directory (directory-mode)"
  fi
}

# ----------------------------------------------------------------------------
# lfs_safe_rm <path>
# ----------------------------------------------------------------------------
lfs_safe_rm() {
  local p="$1"
  local canon
  canon="$(lfs_safe_path "$p")"

  if [[ -n "${LFS:-}" ]]; then
    local lfs_canon
    lfs_canon="$(lfs_safe_path "$LFS")"
    if [[ "$canon" != "$lfs_canon" && "$canon" != "$lfs_canon/"* ]]; then
      lfs_die "refusing rm outside \$LFS: $canon"
    fi
  fi

  local real_target
  real_target="$(readlink -f "$canon" 2>/dev/null || echo "$canon")"
  if [[ -n "${LFS:-}" ]]; then
    local lfs_real
    lfs_real="$(readlink -f "$LFS" 2>/dev/null || echo "$LFS")"
    if [[ "$real_target" != "$lfs_real" && "$real_target" != "$lfs_real/"* ]]; then
      lfs_die "refusing rm: symlink target escapes \$LFS: $real_target"
    fi
  fi

  for bad in "${_LFS_FORBIDDEN_PATHS[@]}"; do
    if [[ "$real_target" == "$bad" ]]; then
      lfs_die "refusing rm of protected path: $real_target"
    fi
  done

  lfs_log "safe-rm: $real_target"
  rm -rf -- "$real_target"
}

# ----------------------------------------------------------------------------
# Self-test (run with `bash scripts/lib/lfs-safety.sh --self-test`).
# ----------------------------------------------------------------------------
_lfs_self_test() {
  local failures=0
  _expect_fail() {
    local p="$1"
    if ( set +e; lfs_safe_path "$p" 2>/dev/null ); then
      echo "FAIL: path accepted but should be refused: $p"
      failures=$((failures+1))
    fi
  }
  _expect_pass() {
    local p="$1"
    if ! ( set +e; lfs_safe_path "$p" >/dev/null 2>&1 ); then
      echo "FAIL: path refused but should be accepted: $p"
      failures=$((failures+1))
    fi
  }

  _expect_fail "relative/path"
  _expect_fail "/"
  _expect_fail "/usr"
  _expect_fail "/usr/local/bin"
  _expect_pass "/tmp/foo/bar"

  if [[ $failures -eq 0 ]]; then
    echo "self-test OK (5/5)"
    exit 0
  else
    echo "self-test FAIL ($failures failures)"
    exit 1
  fi
}

if [[ "${1:-}" == "--self-test" ]]; then
  _lfs_self_test
fi
