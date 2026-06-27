# CI Tool Registry — Python

This file is **data, not a rule**. Detect → look up → substitute:

1. **Detect** which tool fills each role (config files, lockfiles — see the detection signal).
2. **Look up** the CI command below.
3. **Substitute** into the pipeline skeleton (role sequence in `python/pipelines.md`, step syntax in the platform file).

Never hard-code a fixed stack. A poetry + mypy + sphinx project must yield a poetry/mypy/sphinx pipeline, not a uv/ty/mkdocs one.

**Runner prefix:** commands below omit it. Prepend `uv run` (uv projects) or `poetry run` (poetry projects) before each tool invocation.

**Prefer the project's own scripts.** If a `Makefile`, `justfile`, or `[tool.poe]` defines targets (`make test`, `poe lint`), call those — they stay correct as the project evolves.

**If multiple candidates match,** the one with a config file/lockfile present wins. If still ambiguous, ask.

---

## Package install (reproducible)

- uv — `uv.lock` or `[tool.uv]` · `uv sync --frozen` (add `--extra <name>` / `--all-extras` for optional groups)
- poetry — `poetry.lock` or `[tool.poetry]` · `poetry install --no-interaction --sync`
- pdm — `pdm.lock` or `[tool.pdm]` · `pdm install --frozen-lockfile`
- pip — `requirements*.txt` · `pip install -r requirements.txt` (commit a pinned/hashed file)

## Lint

- ruff — `[tool.ruff]` or `ruff.toml` · `ruff check .`
- flake8 — `.flake8` or `[flake8]` in `setup.cfg` · `flake8`
- pylint — `.pylintrc` or `[tool.pylint]` · `pylint <package>`

## Format check

- ruff — `[tool.ruff.format]` · `ruff format --check .`
- black — `[tool.black]` · `black --check .`
- isort — `[tool.isort]` · `isort --check-only .`

## Type check

- ty — `ty.toml` or `[tool.ty]` · `ty check`
- mypy — `mypy.ini` or `[tool.mypy]` · `mypy <package>`
- pyright — `pyrightconfig.json` or `[tool.pyright]` · `pyright`

## Test (+ coverage)

- pytest — `pytest.ini` or `[tool.pytest.ini_options]` · `pytest` (coverage: `pytest --cov --cov-report=xml`)

## Security scan (SAST + dependencies)

- bandit (SAST) — `[tool.bandit]` or `.bandit` · `bandit -r src/ -ll` (`-ll` = medium severity minimum)
- semgrep (SAST, custom rules) — `.semgrep.yml` or `semgrep` in deps · `semgrep --config=p/python --error`
- pip-audit (dependencies) — uv/pip project · `pip-audit` (uv: `uv run pip-audit`)
- safety (dependencies, alt) — `safety` in deps · `safety check`

## Build (package artifact)

- uv — `[tool.uv]` · `uv build`
- poetry — `[tool.poetry]` · `poetry build`
- build — PEP 517 `[build-system]` (any backend) · `python -m build`

## Publish (to PyPI)

- OIDC trusted publishing (preferred) — trusted publisher configured on pypi.org · `uv publish` or `pypa/gh-action-pypi-publish` with `id-token: write`, no stored token
- API token (fallback) — `PYPI_API_TOKEN` secret · `twine upload dist/*` (env `TWINE_USERNAME=__token__`, `TWINE_PASSWORD=$PYPI_API_TOKEN`)

## Docs build / deploy

- mkdocs + mike (versioned) — `mkdocs.yml` + `mike` in deps · `mike deploy --push --update-aliases <version> latest` (pre-release: `mike deploy --push <version>`, no alias move)
- mkdocs (single version) — `mkdocs.yml`, no mike · `mkdocs gh-deploy --force`
- sphinx — `docs/conf.py` · `sphinx-build docs _site`

---

## Example resolution

`pyproject.toml` with `[tool.uv]`, `[tool.ruff]`, `[tool.ruff.format]`, `[tool.mypy]`, `[tool.pytest.ini_options]`, `mkdocs.yml` + mike, PyPI trusted publisher:

| Role         | Resolved command                                              |
| :----------- | :------------------------------------------------------------ |
| install      | `uv sync --frozen`                                            |
| lint         | `uv run ruff check .`                                         |
| format check | `uv run ruff format --check .`                                |
| type check   | `uv run mypy <package>`                                       |
| test         | `uv run pytest --cov --cov-report=xml`                        |
| build        | `uv build`                                                    |
| publish      | `uv publish` (OIDC)                                           |
| docs         | `uv run mike deploy --push --update-aliases <version> latest` |
