# CI/CD Expert — Forge Index

Route by the platform where the pipeline runs. Each platform is split into two files by task depth:

- **`syntax.md`** — building blocks (triggers, jobs, matrix, caching, permissions, environments). Load for any pipeline write/audit/debug task.
- **`orchestration.md`** — release engineering (reusable workflows, auto-tag/tag cascades, publish, Pages deploy). Load only when the task touches releasing, publishing, tagging, or deploying docs.

## Platform routing

| Platform       | Detect via            | Building blocks          | Release automation              |
| :------------- | :-------------------- | :----------------------- | :------------------------------ |
| GitHub Actions | `.github/workflows/*` | `forge/github/syntax.md` | `forge/github/orchestration.md` |
| GitLab CI      | `.gitlab-ci.yml`      | `forge/gitlab/syntax.md` | `forge/gitlab/orchestration.md` |

## What each file owns

- **`github/syntax.md`** — GitHub Actions building blocks: triggers, jobs, matrix, `permissions`/OIDC, caching, pinning, concurrency, environments.
- **`github/orchestration.md`** — GitHub Actions release engineering: reusable/composite workflows, `workflow_call`, auto-tag→publish→docs cascade, Pages deploy (simple + mike).
- **`gitlab/syntax.md`** — GitLab CI building blocks: stages, `rules`, `needs`, caching, artifacts, OIDC (`id_tokens`), environments.
- **`gitlab/orchestration.md`** — GitLab CI release engineering: `include`, parent-child/multi-project pipelines, release flow, Pages deploy.

## Adding a new forge platform

1. Create `<platform>/` here with `syntax.md` + `orchestration.md`.
2. Register in the routing table above and in `references/index.md`.
