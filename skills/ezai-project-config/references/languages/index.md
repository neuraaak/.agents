# Project Config — Languages Index

Route to the correct language subdirectory. For monorepos using both languages, load both files.

## Supported languages

| Language              | Detect via       | File                             |
| :-------------------- | :--------------- | :------------------------------- |
| Python                | `pyproject.toml` | `languages/python/config.md`     |
| JavaScript/TypeScript | `package.json`   | `languages/javascript/config.md` |

## What each file owns

- **`python/config.md`** — uv, ruff, ty, hatchling, pyproject.toml structure, 3.11+ syntax rules, Docker multi-stage pattern.
- **`javascript/config.md`** — pnpm, TypeScript 6.0+, ESM, Node.js 24+, package.json, tsconfig.json, ES2026 features, Docker multi-stage pattern.

## Adding a new language

1. Create `<language>/` here with `config.md`.
2. Register in the table above and in `references/index.md`.
