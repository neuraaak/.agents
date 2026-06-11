# Project Config — References Index

Two routing axes: **common** (always loaded) and **language**. See `languages/index.md` for the full routing table.

## Common (`common/`)

| File               | Load when…                  | Contents                                                                    |
| :----------------- | :-------------------------- | :-------------------------------------------------------------------------- |
| `common/config.md` | Every config/toolchain task | Lockfiles, Docker multi-stage, Observability, health checks, no latest tags |

## Languages (`languages/`)

| Language              | Sub-index               |
| :-------------------- | :---------------------- |
| Python                | `languages/python/`     |
| JavaScript/TypeScript | `languages/javascript/` |

Load `languages/index.md` for the full routing table. For monorepos using both, load both language files.
