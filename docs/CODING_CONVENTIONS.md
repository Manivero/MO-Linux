# CODING_CONVENTIONS — языки, стиль, git

Статус: **Implemented** (рекреирован 2026-10-31 после recycle песочницы; включает AUDIT-013 linguistic policy).

## 1. Языковая политика (§15 Project Initiation v2, AUDIT-013)

| Тип контента | Язык | Обоснование |
|---|---|---|
| Документация (Phase 1+, ADR-0008+, и т.д.) | **Русский** | §15 — общение с владельцем на русском |
| Документация Phase 0 (исходная) | Английский | историческая; перевод опционален |
| Код (bash, python) | **Английский** (имена переменных, функций, комментарии) | индустриальный стандарт |
| Сообщения об ошибках в коде | **Английский** | grep-friendly, ASCII-safe |
| Commit messages | **Английский** | git flow; UTF-8 safe |
| README верхнего уровня | **Русский** | для владельца |
| Metadata в .lpkg | **Английский** (machine-readable) | JSON fields |

## 2. Bash

- `set -euo pipefail` во всех скриптах.
- `IFS=$'\n\t'` (если нужен кастомный).
- Кавычки ВСЕГДА: `"$var"`, `"$(cmd)"`.
- Не использовать `[ ... ]`; использовать `[[ ... ]]`.
- Не использовать `function name()`; использовать `name() {`.
- `local` для локальных переменных в функциях.
- Self-test для safety библиотек.
- `shellcheck` — обязательный (если установлен); не имитировать если отсутствует.

### Пример

```bash
#!/usr/bin/env bash
# Build bash package for LFS
# Phase 2, S4

set -euo pipefail
IFS=$'\n\t'

source /usr/local/lib/lfs-safety.sh

PKG_NAME="bash"
PKG_VERSION="5.2.32"
PKG_TARBALL="${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_SRC_DIR="${LFS}/sources/${PKG_NAME}-${PKG_VERSION}"

lfs_safe_path "${PKG_SRC_DIR}"
cd "${PKG_SRC_DIR}"

./configure --prefix=/usr --without-bash-malloc
make -j"$(nproc)"
make install DESTDIR="${LFS}"
```

## 3. Python

- Python 3.10+ (соответствует Debian 13).
- `from __future__ import annotations` для PEP 604 union types.
- Type hints везде.
- `argparse` для CLI.
- `dataclasses` для данных.
- `if __name__ == "__main__":` guard.
- `py_compile` проходит.
- Black / ruff style (опционально, если установлены).

### Пример

```python
#!/usr/bin/env python3
"""Lint ADR files for required sections."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def lint_file(path: Path) -> list[str]:
    """Return list of issues for a single ADR file."""
    issues: list[str] = []
    text = path.read_text(encoding="utf-8")
    # ... linting logic ...
    return issues


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("adr_dir", type=Path)
    args = parser.parse_args(argv)
    # ...
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

## 4. Makefile

- Табуляции для recipe (не пробелы).
- `.PHONY` для non-file targets.
- `help` target по умолчанию.
- `set -euo pipefail` в shell recipes.

## 5. Markdown

- Заголовки: `#` (H1) только в начале файла; `##` для разделов; `###` для подраздлов.
- Таблицы с выравниванием колонок.
- Code blocks с указанием языка (```bash, ```python).
- Ссылки: `[text](url)` или reference-style `[text][ref]` + `[ref]: url`.
- Emphasis: `**bold**`, `*italic*`; НЕ использовать `_underline_`.
-Lists: `-` для unordered; `1.` для ordered (не путать с автоматической нумерацией).

## 6. Git

- **Коммиты и push запрещены без отдельного разрешения владельца** (§10 Project Initiation v2).
- Платформенный git-репозиторий песочницы (`/home/z/my-project/.git`) делает автокоммиты снапшотов — это поведение платформы, не действия агента; не модифицируется.
- Когда коммиты будут разрешены:
  - `feat:` — new feature.
  - `fix:` — bug fix.
  - `docs:` — documentation.
  - `refactor:` — code restructure.
  - `test:` — test changes.
  - `chore:` — misc.
  - `phase:` — phase-level changes.
  - Format: `type(scope): subject` (subject <50 chars, lowercase, no period).
- Branch naming: `phase-<N>-<short-desc>` (например, `phase-2-build-env`).

## 7. Файлы

- Все файлы создаются под `/home/z/my-project/download/distro/`.
- Имена файлов: lowercase, hyphens (не underscores), extension.
- Исполняемые скрипты: `chmod +x`.
- Encoding: UTF-8 без BOM.
- Line endings: LF (Unix).
- Trailing newline: yes.

## 8. Кросс-ссылки

- Относительные пути в markdown: `[text](../../docs/adr/0008-update-rollback-ab.md)`.
- Абсолютные пути — только для filesystem paths в коде.
- Каждая ADR должна ссылаться на связанные ADR (Decision: «см. ADR-XXXX»).

## 9. Связанные документы

- `docs/AUDIT_FINDINGS.md` — AUDIT-013 (linguistic policy).
- `Makefile` — `lint`, `check` targets.
- `.github/workflows/ci.yml` — CI (lint only, no push).
