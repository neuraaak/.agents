# CI/CD Expert — Languages Index

Route by the language of the project. Always load both `pipelines.md` and `tool-registry.md` for the detected language. For polyglot repos, load both language pairs.

## Language routing

| Language                | Detect via       | Blueprint                           | Tool catalog                            |
| :---------------------- | :--------------- | :---------------------------------- | :-------------------------------------- |
| Python                  | `pyproject.toml` | `languages/python/pipelines.md`     | `languages/python/tool-registry.md`     |
| JavaScript / TypeScript | `package.json`   | `languages/javascript/pipelines.md` | `languages/javascript/tool-registry.md` |

The `pipelines.md` gives the **role sequence** and worked example. It does **not** fix the toolchain — resolve each role to a command via the matching `tool-registry.md`.

## What each file owns

- **`python/pipelines.md`** — Python pipeline blueprint: role sequence and Python-specific concerns (version matrix, runner prefix, frozen installs, OIDC publish).
- **`python/tool-registry.md`** — Python role→tool→command catalog (uv/poetry/pdm, ruff/mypy/ty, pytest, PyPI publish, mkdocs/sphinx). Detection signals included.
- **`javascript/pipelines.md`** — JS/TS pipeline blueprint: role sequence and JS/TS-specific concerns (Node version matrix, frozen installs, OIDC publish).
- **`javascript/tool-registry.md`** — JS/TS role→tool→command catalog (pnpm/npm/yarn/bun, eslint/biome, tsc, vitest/jest, npm publish, vitepress/docusaurus). Detection signals included.

## Adding a new language

1. Create `<language>/` here with `pipelines.md` + `tool-registry.md`.
2. Register in the routing table above and in `references/index.md`.
