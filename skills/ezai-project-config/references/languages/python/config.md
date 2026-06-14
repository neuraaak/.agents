# Config & Toolchain — Python

## Rules

- **VENV**: always `.venv`. Never install globally.
- **TOOLS**: `uv` (packages), `ruff` (lint/format), `ty` (types), `pre-commit` (gates), `mkdocs` (docs).
- **BACKEND**: `hatchling` as the build backend — no `setuptools`, no `flit`.
- **CENTRAL**: all tool config in `pyproject.toml` — no `setup.cfg`, no `tox.ini`.
- **VERSION**: Python 3.11+ minimum. Pin in `.python-version`.

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
3.12
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
requires-python = ">=3.11"
dependencies = []

[project.optional-dependencies]
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

# 🔍 Type checking
[tool.ty]
strict = true

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
    rev: v0.4.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.10.0
    hooks:
      - id: mypy
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

## Core syntax (3.11+)

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
- `pre-commit` installed with ruff + ty hooks.
- Multi-stage Docker images, non-root, pinned tags.
- Secrets via environment variables — never hard-coded.
