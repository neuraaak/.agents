# CI/CD Expert — References Index

Two routing axes: **forge** (where the pipeline runs) and **language** (what the jobs do). Always load `common/principles.md`, then dispatch to the sub-indexes below.

## Common (`common/`)

| File                   | Load when…       | Contents                                                                |
| :--------------------- | :--------------- | :---------------------------------------------------------------------- |
| `common/principles.md` | Every CI/CD task | Strategy, caching, secrets/OIDC, environments, deploy gates, audit list |

## Forge (`forge/`)

Platform-specific syntax and orchestration. See `forge/index.md` for full routing tables.

| Platform       | Detect via            | Sub-index       |
| :------------- | :-------------------- | :-------------- |
| GitHub Actions | `.github/workflows/*` | `forge/github/` |
| GitLab CI      | `.gitlab-ci.yml`      | `forge/gitlab/` |

Load `syntax.md` for any write/audit/debug task. Load `orchestration.md` only when the task touches releasing, publishing, tagging, or deploying docs.

## Languages (`languages/`)

Language-specific pipeline blueprints and tool catalogs. See `languages/index.md` for full routing tables.

| Language                | Detect via       | Sub-index               |
| :---------------------- | :--------------- | :---------------------- |
| Python                  | `pyproject.toml` | `languages/python/`     |
| JavaScript / TypeScript | `package.json`   | `languages/javascript/` |

Always load both `pipelines.md` and `tool-registry.md` for the detected language. Polyglot repo → load both language pairs.
