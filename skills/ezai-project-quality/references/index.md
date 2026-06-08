# Project Quality — References Index

Route to the correct language subdirectory. Always load `common/quality.md` for cross-language principles.

## Common (`common/`)

| File                | Load when…         | Contents                                                                          |
| :------------------ | :----------------- | :-------------------------------------------------------------------------------- |
| `common/quality.md` | Every quality task | Boundary validation, secrets management, fakes vs mocks, coverage, property-based |

## Supported languages

| Language              | Subdirectory  | Available files |
| :-------------------- | :------------ | :-------------- |
| Python                | `python/`     | `quality.md`    |
| JavaScript/TypeScript | `javascript/` | `quality.md`    |

---

## Python (`python/`)

Stack: pytest, hypothesis, Pydantic, python-dotenv, bcrypt.

| File                | Load when…                                | Contents                                                                                            |
| :------------------ | :---------------------------------------- | :-------------------------------------------------------------------------------------------------- |
| `python/quality.md` | Any testing, security, or validation task | Test structure, parametrize, hypothesis, Pydantic validation, secret management, structured logging |

---

## JavaScript/TypeScript (`javascript/`)

Stack: node:test / Vitest, Zod, fast-check, dotenv.

| File                    | Load when…                                | Contents                                                                           |
| :---------------------- | :---------------------------------------- | :--------------------------------------------------------------------------------- |
| `javascript/quality.md` | Any testing, security, or validation task | node:test, Zod validation, fast-check, secret management, Node.js permission model |
