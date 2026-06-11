## CI/CD Pipeline — Reference Rules

Target: versioned libraries/packages (Python `pyproject.toml`, JS `package.json`),
published to a registry, documented with versioned docs.

---

### Philosophy: two modes, one set of jobs

The pipeline reasons by **lifecycle moment**, not by tool. Everything reduces to two modes driven by a single question: _does the version in the file differ from the last tag?_

- **Validation mode** — PRs and feature branches. Everything is dry-run: execute, build, verify — **nothing mutates the world** (no real tag, no upload, no deploy).
- **Release mode** — push to `main` **with** a version change. Strictly sequential and mutating: tag → publish → docs.

---

### Global flow

Sequential **between** workflows (control and dependency order), parallel **only inside** CI.

```
CI (lint ∥ typecheck ∥ tests) → tag-sync → publish → docs
```

Each stage `needs` the previous one. CI is a reusable workflow called by both the PR path (validation) and the release path (gate).

---

### Workflow details

**CI**

- Internal parallelism: `lint`, `typecheck`, `tests` run as independent jobs. Dependencies cached so parallel jobs don't repeat the full install.
- Triggers: all branches + PRs. To avoid double-runs: `push` limited to `main`, `pull_request` for the rest.
- Gate role: marked as _required status check_ (GitHub branch protection / GitLab MR rules). The workflow running alone doesn't block — the branch protection setting does.

**tag-sync**

- Does NOT bump the version (the human writes it in the file). It **syncs a tag to the file version**.
- On `main`: compare file-version vs last tag.
  - Version changed → **create** immutable tag `vX.Y.Z` + move floating alias `vX-latest`.
  - Version unchanged → **skip** (no tag created, no release).
- On PR / branch: no real tag; generates a `tag_preview` flag so downstream steps run the same path without overwriting any ref.
- **Immutability rule**: `vX.Y.Z` is never moved. The floating pointer lives in a **separate ref** (`vX-latest`), not on the release tag.

**publish**

- Build always (validation), upload conditionally.
  - New `vX.Y.Z` created → build + **upload** (OIDC / trusted publishing, no long-lived secret).
  - Otherwise (skip or preview) → build only, no upload.
- **Re-run safe**: treat "version already present" as success (`twine upload --skip-existing` for Python; existence check before `npm publish` for JS).

**docs**

- Build always (validation, including on PRs), deploy conditionally.
- On release: deploy version `X.Y.Z` and move alias `latest` to it. This deploy **depends on publish success** (a `vX.Y.Z` doc without a matching package = broken promise).
- `latest` alias = last _release_ (not main).
- **Idempotent**: re-deploying a version just overwrites its subfolder → freely replayable.
- Order **publish → docs**: publish is irreversible, docs are not.
- Optional `dev` alias: doc built from `main` on each push to expose unreleased content. Decoupled from publish.

---

### Decision table

| Context                        | CI         | tag-sync                               | publish                            | docs                                          |
| ------------------------------ | ---------- | -------------------------------------- | ---------------------------------- | --------------------------------------------- |
| PR / feature branch            | run — gate | no real tag → `tag_preview` flag       | build only, **no upload**          | build only, **no deploy**                     |
| Push `main`, version unchanged | run        | **skip**                               | build only, no upload              | no release deploy; deploys `dev` _if enabled_ |
| Push `main`, version changed   | run        | **create** `vX.Y.Z` + move `vX-latest` | build + **upload** (OIDC)          | deploy `X.Y.Z` + **update `latest`**          |
| Re-run of a release            | run        | tag exists → **no-op**                 | upload **skip-existing** = success | re-deploy (**idempotent**)                    |

---

### Golden rules

1. **Release tag is immutable.** The moving pointer lives in a separate alias (`vX-latest`, `latest`).
2. **Always build, conditionally deliver.** Build package and docs on every path (validation); only publish/deploy on release.
3. **Never publish a red commit.** tag/publish is gated on green CI.
4. **Publish re-run safe**, docs **idempotent** → a partial failure can be replayed.
5. **Order: publish → docs** — publish is irreversible, docs are not.
6. **Required check ≠ running workflow**: merge blocking is a branch protection setting, not a workflow property.

---

### GitHub vs GitLab specifics

| Aspect              | GitHub Actions                                                                                                           | GitLab CI                                                                                                               |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------- |
| Structure           | Multiple workflows chained via `workflow_call` (reusable)                                                                | One pipeline = sequential `stages`, parallel jobs inside                                                                |
| Chaining            | `needs` + reusable workflows                                                                                             | `stages` + `rules:` (`$CI_COMMIT_TAG`, `$CI_COMMIT_BRANCH`, `$CI_PIPELINE_SOURCE`)                                      |
| Tag trigger pitfall | Tag created by `GITHUB_TOKEN` **does not trigger** another workflow → direct call of publish/docs (not `on: push: tags`) | Same protection; natural orchestration via stages in a single pipeline                                                  |
| Versioned docs      | mike pushes to a branch (`gh-pages`) served by Pages                                                                     | GitLab Pages serves `public/` from a job → must **assemble versions in `public/`** or serve the mike branch differently |

**Maintainability**: keep logic (tag script, doc build, publish step) in **scripts** / task runner (`nox`, `tox`, `just`, `make`) called by both systems. YAML stays a thin orchestration layer → no drift between GitHub and GitLab.

---

### Key snippets

**Avoid double-runs (GitHub)**

```yaml
on:
  push:
    branches: [main]
  pull_request:
```

**Concurrency — cancel stale runs on PR, never on main**

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

**Anti-double-pipeline (GitLab)**

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH
```

**Versioned docs deploy (mike)**

```bash
# on release (create)
mike deploy --push --update-aliases X.Y.Z latest
mike set-default --push latest   # once only: root → latest

# dev docs (optional, on push to main)
mike deploy --push dev
```
