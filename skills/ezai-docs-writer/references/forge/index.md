# Forge Index

Routing for forge-specific references (the git hosting platform: GitHub,
GitLab, …). Currently scoped to **badges only** — badge URLs and CI shields
differ per forge. All paths are written from the `references/` root.

| Forge  | Subdirectory    | Detect via                             | Badge registry                   |
| :----- | :-------------- | :------------------------------------- | :------------------------------- |
| GitHub | `forge/github/` | `github.com` remote / `.github/`       | `forge/github/badge-registry.md` |
| GitLab | `forge/gitlab/` | `gitlab.com` remote / `.gitlab-ci.yml` | `forge/gitlab/badge-registry.md` |

When emitting a badge block, load the **pair**: the forge registry here +
the language registry under `languages/<lang>/badge-registry.md`.

---

- `forge/github/badge-registry.md` — core badges for GitHub projects (CI, Docs, License)
- `forge/gitlab/badge-registry.md` — core badges for GitLab projects (CI, Docs, License)

---

## Adding a new forge

1. Create a `forge/<name>/` subdirectory.
2. Add `badge-registry.md` with the forge-specific CI/Docs/License shields.
3. Register in the routing table above.
