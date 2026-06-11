# Project Architect — Languages Index

Route to the correct language subdirectory. For polyglot repos, load both language files.

## Supported languages

| Language              | Detect via       | File                                   |
| :-------------------- | :--------------- | :------------------------------------- |
| Python                | `pyproject.toml` | `languages/python/architecture.md`     |
| JavaScript/TypeScript | `package.json`   | `languages/javascript/architecture.md` |

## What each file owns

- **`python/architecture.md`** — Python 3.11+: visibility rules, `__all__`, Protocol-based interfaces, TypedDict, Hexagonal structure, Ports & Adapters.
- **`javascript/architecture.md`** — ES2026/TypeScript 6.0+: module organization, `#private` fields, Repository pattern, TS type system, Hexagonal equivalent.

## Adding a new language

1. Create `<language>/` here with `architecture.md`.
2. Register in the table above and in `references/index.md`.
