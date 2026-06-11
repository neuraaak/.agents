# Config & Toolchain — Python

## Règles

- **VENV** : toujours `.venv`. Ne jamais installer globalement.
- **TOOLS** : `uv` (packages), `ruff` (lint/format), `ty` (types), `pre-commit` (gates), `mkdocs` (docs).
- **BACKEND** : `hatchling` comme build backend — pas de `setuptools`, pas de `flit`.
- **CENTRAL** : toute config outil dans `pyproject.toml` — pas de `setup.cfg`, pas de `tox.ini`.
- **VERSION** : Python 3.11+ minimum. Épingler dans `.python-version`.

## Environnement

```bash
uv venv                          # créer .venv
uv sync                          # installer les deps depuis uv.lock
uv run pytest                    # exécuter dans le venv sans l'activer
uv run ruff check .
uv run ruff format .
uv run ty check
```

## `.python-version`

```text
3.12
```

Committer ce fichier pour épingler la version Python utilisée par `uv` et `pyenv`.

## `pyproject.toml` — structure complète

L'ordre des sections (les emojis aident à la navigation visuelle) :

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

Toujours documenter les sélections de règles ruff avec des commentaires inline.

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
uv run pre-commit install   # activer les hooks Git
uv run pre-commit run --all-files  # lancer manuellement
```

## `mkdocs` — config minimale

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

## Syntaxe fondamentale (3.11+)

```python
from __future__ import annotations  # annotations différées — toujours

from pathlib import Path             # pathlib uniquement, pas os.path

def read_file(path: str | Path) -> bytes:   # union avec |, pas Union[]
    with Path(path).open("rb") as f:
        return f.read()
```

- `from __future__ import annotations` dans chaque fichier
- `pathlib.Path` exclusivement pour les opérations filesystem
- Syntaxe union `int | str` (pas `Union`)
- `with` statements pour tout cleanup de ressource
- `t-strings` (PEP 750) pour les templates sécurisés en 3.14+

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

- Tags exacts — jamais `python:latest`
- `--frozen` en CI pour respecter le lockfile
- Utilisateur non-root en stage runtime

## Variables d'environnement

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

## Critères de succès

- `uv` exclusivement pour la gestion des packages ; `uv.lock` commité.
- `pyproject.toml` est la source de vérité unique.
- `from __future__ import annotations` dans chaque fichier Python.
- `hatchling` comme build backend.
- `ruff lint` + `ruff format` configurés avec règles commentées.
- `pre-commit` installé avec hooks ruff + ty.
- Images Docker multi-stage, non-root, tags épinglés.
- Secrets via variables d'environnement — jamais en dur.
