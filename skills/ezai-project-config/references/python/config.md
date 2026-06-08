# Config & Toolchain — Python

## Rules

- **VENV:** Always `.venv`. Never install globally.
- **TOOLS:** `uv` (packages), `ruff` (lint/format), `ty` (types), `pre-commit` (gates), `mkdocs` (docs).
- **BACKEND:** `hatchling` as build backend — no `setuptools`, no `flit`.
- **CENTRAL:** All tool config in `pyproject.toml` — no `setup.cfg`, no `tox.ini`.
- **VERSION:** Target Python 3.11+ minimum.

## Environment

```bash
uv venv                          # create .venv
uv sync                          # install deps from uv.lock
uv run pytest                    # run inside venv without activating
uv run ruff check .
uv run ty check
```

## `pyproject.toml` structure

Section order (emoji markers help visual navigation):

```toml
# 🔨 Build system
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

# 📦 Metadata
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

# 🎨 Code quality
[tool.ruff.lint]
select = [
    "E",   # pycodestyle errors
    "F",   # pyflakes
    "I",   # isort
    "S",   # bandit (security)
    "UP",  # pyupgrade
]

[tool.ty]
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
```

Always document ruff rule selections with inline comments.

## Foundational syntax checklist (3.11+)

```python
from __future__ import annotations  # deferred annotations — always

from pathlib import Path             # pathlib only, no os.path

def read_file(path: str | Path) -> bytes:   # union with |, not Union[]
    with Path(path).open("rb") as f:
        return f.read()
```

- `from __future__ import annotations` in every file
- `pathlib.Path` exclusively for filesystem ops
- `int | str` union syntax (not `Union`)
- `with` statements for all resource cleanup
- `t-strings` (PEP 750) for safe templates in 3.14+

## Docker multi-stage (Python)

```dockerfile
# Build stage
FROM python:3.14-slim AS builder
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen --no-dev

# Runtime stage
FROM python:3.14-slim
RUN useradd -m appuser
USER appuser
WORKDIR /app
COPY --from=builder /app/.venv .venv
COPY src/ src/
CMD [".venv/bin/python", "-m", "my_project"]
```

- Pin exact image tags — never `python:latest`
- `--frozen` in CI to respect the lockfile
- Non-root user in production stage

## Success criteria

- `uv` exclusively for package management; `uv.lock` committed.
- `pyproject.toml` is the single source of truth.
- `from __future__ import annotations` in every Python file.
- `hatchling` as build backend.
- Docker images multi-stage, non-root.
