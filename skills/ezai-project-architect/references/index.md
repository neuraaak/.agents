# Project Architect — References Index

Two routing axes: **common** (always loaded) and **language**. See `languages/index.md` for the full routing table.

## Common (`common/`)

| File                     | Load when…              | Contents                                                         |
| :----------------------- | :---------------------- | :--------------------------------------------------------------- |
| `common/architecture.md` | Every architecture task | Composition, Ports & Adapters, Repository, feature-based modules |

## Languages (`languages/`)

| Language              | Sub-index               |
| :-------------------- | :---------------------- |
| Python                | `languages/python/`     |
| JavaScript/TypeScript | `languages/javascript/` |
| PHP                   | `languages/php/`        |

Load `languages/index.md` for the full routing table. For polyglot repos, load both language files.

## Frameworks (delta-only)

Framework files live under `languages/<lang>/frameworks/` and are **deltas** on
the language file — load them *in addition*, never instead of. Cascade:
`common → language → framework`.

| Framework | File                                       |
| :-------- | :----------------------------------------- |
| React     | `languages/javascript/frameworks/react.md` |
| FastAPI   | `languages/python/frameworks/fastapi.md`   |

If no framework is detected, or it has no delta file, stop at the language file.
