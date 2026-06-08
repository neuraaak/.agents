---
name: ezai-project-config
description:
  "Toolchain setup, project configuration, and infrastructure
  standards for Python and JS/TS projects. Covers pyproject.toml / package.json
  structure, build backends, linters, type checkers, Docker multi-stage builds,
  lockfiles, and observability setup. Load from ezai-persona-senior-dev, or invoke
  directly for setup tasks.

  Triggers on: 'set up the project', 'configure ruff/ty/uv', 'write a Dockerfile',
  'set up pre-commit', 'configure tsconfig', 'add OpenTelemetry', 'lockfile issue'."
---

Project toolchain, configuration, and infrastructure standards. Load the language file from the routing table below, then load `references/common/config.md` for cross-language infrastructure principles.

## Language routing

| Language                | File                              |
| :---------------------- | :-------------------------------- |
| Python                  | `references/python/config.md`     |
| JavaScript / TypeScript | `references/javascript/config.md` |

For monorepos using both, load both language files and apply each to its respective subdirectory. If a file is unavailable, notify the user with: "I could not locate [filename]. Please provide it or confirm the language."
