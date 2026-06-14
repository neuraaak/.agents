---
name: ezai-project-config
description: >
  Toolchain setup, project configuration, and infrastructure standards for Python
  and JS/TS projects. Covers pyproject.toml / package.json structure, build backends,
  linters, type checkers, Docker multi-stage builds, lockfiles, env vars, and
  observability setup.

  Load from ezai-senior-dev-persona or directly for any config task.

  Triggers on: "set up the project", "configure ruff/ty/uv", "write a Dockerfile",
  "set up pre-commit", "configure tsconfig", "add OpenTelemetry", "lockfile issue",
  "configure eslint", "monorepo setup", "env vars", "environment variable",
  "pyproject.toml", "package.json", "configure the project".
---

Toolchain, configuration, and project infrastructure. Follows a 3-step workflow: identify the language and task type, load the matching language file, then apply the standards with complete config.

## Local rules precedence

Any rule declared in the user's `.claude/` (rules files, CLAUDE.md) takes
precedence over this skill. When a local rule covers the same domain, apply it
**in addition and in priority** over the defaults described here. This skill
ships only the general default; context-specific overrides live in the user's
rules.

## Capabilities

| Key                            | Description                                                           |
| :----------------------------- | :-------------------------------------------------------------------- |
| `pyproject-toml-structure`     | Initialize or audit a Python project's pyproject.toml                 |
| `package-json-structure`       | Initialize or audit a JS/TS project's package.json                    |
| `linting-formatting-typecheck` | Configure ruff, ty (Python) or ESLint, tsc (JS/TS)                    |
| `docker-multistage`            | Write a production-ready multi-stage Dockerfile for Python or Node.js |
| `lockfile-reproducibility`     | Set up uv.lock, pnpm-lock.yaml, and deterministic CI installs         |
| `env-vars-secrets`             | Configure .env, vault patterns, and secure secret handling            |
| `observability-opentelemetry`  | Add OpenTelemetry structured logs and traces                          |
| `monorepo-tooling`             | Set up uv (Python) or pnpm workspaces (JS/TS)                         |
| `pre-commit-setup`             | Configure pre-commit hooks with lint-staged or husky                  |

## Workflow

1. **Identify** — detected language(s) (`pyproject.toml` → Python, `package.json` → JS/TS) + task type (init / audit / Docker / CI)
2. **Load** — the language file below + `references/common/config.md` (cross-cutting principles)
3. **Apply** — complete config with verifiable success criteria

## Language routing

| Language                | File                                        |
| :---------------------- | :------------------------------------------ |
| Python                  | `references/languages/python/config.md`     |
| JavaScript / TypeScript | `references/languages/javascript/config.md` |

For monorepos spanning both languages, load both files and apply each to its respective subdirectory. If a file is inaccessible, notify the user and fall back to `references/common/config.md`.

## Output format

- **Config files**: complete copy-paste-ready blocks, with commented sections
- **Tool choice**: comparison table when several options are valid
- **Success criteria**: verifiable checklist at the end of the response
- **Secrets**: always flag if a config exposes sensitive values
