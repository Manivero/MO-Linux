# Module: build-system

Stub directory. Contents will be added in later phases.

## Purpose

Build system module — orchestration of LFS build (Phase 2).
Will contain:
- build.sh — top-level orchestrator for S2-S8
- stage-*.sh — per-stage scripts (stage-s2-fetch.sh, stage-s3-toolchain.sh, ...)
- reproducibility-check.sh — rebuild + diff
- checkpoint.sh — tar snapshot of /mnt/lfs

Status: Planned (Phase 2).
Spec: BUILD_SYSTEM.md, PHASE2_PLAN.md.
