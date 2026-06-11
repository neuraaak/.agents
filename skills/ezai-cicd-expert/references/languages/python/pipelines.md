# Python — Pipeline Blueprint

The role sequence and Python-specific concerns for a CI pipeline. **Do not hard-code tools here** — detect the project's toolchain and resolve each role to a command via `python/tool-registry.md`. Wrap the resolved commands as steps/scripts using the platform file (`github/syntax.md` or `gitlab/syntax.md`).

## Role sequence

```text
install → lint → format-check → type-check → test → build → publish → docs
```

Lint / format-check / type-check are independent and gate the rest. `test` fans out across a Python version matrix. `build`, `publish`, `docs` run only on a release ref.

## Python-specific concerns

- **Version matrix:** drive it from the project's `requires-python` floor up to current stable (e.g. `["3.11", "3.12", "3.13"]`). Don't test versions below the declared floor.
- **Runner prefix:** Python tools run inside the environment — `uv run <tool>` (uv) or `poetry run <tool>` (poetry). The registry commands omit this prefix; add the one matching the detected package manager.
- **Frozen installs:** the install command must respect the lockfile (`uv sync --frozen`, `poetry install`, `pdm install --frozen-lockfile`). Adding `--extra`/`--all-extras` for optional groups does **not** waive `--frozen`.
- **Publish auth:** prefer OIDC trusted publishing (no stored token); fall back to `PYPI_API_TOKEN`. Both resolutions are in the registry.

## Worked example (uv + ruff + mypy + pytest)

Detection: `[tool.uv]`, `[tool.ruff]`, `[tool.mypy]`, `[tool.pytest.ini_options]` → registry lookup yields `uv sync --frozen`, `uv run ruff check .`, `uv run mypy`, `uv run pytest`. Wrapped for **GitHub Actions**:

```yaml
jobs:
  quality:
    runs-on: ubuntu-24.04
    permissions: { contents: read }
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
        with: { enable-cache: true }
      - run: uv sync --frozen --all-extras
      - run: uv run ruff check .
      - run: uv run ruff format --check .
      - run: uv run mypy src

  test:
    needs: [quality]
    runs-on: ubuntu-24.04
    strategy:
      fail-fast: false
      matrix: { python: ["3.11", "3.12", "3.13"] }
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
        with: { python-version: "${{ matrix.python }}", enable-cache: true }
      - run: uv sync --frozen
      - run: uv run pytest --cov --cov-report=xml
```

For **GitLab CI**, wrap the same resolved commands as `script:` entries with a lockfile-keyed `cache:` (see `gitlab/syntax.md`). For **publish** and **docs deploy**, resolve those roles in the registry and place them in the orchestration file's release cascade.

A poetry / pylint / pyright / sphinx project keeps this exact structure but every command differs — re-resolve from the registry, never copy the uv commands above.
