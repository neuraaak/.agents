# Badge Registry — Python

Python-specific badges: PyPI version/status + tool badges. Combine with the forge badge registry (`forge/github/badge-registry.md` or `forge/gitlab/badge-registry.md`) for the full badge block.

This file is **data, not a rule**. Detect → look up → emit:

1. **Detect** which tools the project actually uses (signals below).
2. **Look up** the badge template.
3. **Emit** only for confirmed tools. Never emit a badge for a tool not present.

Replace `{pkg}` with the distribution name from `pyproject.toml` / `setup.cfg`.

**Logo and color** follow [simple-icons](https://simpleicons.org): logo is the icon slug, color is the brand hex (no `#`). Never guess — a wrong slug renders a blank icon.

---

## Registry version badges (public-oss only)

Always emit both for public Python packages:

```markdown
[![PyPI version](https://img.shields.io/pypi/v/{pkg}?style=flat&logo=pypi&logoColor=white)](https://pypi.org/project/{pkg}/)
[![Python versions](https://img.shields.io/pypi/pyversions/{pkg}?style=flat&logo=python&logoColor=white)](https://pypi.org/project/{pkg}/)
[![PyPI status](https://img.shields.io/pypi/status/{pkg}?style=flat&logo=pypi&logoColor=white)](https://pypi.org/project/{pkg}/)
```

Omit for `internal` profile — shields.io cannot reach private registries.

---

## Tool badges

Each entry: **tool** — detect via · logo slug · brand hex

### Package manager

- uv — `uv.lock` or `[tool.uv]` · `uv` · `DE5FE9`
- poetry — `poetry.lock` or `[tool.poetry]` · `poetry` · `60A5FA`
- pdm — `pdm.lock` or `[tool.pdm]` · `pdm` · `AC75D7`
- hatch — `[tool.hatch]` · _no logo_ · `lightgrey`
- conda — `environment.yml` · `anaconda` · `44A833`

### Linter

- ruff — `[tool.ruff]` or `ruff.toml` · `ruff` · `D7FF64`
- flake8 — `.flake8` or `[flake8]` in `setup.cfg` · _no logo_ · `lightgrey`
- pylint — `.pylintrc` or `[tool.pylint]` · _no logo_ · `lightgrey`

### Formatter

- ruff — `[tool.ruff.format]` · `ruff` · `D7FF64`
- black — `[tool.black]` · _no logo_ · `000000`
- isort — `[tool.isort]` · _no logo_ · `lightgrey`

### Type checker

- ty — `ty.toml` or `[tool.ty]` · `astral` · `261230`
- mypy — `mypy.ini` or `[tool.mypy]` · _no logo_ · `lightgrey`
- pyright — `pyrightconfig.json` or `[tool.pyright]` · _no logo_ · `lightgrey`

### Test runner

- pytest — `pytest.ini` or `[tool.pytest.ini_options]` · `pytest` · `0A9EDC`

### Coverage

- codecov — `codecov.yml` or Codecov step in CI · `codecov` · `F01F7A`
- coveralls — `.coveralls.yml` or Coveralls in CI · `coveralls` · `3F5767`

---

## Badge template

```markdown
[![{role}](https://img.shields.io/badge/{role}-{tool}-{color}?style=flat&logo={logo}&logoColor=white)]({link})
```

Omit `&logo={logo}&logoColor=white` when the tool has no logo slug. Use the tool's homepage as `{link}`.

---

## Example

Project with `uv.lock`, `[tool.ruff]`, `[tool.ruff.format]`, `[tool.ty]`, `[tool.pytest.ini_options]` on GitHub → emit (in order): PyPI version + Python versions + PyPI status, then tool badges for uv, ruff (linter + formatter share one badge), ty, pytest.
