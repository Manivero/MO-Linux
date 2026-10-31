# Makefile — single entry point for project tasks.
#
# Per Project Initiation v2 §14: "Makefile или единая точка входа сборки".
#
# Phase 0 scope: only safe, read-only checks. No LFS build, no kernel build,
# no host package install, no commit/push.
#
# Usage:
#   make help          — show available targets
#   make check         — run host version check + self-tests
#   make bench         — run idle-ram + boot-time + disk-io benchmarks
#   make shellcheck    — lint shell scripts (requires shellcheck; skips if absent)
#   make sources-verify — HEAD-check every URL in sources.lock
#   make adr-lint      — sanity-check ADR files for required sections

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS      := $(PROJECT_ROOT)/scripts
RESULTS      := $(PROJECT_ROOT)/bench/results

.PHONY: help check bench shellcheck sources-verify adr-lint self-test clean

help:
	@echo "Available targets:"
	@echo "  check           — host version check + lib self-test"
	@echo "  bench           — idle-ram, boot-time, disk-io"
	@echo "  shellcheck      — lint shell scripts (skipped if tool absent)"
	@echo "  sources-verify  — HEAD-check URLs in sources.lock"
	@echo "  adr-lint        — sanity-check ADR files"
	@echo "  self-test       — run lfs-safety.sh self-test"
	@echo "  clean           — remove bench/results/* (does NOT touch git)"

check: self-test
	@echo "==> host-version-check.sh"
	@bash $(SCRIPTS)/host-version-check.sh || \
	  (echo "Note: host-version-check reported failures; see output above." >&2; exit 0)
	@echo "==> check complete (see bench/results/ for raw output)"

self-test:
	@bash $(SCRIPTS)/lib/lfs-safety.sh --self-test

bench:
	@echo "==> idle-ram"
	@bash $(SCRIPTS)/bench/idle-ram.sh
	@echo "==> boot-time"
	@bash $(SCRIPTS)/bench/boot-time.sh
	@echo "==> disk-io"
	@bash $(SCRIPTS)/bench/disk-io.sh

shellcheck:
	@if ! command -v shellcheck >/dev/null 2>&1; then \
	  echo "shellcheck: SKIPPED (not installed; install for full linting)"; \
	  exit 0; \
	fi
	@echo "==> shellcheck on scripts/"
	@shellcheck $(SCRIPTS)/host-version-check.sh \
	            $(SCRIPTS)/lib/lfs-safety.sh \
	            $(SCRIPTS)/bench/idle-ram.sh \
	            $(SCRIPTS)/bench/boot-time.sh \
	            $(SCRIPTS)/bench/disk-io.sh

sources-verify:
	@echo "==> sources-verify (HEAD checks)"
	@python3 $(PROJECT_ROOT)/scripts/sources-verify.py $(PROJECT_ROOT)/sources.lock

adr-lint:
	@echo "==> adr-lint"
	@python3 $(PROJECT_ROOT)/scripts/adr-lint.py $(PROJECT_ROOT)/docs/adr

clean:
	@echo "Removing bench/results/* (does NOT touch git)"
	@rm -rf -- $(RESULTS)/*
	@mkdir -p $(RESULTS)
	@echo "Done."
