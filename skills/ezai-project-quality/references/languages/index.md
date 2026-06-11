# Project Quality — Languages Index

Route to the correct language subdirectory. For mixed repos, load both language files.

## Supported languages

| Language              | Detect via       | File                              |
| :-------------------- | :--------------- | :-------------------------------- |
| Python                | `pyproject.toml` | `languages/python/quality.md`     |
| JavaScript/TypeScript | `package.json`   | `languages/javascript/quality.md` |

## What each file owns

- **`python/quality.md`** — pytest, hypothesis, Pydantic validation, secret management, python-dotenv, bcrypt, structured logging.
- **`javascript/quality.md`** — node:test / Vitest, Zod validation, fast-check, secret management, Node.js permission model.

## Adding a new language

1. Create `<language>/` here with `quality.md`.
2. Register in the table above and in `references/index.md`.
