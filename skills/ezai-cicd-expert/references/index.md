# CI/CD Expert — References Index

Two routing axes: **platform** (where the pipeline runs) and **language** (what the jobs do). Always load `common/principles.md`, then the platform file(s) the task needs, then one language file.

Each platform is split into two files by task depth:

- **`syntax.md`** — the building blocks (triggers, jobs, matrix, caching, permissions, environments). Load for any pipeline write/audit/debug task.
- **`orchestration.md`** — release engineering (reusable workflows, auto-tag/tag cascades, publish, Pages deploy). Load only when the task touches release automation, publishing, or docs deployment.

## Platform routing

| Platform       | Detect via            | Building blocks    | Release automation        |
| :------------- | :-------------------- | :----------------- | :------------------------ |
| GitHub Actions | `.github/workflows/*` | `github/syntax.md` | `github/orchestration.md` |
| GitLab CI      | `.gitlab-ci.yml`      | `gitlab/syntax.md` | `gitlab/orchestration.md` |

Load `orchestration.md` only when the request mentions releasing, publishing, tagging, version bumps, or deploying docs — a plain CI pipeline (lint/test/build) needs only `syntax.md`.

## Language routing

| Language                | Detect via       | File                      |
| :---------------------- | :--------------- | :------------------------ |
| Python                  | `pyproject.toml` | `python/pipelines.md`     |
| JavaScript / TypeScript | `package.json`   | `javascript/pipelines.md` |

Polyglot repo → load both language files and both tool registries. The language file gives the **role sequence** and a worked example — it deliberately does **not** fix the toolchain; resolve each role to a command via the matching `tool-registry.md`.

## Common (`common/`)

| File                   | Load when…       | Contents                                                                |
| :--------------------- | :--------------- | :---------------------------------------------------------------------- |
| `common/principles.md` | Every CI/CD task | Strategy, caching, secrets/OIDC, environments, deploy gates, audit list |

## What each file owns

- **`common/principles.md`** — platform- and language-agnostic strategy: pipeline stages, caching theory, secret handling, environments, deploy gates, the audit checklist.
- **`github/syntax.md`** — GitHub Actions building blocks: triggers, jobs, matrix, `permissions`/OIDC, caching, pinning, concurrency, environments.
- **`github/orchestration.md`** — GitHub Actions release engineering: reusable/composite workflows, `workflow_call`, auto-tag→publish→docs cascade, Pages deploy (simple + mike).
- **`gitlab/syntax.md`** — GitLab CI building blocks: stages, `rules`, `needs`, caching, artifacts, OIDC (`id_tokens`), environments.
- **`gitlab/orchestration.md`** — GitLab CI release engineering: `include`, parent-child/multi-project pipelines, release flow, Pages deploy.
- **`python/pipelines.md`** — Python pipeline blueprint: role sequence and Python-specific concerns. Load alongside `python/tool-registry.md`.
- **`python/tool-registry.md`** — Python-only role→tool→command catalog (uv/poetry/pdm, ruff/mypy/ty, pytest, PyPI publish, mkdocs/sphinx). Detection signals included.
- **`javascript/pipelines.md`** — JS/TS pipeline blueprint: role sequence and JS/TS-specific concerns. Load alongside `javascript/tool-registry.md`.
- **`javascript/tool-registry.md`** — JS/TS-only role→tool→command catalog (pnpm/npm/yarn/bun, eslint/biome, tsc, vitest/jest, npm publish, vitepress/docusaurus). Detection signals included.

## Adding a new platform or language

1. Create `<platform>/` or `<language>/` here.
2. For a platform: add `syntax.md` + `orchestration.md`. For a language: add `pipelines.md` + `tool-registry.md`.
3. Register in the routing tables above.
