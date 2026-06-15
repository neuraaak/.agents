# GitHub Actions — Release & Deploy Orchestration

Multi-workflow patterns for release engineering: numbered reusable workflows, a shared dependency-cache primer, the `tag-sync → publish → docs` cascade driven by a three-state `tag_action`, and Pages deployment. This file owns the **VCS-level orchestration** only — the per-role commands (`install`, `lint`, `test`, `build`, `publish`, `docs-build`) are placeholders here; resolve each to a concrete command via `languages/<language>/tool-registry.md`. For the building blocks (triggers, jobs, matrix, caching), see `github/syntax.md`. For the strategy, see `common/principles.md` → "Validation vs release".

> **Placeholders.** `‹install›`, `‹frozen-install›`, `‹lint›`, `‹test›`, `‹build›`, `‹publish›`, `‹docs-build›`, `‹lockfile›`, `‹version-file›` and `‹lang-setup›` (the setup action + cache, e.g. `setup-node`/`setup-uv`) stand for whatever the language tool-registry resolves. Runner images (`ubuntu-24.04`) and action SHAs are VCS-level and stay concrete.

## Numbered reusable-workflow architecture

Split the pipeline into small **reusable workflows** (`on: workflow_call`), one responsibility each, and number them by dependency order. The number is documentation: a reader sees the cascade at a glance, and the prefix sorts them in the file tree.

```text
00-install-deps   ← primes the dependency-store cache (no logic, just a warm cache)
01-ci             ← lint ∥ test matrix; the quality gate. Called by PRs and by 02.
02-tag-sync       ← orchestrator: CI gate → tag-sync → triggers 03 then 04
03-publish        ← build always, upload only on a real release (OIDC)
04-docs           ← build always, deploy versioned/dev/none by mode
```

| #    | Workflow       | Triggers                                  | Role                                                     |
| :--- | :------------- | :---------------------------------------- | :------------------------------------------------------- |
| 00   | `install-deps` | `workflow_call`                           | Prime the lockfile-keyed store cache for every caller    |
| 01   | `ci`           | `pull_request`, `workflow_call`, dispatch | Lint ∥ tests; release gate (called by 02 on `main`)      |
| 02   | `tag-sync`     | `push: main`, `workflow_dispatch`         | Decide `tag_action`, tag on release, cascade to 03 → 04  |
| 03   | `publish`      | `workflow_call`, `workflow_dispatch`      | Build + package always; upload on `create` only          |
| 04   | `docs`         | `pull_request`, `workflow_call`, dispatch | Build always; deploy `latest`/`dev`/none by `tag_action` |

**Why a single orchestrator (`02`) instead of `on: push: tags`.** A tag pushed by `GITHUB_TOKEN` does **not** trigger another workflow (loop protection). So `02-tag-sync` calls `03` and `04` directly via `uses:` rather than relying on a tag-push event that would never fire.

**No bare `push` trigger on `01-ci`.** PRs cover feature branches; on `main`, CI runs as the release gate via `workflow_call` from `02`. One CI run per change — no double-runs. Same for `04-docs` (PR validation builds + release deploys, never both for one change).

## `00-install-deps` — shared cache primer

A logic-free reusable workflow whose only job is to populate the dependency-store cache, keyed on the lockfile hash. Every downstream job that then runs `‹lang-setup›` with the same cache key gets a hit instead of a network download.

```yaml
# 00-install-deps.yml
on:
  workflow_call:
    inputs:
      lang-version: { required: false, type: string, default: "<pinned>" }

permissions: {}

jobs:
  install:
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha>
      - uses: ‹lang-setup›          # setup-node / setup-uv …, cache keyed on ‹lockfile›
      - run: ‹frozen-install›        # reproducible install (resolve via tool-registry)
```

Callers `needs: [install-deps]`, then repeat `‹lang-setup›` + `‹frozen-install›`. The second install is a near-instant cache hit. Cache the **store** (not the resolved tree like `node_modules`/`.venv`) so the warm cache stays valid across jobs and runners (`common/principles.md` → "Caching").

## `01-ci` — parallel quality gate

Internal parallelism: the `lint`/format job and the `test` matrix are independent and both only `needs: [install-deps]`, so they run concurrently off the warm cache.

```yaml
# 01-ci.yml (abbreviated)
on:
  pull_request:
    paths: ["<source globs>", "‹version-file›", "‹lockfile›", ".github/workflows/01-ci.yml"]
  workflow_call:                      # called by 02-tag-sync as the release gate
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}   # cancel stale PR runs; never on main

jobs:
  install-deps:
    uses: ./.github/workflows/00-install-deps.yml

  quality:
    needs: [install-deps]
    runs-on: ubuntu-24.04
    steps: [ checkout, ‹lang-setup›, ‹frozen-install›, ‹lint›, ‹format-check› ]

  test:
    needs: [install-deps]             # parallel with quality — no gate between them
    runs-on: ubuntu-24.04
    strategy:
      fail-fast: false
      matrix: { version: ["<pinned>", "<floating-major>"] }   # language-version matrix
    steps: [ checkout, ‹lang-setup (matrix.version)›, ‹frozen-install›, ‹test›, coverage-on-pinned-cell ]
```

## `02-tag-sync` — orchestrator with three-state `tag_action`

`tag-sync` does **not** bump the version — the human writes it in `‹version-file›`. The workflow decides what to do from one signal, `tag_action`, which refines the two-mode model (`common/principles.md`) into three concrete branches:

| `tag_action` | When                                        | Tag                           | Publish (03)               | Docs (04)                 |
| :----------- | :------------------------------------------ | :---------------------------- | :------------------------- | :------------------------ |
| `create`     | push to `main`, `vX.Y.Z` doesn't exist yet  | create `vX.Y.Z` + `vX-latest` | upload (OIDC)              | deploy `X.Y.Z` + `latest` |
| `skip`       | push to `main`, `vX.Y.Z` already exists     | none                          | **not called**             | deploy `dev` alias        |
| `preview`    | `workflow_dispatch` off a non-`main` branch | none ever                     | build + package, no upload | build only, no push       |

`create` is **release mode**; `skip` and `preview` are both **validation mode** (nothing mutating gets uploaded). `preview` exercises the whole job graph end-to-end from a branch — proving the pipeline is healthy before it ever runs for real on `main`. `skip` keeps `main` visible between releases via the `dev` docs alias.

```yaml
# 02-tag-sync.yml (abbreviated)
on:
  push: { branches: [main] }
  workflow_dispatch:                  # run from any branch to exercise preview mode

permissions:
  contents: read

concurrency:
  group: tag-sync-${{ github.ref }}
  cancel-in-progress: false           # never interrupt an in-flight release

jobs:
  ci:                                 # release gate — never publish a red commit
    uses: ./.github/workflows/01-ci.yml

  tag-sync:
    needs: ci
    runs-on: ubuntu-24.04
    permissions:
      contents: write                 # push tags
    outputs:
      tag_action: ${{ steps.gate.outputs.tag_action }}   # create | skip | preview
      version: ${{ steps.version.outputs.version }}
      tag_name: ${{ steps.gate.outputs.tag_name }}
    steps:
      - uses: actions/checkout@<sha>
        with: { fetch-depth: 0 }      # full history: need every tag
      # ... read VERSION from ‹version-file› into steps.version (language-specific one-liner) ...
      - name: Determine tag action
        id: gate
        run: |
          TAG_NAME="v${{ steps.version.outputs.version }}"
          echo "tag_name=$TAG_NAME" >> "$GITHUB_OUTPUT"
          if [ "${{ github.ref }}" != "refs/heads/main" ]; then
            echo "tag_action=preview" >> "$GITHUB_OUTPUT"          # off main → dry-run
          elif git rev-parse -q --verify "refs/tags/$TAG_NAME" >/dev/null; then
            echo "tag_action=skip" >> "$GITHUB_OUTPUT"             # exists → no release
          else
            echo "tag_action=create" >> "$GITHUB_OUTPUT"          # new version → release
          fi
      - name: Create immutable tag + move floating alias
        if: steps.gate.outputs.tag_action == 'create'
        run: |
          VERSION="${{ steps.version.outputs.version }}"; MAJOR="${VERSION%%.*}"
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git tag "v$VERSION"                       # NEVER -f: the release tag is immutable
          git push origin "v$VERSION"
          git tag -f "v${MAJOR}-latest"             # only the alias ever moves
          git push origin --force "v${MAJOR}-latest"

  # publish is irreversible → runs before docs on create (golden rule: publish → docs).
  trigger-publish:
    needs: tag-sync
    if: needs.tag-sync.outputs.tag_action != 'skip'   # skip = already published earlier
    permissions:
      contents: read
      id-token: write                 # OIDC for trusted publishing — no secrets: inherit
    uses: ./.github/workflows/03-publish.yml
    with:
      version:    ${{ needs.tag-sync.outputs.version }}
      tag:        ${{ needs.tag-sync.outputs.tag_name }}
      tag_action: ${{ needs.tag-sync.outputs.tag_action }}

  trigger-deploy-docs:
    needs: [tag-sync, trigger-publish]
    if: |
      always() &&
      needs.tag-sync.result == 'success' &&
      ( needs.tag-sync.outputs.tag_action == 'skip' ||
        needs.tag-sync.outputs.tag_action == 'preview' ||
        needs.trigger-publish.result == 'success' )
    permissions:
      contents: write                 # versioned-docs tool pushes to the docs branch
      pages: write
      id-token: write
    uses: ./.github/workflows/04-docs.yml
    with:
      version:    ${{ needs.tag-sync.outputs.version }}
      tag_action: ${{ needs.tag-sync.outputs.tag_action }}
```

**Docs gating subtlety.** `trigger-deploy-docs` uses `always()` because `skip`/`preview` deliberately do **not** run publish, so the job must not inherit `trigger-publish`'s `skipped` result as a failure. The explicit `if` re-encodes the intent: deploy when tag-sync succeeded **and** either we're on a non-publish path (`skip`/`preview`) **or** publish actually succeeded (`create`). This preserves **publish → docs** ordering on release while letting the other two modes proceed independently.

**Immutability.** `vX.Y.Z` is created **once, never force-pushed** — replaying `02` on the same version yields `tag_action=skip` (the gate finds the tag). Only `vX-latest` is force-pushed: a moving major-alias is *meant* to move (`common/principles.md`).

**No `secrets: inherit`.** The cascade passes typed `with:` inputs only and relies on **OIDC** (`id-token: write`) for publishing. `secrets: inherit` hands *all* repo secrets to the called workflow — avoid it; with trusted publishing there's no token to pass anyway.

## `03-publish` — build always, upload on `create`

The called publish workflow keys every mutating step on `tag_action`. On `preview` it builds and packages only (dry-run resilience check); on `create` it uploads via OIDC. It is never called on `skip`. The actual build/package/publish commands and the existence-check come from the language tool-registry — the **gating** is VCS-level:

```yaml
# 03-publish.yml (publish job, abbreviated)
on:
  workflow_call:
    inputs:
      version:    { required: true, type: string }
      tag:        { required: true, type: string }
      tag_action: { required: true, type: string }   # create | preview
  workflow_dispatch:                                  # manual run behaves like create

jobs:
  validate:                          # ‹lint› + ‹test› + ‹package --dry-run› (runs on every mode)
    ...
  publish:
    needs: validate
    if: inputs.tag_action == 'create' || github.event_name == 'workflow_dispatch'
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      id-token: write                # mint OIDC token for Trusted Publishing
    environment:
      name: <registry>               # protected environment; also what the Trusted Publisher matches
    steps:
      - uses: actions/checkout@<sha>
      - uses: ‹lang-setup (with registry config)›
      - name: Skip if already published   # re-run safe — replay doesn't conflict
        id: published
        run: ‹registry existence check → exists=true|false›
      - if: steps.published.outputs.exists == 'false'
        run: ‹publish --provenance›    # resolve via tool-registry (npm publish / twine / uv publish)
```

**Trusted Publishing + reusable workflows.** When `03` is invoked via `workflow_call` from `02`, the npm/PyPI Trusted Publisher must be registered against **the file that contains the publish job** (`03-publish.yml`) and its `environment` — not the caller. Renaming the workflow file or environment breaks the OIDC match and the registry rejects the upload (npm returns a misleading **404** on `PUT`). Re-register the Trusted Publisher after any rename.

## `04-docs` — build always, deploy by mode

Docs mirror publish: build on every path (PR validation included), deploy conditionally on `tag_action`. The `‹docs-build›` command and the versioned-docs tool come from the language tool-registry (e.g. `mike` for MkDocs); the **deploy mechanics and gating** are VCS-level.

```yaml
# 04-docs.yml (deploy job, abbreviated — versioned docs)
on:
  pull_request:
    paths: ["docs/**", "‹version-file›", "‹lockfile›"]
  workflow_dispatch:
  workflow_call:
    inputs:
      version:    { required: false, type: string }
      tag_action: { required: false, type: string, default: "preview" }

jobs:
  build:                             # ‹docs-build› + upload-pages-artifact (every path)
    ...
  deploy:
    needs: build
    if: github.event_name != 'pull_request'    # PRs only validate the build
    permissions:
      contents: write                # versioned-docs tool pushes to the docs branch
      pages: write
      id-token: write
    environment: { name: github-pages, url: "${{ steps.deployment.outputs.page_url }}" }
    concurrency:
      group: pages
      cancel-in-progress: false      # never interrupt a live Pages deploy
    steps:
      - uses: actions/checkout@<sha>
        with: { fetch-depth: 0 }     # versioned-docs tool needs full history
      - name: Deploy (create — versioned release)
        if: inputs.tag_action == 'create'
        run: ‹docs-deploy version=$VERSION + move 'latest' alias›
      - name: Deploy (skip — dev alias for main between releases)
        if: inputs.tag_action == 'skip'
        run: ‹docs-deploy dev alias›
      - name: Deploy (preview — local build check, no push)
        if: inputs.tag_action == 'preview' || inputs.tag_action == ''
        run: ‹docs-deploy without push›   # validates the versioning config without touching the docs branch
      - id: deployment
        if: inputs.tag_action == 'create' || inputs.tag_action == 'skip'
        uses: actions/deploy-pages@<sha>
```

The three deploy steps are mutually exclusive on `tag_action`: **`create`** moves the `latest` alias to the new release (publish already succeeded upstream); **`skip`** refreshes the `dev` alias without touching any release version; **`preview`** runs the deploy command **without pushing** to validate the versioning config only.

## Reusable & composite workflows — the two tools

- **Reusable workflow** (`on: workflow_call`) — a whole callable job graph with typed `inputs`/`secrets`. This is what `00`–`04` are.
- **Composite action** (`runs.using: composite` in `action.yml`) — a bundle of *steps* reused **within** a job (e.g. the repeated `checkout → ‹lang-setup› → ‹install›` prelude). Reach for this if the per-job boilerplate grows; for a handful of jobs the inline repetition is clearer than the indirection.

## Simple (unversioned) Pages deploy

When there's no version dimension, skip the versioned-docs tool — upload an artifact and deploy:

```yaml
permissions: { contents: read, pages: write, id-token: write }
jobs:
  build:
    steps:
      - uses: actions/upload-pages-artifact@<sha>
        with: { path: <built-site-dir> }
  deploy:
    needs: build
    environment: { name: github-pages, url: "${{ steps.d.outputs.page_url }}" }
    steps:
      - id: d
        uses: actions/deploy-pages@<sha>
```
