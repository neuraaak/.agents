# Project Config — References Index

Route to the correct language subdirectory. Always load `common/config.md` for cross-language infrastructure principles.

## Common (`common/`)

| File               | Load when…                  | Contents                                                                    |
| :----------------- | :-------------------------- | :-------------------------------------------------------------------------- |
| `common/config.md` | Every config/toolchain task | Lockfiles, Docker multi-stage, Observability, health checks, no latest tags |

## Supported languages

| Language              | Subdirectory  | Available files |
| :-------------------- | :------------ | :-------------- |
| Python                | `python/`     | `config.md`     |
| JavaScript/TypeScript | `javascript/` | `config.md`     |

---

## Python (`python/`)

Stack: uv, ruff, ty, hatchling, pyproject.toml, Docker multi-stage.

| File               | Load when…                                                      | Contents                                                                                              |
| :----------------- | :-------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------- |
| `python/config.md` | Toolchain setup, project config, Docker, or foundational syntax | uv commands, pyproject.toml structure, ruff/ty config, 3.11+ syntax rules, Docker multi-stage pattern |

---

## JavaScript/TypeScript (`javascript/`)

Stack: pnpm, TypeScript 6.0+, ESM, Node.js 24+, Docker multi-stage.

| File                   | Load when…                                                | Contents                                                                                                    |
| :--------------------- | :-------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------- |
| `javascript/config.md` | Toolchain setup, project config, Docker, or ES2026 syntax | package.json, tsconfig.json, ES2026 features (Temporal, `using`, Array by Copy), Docker multi-stage pattern |
