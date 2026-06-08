# Badge Registry

Catalog of tool badges that may appear in a `README.md` or `docs/index.md`, for Python and JavaScript/TypeScript projects.

This file is **data, not a rule**. Do not assume any tool is present. The workflow is:

1. **Detect** which tools the project actually uses (config files, manifest sections — see the "Detect when" column).
2. **Look up** each detected tool below.
3. **Emit** its badge using the template, in the badge block.

Never emit a badge for a tool you have not confirmed. Never hard-code a fixed stack.

---

## Static tool badge template

All tool badges are static (they link to the tool's homepage, not a live endpoint):

```markdown
[![{role}](https://img.shields.io/badge/{role}-{tool}-{color}?style=flat&logo={logo}&logoColor=white)]({link})
```

- `{role}` — the category label (e.g. `linter`, `type checker`).
- `{tool}` — the tool name shown as the badge value (e.g. `ruff`).
- `{logo}` / `{color}` / `{link}` — from the catalog below.
- If a tool has no logo slug, omit `&logo={logo}&logoColor=white` entirely.

**Logo and color are per-tool brand values, not role-generic.** Both follow [simple-icons](https://simpleicons.org): the logo is the icon slug, the color is the brand hex (without `#`). When a tool has no simple-icons entry, omit the logo and fall back to `{color}` = `lightgrey`. Never guess a slug or hex — a wrong slug renders a blank icon, a wrong hex misbrands the tool.

---

Each entry reads: **tool** — detection signal · logo slug (or _no logo_) · brand hex.

## Python (`references/python/`)

- **Package manager**
  - uv — `uv.lock` or `[tool.uv]` · `uv` · `DE5FE9`
  - poetry — `poetry.lock` or `[tool.poetry]` · `poetry` · `60A5FA`
  - pdm — `pdm.lock` or `[tool.pdm]` · `pdm` · `AC75D7`
  - hatch — `[tool.hatch]` · _no logo_ · `lightgrey`
  - conda — `environment.yml` · `anaconda` · `44A833`
- **Linter**
  - ruff — `ruff.toml` or `[tool.ruff]` · `ruff` · `D7FF64`
  - flake8 — `.flake8` or `[flake8]` in `setup.cfg` · _no logo_ · `lightgrey`
  - pylint — `.pylintrc` or `[tool.pylint]` · _no logo_ · `lightgrey`
- **Formatter**
  - black — `[tool.black]` · _no logo_ · `000000`
  - isort — `[tool.isort]` · _no logo_ · `lightgrey`
  - ruff — `[tool.ruff.format]` · `ruff` · `D7FF64`
- **Type checker**
  - mypy — `mypy.ini` or `[tool.mypy]` · _no logo_ · `lightgrey`
  - ty — `ty.toml` or `[tool.ty]` · `astral` · `261230`
  - pyright — `pyrightconfig.json` or `[tool.pyright]` · _no logo_ · `lightgrey`
- **Test runner**
  - pytest — `pytest.ini` or `[tool.pytest.ini_options]` · `pytest` · `0A9EDC`
- **Coverage**
  - codecov — `codecov.yml` or Codecov in CI · `codecov` · `F01F7A`
  - coveralls — `.coveralls.yml` or Coveralls in CI · `coveralls` · `3F5767`

---

## JavaScript / TypeScript (`references/javascript/`)

- **Package manager**
  - npm — `package-lock.json` · `npm` · `CB3837`
  - pnpm — `pnpm-lock.yaml` · `pnpm` · `F69220`
  - yarn — `yarn.lock` · `yarn` · `2C8EBB`
  - bun — `bun.lockb` · `bun` · `FBF0DF`
- **Linter**
  - eslint — `.eslintrc*` or `eslint.config.*` · `eslint` · `4B32C3`
  - biome — `biome.json` · `biome` · `60A5FA`
  - oxlint — `.oxlintrc.json` · `oxc` · `lightgrey`
- **Formatter**
  - prettier — `.prettierrc*` or `prettier` key in `package.json` · `prettier` · `F7B93E`
  - biome — `biome.json` · `biome` · `60A5FA`
- **Type checker**
  - typescript — `tsconfig.json` · `typescript` · `3178C6`
- **Test runner**
  - jest — `jest.config.*` or `jest` key in `package.json` · `jest` · `C21325`
  - vitest — `vitest.config.*` · `vitest` · `6E9F18`
  - mocha — `.mocharc*` · `mocha` · `8D6748`
- **Build / bundler**
  - vite — `vite.config.*` · `vite` · `646CFF`
  - webpack — `webpack.config.*` · `webpack` · `8DD6F9`
  - rollup — `rollup.config.*` · `rollupdotjs` · `EC4A3F`
  - esbuild — `esbuild` in `package.json` scripts/deps · `esbuild` · `FFCF00`

---

## Example

A Python project with `uv.lock`, `[tool.ruff]`, and `[tool.ty]` configured yields exactly three tool badges:

```markdown
[![uv](https://img.shields.io/badge/package%20manager-uv-DE5FE9?style=flat&logo=uv&logoColor=white)](https://github.com/astral-sh/uv)
[![linter](https://img.shields.io/badge/linter-ruff-D7FF64?style=flat&logo=ruff&logoColor=white)](https://github.com/astral-sh/ruff)
[![type checker](https://img.shields.io/badge/type%20checker-ty-261230?style=flat&logo=astral&logoColor=white)](https://github.com/astral-sh/ty)
```

A project with none of these configured yields **zero** tool badges — only the core badges (version, license, CI, docs) remain.
