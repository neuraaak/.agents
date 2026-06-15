# CI/CD Expert — Forge Index

Route by the platform where the pipeline runs. Each platform is split into two files by task depth:

- **`syntax.md`** — building blocks (triggers, jobs, matrix, caching, permissions, environments). Load for any pipeline write/audit/debug task.
- **`orchestration.md`** — release engineering (reusable workflows, tag-sync/tag cascades, publish, Pages deploy). Load only when the task touches releasing, publishing, tagging, or deploying docs.

## Platform routing

| Platform       | Detect via            | Building blocks          | Release automation              |
| :------------- | :-------------------- | :----------------------- | :------------------------------ |
| GitHub Actions | `.github/workflows/*` | `forge/github/syntax.md` | `forge/github/orchestration.md` |
| GitLab CI      | `.gitlab-ci.yml`      | `forge/gitlab/syntax.md` | `forge/gitlab/orchestration.md` |

## What each file owns

- **`github/syntax.md`** — GitHub Actions building blocks: triggers, jobs, matrix, `permissions`/OIDC, caching, pinning, concurrency, environments.
- **`github/orchestration.md`** — GitHub Actions release engineering: numbered reusable workflows (`00`–`04`), shared cache primer, `workflow_call`, the tag-sync→publish→docs cascade driven by a three-state `tag_action` (create/skip/preview), Pages deploy (simple + versioned). Role commands deferred to `languages/`.
- **`gitlab/syntax.md`** — GitLab CI building blocks: stages, `rules`, `needs`, caching, artifacts, OIDC (`id_tokens`), environments.
- **`gitlab/orchestration.md`** — GitLab CI release engineering: root `.gitlab-ci.yml` that `include:`s numbered sub-files (`00`–`04`) into one staged pipeline, shared cache primer, runtime `tag_action` (create/skip/preview) via dotenv-exported var, OIDC publish, Pages by directory layout. Mirrors the GitHub cascade.

## Adding a new forge platform

1. Create `<platform>/` here with `syntax.md` + `orchestration.md`.
2. Register in the routing table above and in `references/index.md`.
