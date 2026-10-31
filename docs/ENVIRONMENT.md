# Build host environment — inventory

This document records what the build host actually provides. It is **distinct** from the target hardware profile (see `TARGET_HARDWARE.md`). The host is the machine that runs the LFS build; the target is the (older) machine that runs the finished distribution.

Inventory was produced by read-only commands on **2026-10-30 (UTC+8)**. No host packages were installed and no host configuration was changed in the process.

## 1. Operating system

| Field | Value |
|---|---|
| Kernel (host) | Linux 5.10.134-013.15.kangaroo.al8.x86_64 |
| Distribution | Debian GNU/Linux 13 (trixie) 13.4 |
| Architecture | x86_64 |
| Hypervisor | KVM (this host is itself a VM) |
| Virtualization type | full |

The host kernel is 5.10.x, which is older than the LFS 13.1 host requirement ("Linux 5.10 or newer"). This satisfies the LFS minimum, but is significantly older than the LTS line that this project will pin as the target kernel.

## 2. CPU

| Field | Value |
|---|---|
| Model | Intel(R) Xeon(R) Processor (family 6, model 173, stepping 1) |
| Cores | 2 (2 sockets × 1 thread) |
| BogoMIPS | 6400.00 |
| Flags of interest | sse4_2, avx, avx2, avx512f, aes, rdrand, rdseed, pku, amx_*, la57, avx_vnni |

Two cores is enough to bootstrap LFS but kernel builds will be slow. The presence of AVX-512 and AMX is irrelevant for the target — release kernels must use generic x86_64 baseline (no `-march=native`).

## 3. RAM and swap

```
               total        used        free      shared  buff/cache   available
Mem:           4.1Gi       474Mi       3.6Gi        48Ki       180Mi       3.6Gi
Swap:             0B          0B          0B
```

4 GB is adequate for an LFS build of a generic kernel plus a small userspace. No swap is configured — for safety we will **not** add swap to the host. If build OOM occurs, we will split the build into smaller stages or move to a build worker (out of scope for Phase 0).

## 4. Disk

```
c-…-rootfs  9.9G  86M  9.3G   1% /
```

9.3 GB free is enough for Phase 0 deliverables and likely enough for a Phase 2 minimal LFS build (LFS 13.1 needs ~10–15 GB including sources and toolchain). If a full build is attempted on this host, we may need to clean between stages or relocate the build to a larger volume. **This will be revisited at the Phase 2 gate.**

## 5. Network

| Target | Reachable? |
|---|---|
| `https://kernel.org` | yes (HTTP/2 200) |
| `https://cdn.kernel.org/pub/linux/kernel/v6.x/...` | yes |
| `https://www.linuxfromscratch.org/lfs/view/13.1-systemd/` | yes |
| `https://ftpmirror.gnu.org/` | not reachable from this sandbox (HEAD fails with "Network is unreachable") — Phase 2 download script will use `https://mirrors.kernel.org/gnu/` as a fallback mirror |

Network is available for kernel.org and linuxfromscratch.org. Source manifests can carry verified URL+version pairs. The Phase 0 `sources.lock` will pin the kernel tarball and the LFS 13.1-systemd package list; SHA256 will be computed in Phase 2 after download.

## 6. Build toolchain — host

Versions of tools required by the LFS 13.1 host-requirements chapter, as actually installed on this host:

| Tool | Required (≥) | Installed | Status |
|---|---|---|---|
| Bash | 3.2 | 5.2.21 | OK |
| Binutils | 2.13.1 | 2.44 | OK |
| Bison | 2.7 | **missing** | BLOCKER for Phase 2 |
| Bzip2 | 1.0.8 | 1.0.8 | OK |
| Coreutils | 8.1 | 9.x (Debian 13) | OK |
| Diffutils | 2.8.1 | 3.x | OK |
| Findutils | 4.2.31 | 4.x | OK |
| Gawk | 4.0.1 | **missing** | BLOCKER for Phase 2 |
| GCC | 5.4 (≤16.2) | 14.2.0 | OK |
| Grep | 2.5.1a | 3.11 | OK |
| Gzip | 1.3.12 | 1.13 | OK |
| M4 | 1.4.10 | 1.4.19 | OK |
| Make | 4.0 | 4.4.1 | OK |
| Patch | 2.5.4 | 2.8 | OK |
| Perl | 5.8.8 | 5.40.1 | OK |
| Python | 3.4 | 3.12.16 | OK |
| Sed | 4.1.5 | 4.9 | OK |
| Tar | 1.22 | 1.35 | OK |
| Texinfo | 5.0 | **missing** | BLOCKER for Phase 2 |
| Xz | 5.0.0 | 5.8.1 | OK |

Additional tools missing for downstream phases:

| Tool | Why needed | Status |
|---|---|---|
| `flex` | some LFS packages require it | missing |
| `shellcheck` | validate `scripts/` per §11 | missing |
| `ninja` | meson/ninja build system | missing |
| `meson` | systemd build | missing |
| `ccache` | optional reproducibility acceleration | missing |
| `rustc`/`cargo` | Phase 7 package manager (if Rust is chosen) | missing |
| `qemu-system-x86_64`, `qemu-img` | Phase 3 QEMU boot tests | missing |
| `/dev/kvm` | hardware-assisted QEMU (nested virt) | absent (host is itself a VM with no nested virt) |
| `fio` (the real disk bench) | Phase 5 disk I/O benchmarks | the `fio` on PATH (`/home/z/.venv/bin/fio`) is the Python `fiona` CLI, NOT the disk I/O bench. The host-version-check script correctly detects this. |

**All of the above require explicit user permission before installation on the host.** Phase 0 does not need any of them. Phase 2 will be blocked until bison, gawk, texinfo and (for some packages) flex are present.

## 7. Privileges

| Item | Value |
|---|---|
| User | `z` (uid=1001, gid=1001) |
| `sudo` | available but **password-required** (no passwordless sudo) |
| Root shell | not available without password |

Implications:

- The LFS Chapter 4 step "create user `lfs`" cannot be performed without user-supplied root credentials.
- The LFS Chapter 2 step "make a partition and `mount` it on `$LFS`" cannot be performed on a physical block device, but **can** be performed on a loopback file (`losetup` requires root) or — preferred — on a regular directory under `/home/z/my-project/` (no root needed for the directory, but mount-style isolation is unavailable).
- Phase 0 deliverables need no root.

## 8. What Phase 0 can and cannot verify on this host

| Activity | Possible on this host? |
|---|---|
| Run `scripts/host-version-check.sh` (LFS version-check) | yes (will report missing tools) |
| Run `scripts/bench/idle-ram.sh` on host | yes (measure host, not target) |
| Run `scripts/bench/disk-io-fio.sh` on host | needs real `fio` (the one on PATH is `fiona`); will use a `dd`-based fallback |
| Run `scripts/bench/boot-time.sh` on host | no (cannot measure host boot without reboot rights); will record as a manual procedure |
| Shellcheck | no (tool missing); use a portable Bash style instead and re-check when shellcheck becomes available |
| QEMU boot of the future target system | no (`qemu-system-x86_64` missing); deferred to Phase 3 with explicit status `Verified (build)` only |
| Build the Phase 2 LFS toolchain | blocked (bison, gawk, texinfo missing; root needed for `lfs` user) |

## 9. Open questions for the project owner

1. May we install the missing LFS host prerequisites on this host? Suggested list: `bison flex gawk texinfo shellcheck qemu-system-x86_64 qemu-utils ninja-build meson ccache` and the real `fio` (e.g., from `apt: fio`).
2. May we use `sudo` (with password) to create the `lfs` user, OR should we build entirely without a dedicated `lfs` user (using the unprivileged `z` user and a project-owned build directory)?
3. Is `/dev/kvm` likely to become available (e.g., on a different worker), or should Phase 3 plan for TCG-only QEMU?

These questions are batched in `REPORT.md` and require owner decisions before Phase 2 can start. None of them blocks Phase 0.
