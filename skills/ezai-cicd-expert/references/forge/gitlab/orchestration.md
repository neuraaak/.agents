# GitLab CI — Release & Deploy Orchestration

The GitLab port of the numbered release cascade. Where GitHub chains many reusable workflow *files* via `needs`, GitLab uses **one root `.gitlab-ci.yml`** that **`include:`s** numbered sub-files, all flattened into **a single pipeline** ordered by `stages`. The `tag-sync → publish → docs` logic and the three-state `tag_action` (create/skip/preview) are identical in intent — only the wiring differs. This file owns the **VCS-level orchestration** only; per-role commands are placeholders, resolved via `languages/<language>/tool-registry.md`. For the building blocks (stages, rules, needs, caching, `id_tokens`), see `gitlab/syntax.md`. For the strategy, see `common/principles.md` → "Validation vs release".

> **Placeholders.** `‹install›`, `‹frozen-install›`, `‹lint›`, `‹test›`, `‹build›`, `‹publish›`, `‹docs-build›`, `‹lockfile›`, `‹version-file›`, `‹store-dir›`, `‹runner-image›` and `‹lang-setup›` stand for whatever the language tool-registry resolves. The GitLab keywords around them (`include`, `stages`, `rules`, `dotenv`, `cache:policy`, `id_tokens`) are the VCS-level substance of this file.

## GitHub ↔ GitLab structural map

| Concept             | GitHub Actions                           | GitLab CI                                                    |
| :------------------ | :--------------------------------------- | :----------------------------------------------------------- |
| Unit of reuse       | reusable workflow file (`workflow_call`) | `include: local:` fragment merged into one pipeline          |
| Cascade ordering    | `needs:` across workflow files           | `stages:` order (+ `needs:` for intra-stage DAG)             |
| Orchestrator        | `02-tag-sync.yml` calls `03`/`04`        | root `.gitlab-ci.yml` includes all sub-files                 |
| Per-job output gate | job `outputs` + `if:`                    | `dotenv` artifact var + `rules: if: $VAR`                    |
| Shared dep cache    | `00-install-deps` reusable workflow      | one `install` job, `cache: policy: pull-push`; others `pull` |
| Docs aliases        | versioned-docs tool (e.g. `mike`)        | directory layout under `public/` (no native alias mechanism) |

**`include:` vs `trigger:`.** Use `include: local:` (flatten into one pipeline — the default choice; stage order gives you the cascade). Reserve `trigger:` child pipelines for when you genuinely need isolation (separate pipeline graph, independent retry). The rule prefers the single-pipeline form: natural orchestration via stages.

## Root `.gitlab-ci.yml` — the orchestrator

```yaml
stages: [install, test, tag, publish, docs]

include:
  - local: .gitlab/ci/00-install.yml
  - local: .gitlab/ci/01-ci.yml
  - local: .gitlab/ci/02-tag-sync.yml
  - local: .gitlab/ci/03-publish.yml
  - local: .gitlab/ci/04-docs.yml

# Anti-double-pipeline: run for MRs and for branch pushes, but never both for the
# same change (GitHub's "no bare push trigger" equivalent).
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH

default:
  image: ‹runner-image›                # pin exact — never :latest
```

The numbered file names mirror the GitHub `00`–`04` scheme so a reader recognizes the same cascade across both forges.

## `00-install.yml` — shared cache primer

GitLab has no separate "reusable workflow" to prime a cache; instead one job warms a lockfile-keyed cache with `policy: pull-push`, and every later job declares the **same cache key** with `policy: pull` for a hit-only restore.

```yaml
# .gitlab/ci/00-install.yml
.dep-cache: &dep-cache               # YAML anchor reused by every job below
  key:
    files: [‹lockfile›]              # key on the lockfile hash — same lockfile → same cache
  paths: [‹store-dir›]

install:
  stage: install
  cache:
    <<: *dep-cache
    policy: pull-push                # this job *populates* the cache
  script:
    - ‹frozen-install›               # reproducible install (resolve via tool-registry)
```

Downstream jobs reuse `*dep-cache` with `policy: pull` (below) so they restore the warm store instead of re-downloading. Cache the **store**, not the resolved tree (`common/principles.md` → "Caching").

## `01-ci.yml` — parallel quality gate

Lint and the test matrix sit in the same `test` stage with no `needs` between them, so they run **in parallel**. `parallel:matrix` is GitLab's matrix.

```yaml
# .gitlab/ci/01-ci.yml
.with-deps: &with-deps
  cache:
    key:
      files: [‹lockfile›]
    paths: [‹store-dir›]
    policy: pull                     # hit-only — install job already populated it
  before_script:
    - ‹frozen-install›

lint:
  stage: test
  needs: [install]
  <<: *with-deps
  script: [‹lint›, ‹format-check›]

test:
  stage: test
  needs: [install]                   # parallel with lint — no gate between them
  <<: *with-deps
  parallel:
    matrix:
      - LANG_VERSION: ["<pinned>", "<floating-major>"]
  image: ‹runner-image:$LANG_VERSION›
  script: [‹test›]
```

## `02-tag-sync.yml` — runtime `tag_action`, exported via dotenv

This is the crux of the port. GitLab `rules:` are evaluated at **pipeline-creation** time, so they **cannot** run `git rev-parse` to test whether `vX.Y.Z` already exists. So the decision is a **runtime job** that determines `TAG_ACTION` and writes it to a **`dotenv` report artifact**; downstream jobs `needs:` this job and gate on `$TAG_ACTION` in their `rules:`.

```yaml
# .gitlab/ci/02-tag-sync.yml
tag-sync:
  stage: tag
  needs: [lint, test]                # release gate — never publish a red commit
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"   # branch/MR → preview path
    - if: $CI_COMMIT_BRANCH == "main"                     # main → create-or-skip path
  script:
    - VERSION="$(‹read version from ‹version-file››)"     # language-specific one-liner
    - TAG_NAME="v$VERSION"; MAJOR="${VERSION%%.*}"
    - |
      if [ "$CI_COMMIT_BRANCH" != "main" ]; then
        TAG_ACTION=preview                                # off main → dry-run, never tag
      elif git rev-parse -q --verify "refs/tags/$TAG_NAME" >/dev/null; then
        TAG_ACTION=skip                                   # tag exists → no release
      else
        TAG_ACTION=create                                 # new version → release
      fi
    - |
      if [ "$TAG_ACTION" = "create" ]; then
        git config user.name  "gitlab-ci"
        git config user.email "ci@$CI_SERVER_HOST"
        git remote set-url origin "https://oauth2:${CI_PUSH_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"
        git tag "$TAG_NAME"                               # NEVER -f: release tag is immutable
        git push origin "$TAG_NAME"
        git tag -f "v${MAJOR}-latest"                     # only the alias moves
        git push origin --force "v${MAJOR}-latest"
      fi
    # export for downstream rules + scripts
    - echo "TAG_ACTION=$TAG_ACTION" >> tag.env
    - echo "VERSION=$VERSION"       >> tag.env
    - echo "TAG_NAME=$TAG_NAME"     >> tag.env
  artifacts:
    reports:
      dotenv: tag.env
```

`TAG_ACTION` maps onto the two-mode model exactly as on GitHub:

| `TAG_ACTION` | When                               | Tag                           | publish (03)               | docs (04)                  |
| :----------- | :--------------------------------- | :---------------------------- | :------------------------- | :------------------------- |
| `create`     | `main`, `vX.Y.Z` doesn't exist yet | create `vX.Y.Z` + `vX-latest` | upload (OIDC)              | publish `X.Y.Z` + `latest` |
| `skip`       | `main`, `vX.Y.Z` already exists    | none                          | **not run**                | publish `dev/`             |
| `preview`    | MR / non-`main` branch             | none ever                     | build + package, no upload | build only, no publish     |

> **Token note.** Pushing a tag from CI needs write scope beyond the default `CI_JOB_TOKEN` (read-only for repo writes). Use a **Project Access Token** / CI/CD variable (`CI_PUSH_TOKEN`) with `write_repository`, masked and protected. There is no `GITHUB_TOKEN`-style loop-protection problem here because the tag push does **not** start a second pipeline you depend on — the same pipeline continues through its stages.

## `03-publish.yml` — build always, upload on `create`

Every mutating step keys on `$TAG_ACTION`. The build/package/publish commands and the existence-check resolve via the language tool-registry — the **gating** is VCS-level.

```yaml
# .gitlab/ci/03-publish.yml
publish:
  stage: publish
  needs: [tag-sync]                  # inherits $TAG_ACTION / $VERSION from the dotenv artifact
  rules:
    - if: $TAG_ACTION == "create"
      when: on_success
    - if: $TAG_ACTION == "preview"   # dry-run: package only, no upload
      when: on_success
      variables: { PUBLISH_DRY_RUN: "true" }
    # $TAG_ACTION == "skip" → no matching rule → job not created
  id_tokens:
    REGISTRY_ID_TOKEN: { aud: ‹registry-audience› }   # OIDC — no stored token
  environment:
    name: <registry>                 # protected environment + Trusted Publisher match
  script:
    - ‹frozen-install›
    - ‹package --dry-run›            # always validate the publishable set
    - '[ "$PUBLISH_DRY_RUN" = "true" ] && { echo "preview — packaged only"; exit 0; } || true'
    - ‹registry existence check $VERSION → exit 0 if already present›   # replay-safe
    - ‹publish --provenance›
```

> GitLab also has a native `release:` keyword (`release-cli`) to attach notes/assets to a tag — use it instead of hand-rolling release creation. OIDC `aud` and the publish command resolve per language (npm registry / PyPI) via the tool-registry.

## `04-docs.yml` — Pages, by directory layout

GitLab Pages has no alias mechanism — `latest`/`dev`/`X.Y.Z` are **subdirectories of `public/`**. The job must be named `pages` and the `publish → docs` order is preserved by the stage sequence (publish runs first; it's irreversible, the site isn't).

```yaml
# .gitlab/ci/04-docs.yml
build-docs:                          # always builds (validation included)
  stage: docs
  needs: [tag-sync]
  cache:
    key: { files: [‹lockfile›] }
    paths: [‹store-dir›]
    policy: pull
  script:
    - ‹frozen-install›
    - ‹docs-build›                   # → ‹built-site-dir›
  artifacts:
    paths: [‹built-site-dir›]

pages:
  stage: docs
  needs: [build-docs]
  rules:
    - if: $TAG_ACTION == "create"    # versioned release: publish X.Y.Z + refresh latest/
    - if: $TAG_ACTION == "skip"      # main between releases: refresh dev/
    # preview → no matching rule → no deploy (build-docs already validated the build)
  script:
    - mkdir -p public
    - |
      if [ "$TAG_ACTION" = "create" ]; then
        rm -rf "public/$VERSION" public/latest
        cp -r ‹built-site-dir› "public/$VERSION"
        cp -r ‹built-site-dir› public/latest      # 'latest' = newest release
      else  # skip
        rm -rf public/dev
        cp -r ‹built-site-dir› public/dev         # unreleased main content
      fi
  artifacts:
    paths: [public]
```

The three modes mirror the GitHub versioned-docs steps: `create` → `public/X.Y.Z` + `public/latest`; `skip` → `public/dev`; `preview` → build only, no `pages` job. Re-deploying a version overwrites its own subfolder only → idempotent. (GitLab Pages republishes the whole `public/` artifact each run; if you need to preserve sibling version folders, fetch the previously published site into `public/` before overwriting the target subfolder.)

## Carry-over rules (unchanged from GitHub)

- **Release tag is immutable.** `vX.Y.Z` is tagged once, never force-pushed; only the `vX-latest` alias moves.
- **Always build, conditionally deliver.** `build-docs` and the package/build steps run on every path; only `create` uploads or publishes versioned docs.
- **Order: publish → docs.** Guaranteed by stage sequence (`publish` before `docs`).
- **Replay-safe.** Publish treats "already present" as success; Pages overwrites a subfolder → idempotent.
- **Pin everything.** External `include:` fragments and project templates get a pinned `ref:`; runner images pinned to exact tags, never `:latest`.
- **Least privilege + OIDC.** Prefer `id_tokens` trusted publishing over a long-lived registry token; scope the tag-push token to `write_repository`, masked and protected.
