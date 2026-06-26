# Config & Toolchain — Python

## Rules

- **VENV**: always `.venv`. Never install globally.
- **TOOLS**: `uv` (packages), `ruff` (lint/format), `ty` (types — see note), `pre-commit` (gates), `mkdocs` (docs).
- **TYPES**: `ty` (Astral) is the forward default but still **in preview** — recommend it for new projects, and keep `mypy` as the stable fallback for teams that need maturity today. Pick one; don't run both as blocking gates.
- **BACKEND**: `hatchling` as the build backend — no `setuptools`, no `flit`.
- **CENTRAL**: all tool config in `pyproject.toml` — no `setup.cfg`, no `tox.ini`.
- **VERSION**: Python 3.12+ minimum. Pin in `.python-version`.

## Environment

```bash
uv venv                          # create .venv
uv sync                          # install deps from uv.lock
uv run pytest                    # run inside the venv without activating it
uv run ruff check .
uv run ruff format .
uv run ty check
```

## `.python-version`

```text
3.14
```

Commit this file to pin the Python version used by `uv` and `pyenv`.

## `pyproject.toml` — full structure

Section order (the emojis aid visual navigation):

```toml
# 🔨 Build system
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

# 📦 Metadata
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

# 🧰 Dev tooling (PEP 735 — installed by `uv sync` by default)
[dependency-groups]
dev = ["pytest", "ruff", "ty", "mkdocs"]

# 🎨 Linting
[tool.ruff.lint]
select = [
    "E",   # pycodestyle errors
    "F",   # pyflakes
    "I",   # isort
    "S",   # bandit (security)
    "UP",  # pyupgrade
]
ignore = []

# 🖌️ Formatting
[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "auto"

# 🔍 Type checking — ty (preview default)
[tool.ty]
strict = true

# Stable fallback — use instead of [tool.ty] if you need maturity today
# [tool.mypy]
# strict = true

# 🧪 Tests
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"
```

Always document ruff rule selections with inline comments.

## `pre-commit` — config

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.0          # pin to the latest ruff release
    hooks:
      - id: ruff-check   # the `ruff` hook was renamed `ruff-check`
        args: [--fix]
      - id: ruff-format
  # Type-check with the same checker declared in pyproject.toml (ty)
  - repo: local
    hooks:
      - id: ty
        name: ty
        entry: uv run ty check
        language: system
        types: [python]
        pass_filenames: false
# Stable fallback — swap the local `ty` hook for mypy if you chose it instead:
#   - repo: local
#     hooks:
#       - id: mypy
#         name: mypy
#         entry: uv run mypy
#         language: system
#         types: [python]
```

```bash
uv run pre-commit install   # enable Git hooks
uv run pre-commit run --all-files  # run manually
```

## `mkdocs` — minimal config

```yaml
# mkdocs.yml
site_name: My Project
theme:
  name: material
nav:
  - Home: index.md
  - API: api/
plugins:
  - search
  - mkdocstrings:
      handlers:
        python:
          options:
            docstring_style: google
```

## Core syntax (3.12+)

```python
from __future__ import annotations  # deferred annotations — always

from pathlib import Path             # pathlib only, not os.path

def read_file(path: str | Path) -> bytes:   # union with |, not Union[]
    with Path(path).open("rb") as f:
        return f.read()
```

- `from __future__ import annotations` in every file
- `pathlib.Path` exclusively for filesystem operations
- Union syntax `int | str` (not `Union`)
- `with` statements for any resource cleanup
- `t-strings` (PEP 750) for safe templating in 3.14+

## Docker multi-stage (Python)

```dockerfile
# Build stage
FROM python:3.14-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

# Runtime stage
FROM python:3.14-slim
RUN useradd -m appuser
USER appuser
WORKDIR /app
COPY --from=builder /app/.venv .venv
COPY src/ src/
HEALTHCHECK --interval=30s --timeout=5s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"
CMD [".venv/bin/python", "-m", "my_project"]
```

- Exact tags — never `python:latest`
- `--frozen` in CI to honor the lockfile
- Non-root user in the runtime stage

## Environment variables

```python
import os

def get_env(key: str, default: str | None = None) -> str:
    value = os.environ.get(key, default)
    if value is None:
        raise RuntimeError(f"Required environment variable '{key}' is not set")
    return value

DATABASE_URL = get_env("DATABASE_URL")
API_KEY = get_env("API_KEY")
```

## Success criteria

- `uv` exclusively for package management; `uv.lock` committed.
- `pyproject.toml` is the single source of truth.
- `from __future__ import annotations` in every Python file.
- `hatchling` as the build backend.
- `ruff lint` + `ruff format` configured with commented rules.
- `pre-commit` installed with ruff + a type-check hook (`ty` by default, `mypy` as the stable fallback).
- Multi-stage Docker images, non-root, pinned tags.
- Secrets via environment variables — never hard-coded.
