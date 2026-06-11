# GitHub Actions — Release & Deploy Orchestration

Multi-workflow patterns for release engineering: reusable workflows, the auto-tag → publish → docs cascade, and Pages deployment. For the building blocks (triggers, jobs, matrix, caching), see `github/syntax.md`.

## Reusable & composite workflows

Avoid copy-paste across repos/jobs.

- **Reusable workflow** (`on: workflow_call`) — a whole callable job graph with `inputs`/`secrets`.
- **Composite action** (`runs.using: composite` in `action.yml`) — a bundle of steps reused within jobs.

```yaml
jobs:
  test:
    uses: ./.github/workflows/reusable-test.yml
    with:
      version: "3.12"
```

## `workflow_call` — receiving inputs and secrets

A reusable workflow declares what the caller must pass:

```yaml
on:
  workflow_dispatch:
  workflow_call:
    inputs:
      version:   { required: true, type: string }
      tag:       { required: true, type: string }
      is_prerelease: { required: false, type: string, default: "false" }
    secrets:
      PYPI_API_TOKEN: { required: true }
```

Inputs let the caller pass context (version, tag, prerelease flag) without environment variables. Declaring explicit `secrets:` is safer than `secrets: inherit` when the workflow can be called from untrusted code — see the cascade note below.

## Auto-tag → publish → docs cascade

A common orchestration: on every push to `main`, read the version from `pyproject.toml`/`package.json`, create a `vX.Y.Z` tag and a `vX-latest` moving tag, then cascade to publish and docs via `workflow_call`.

```yaml
# auto-tag.yml (abbreviated)
on:
  push: { branches: [main] }
  workflow_dispatch:

permissions:
  contents: write          # needed to push tags

jobs:
  auto-tag:
    outputs:
      version: ${{ steps.version.outputs.version }}
      tag_name: ${{ steps.tag.outputs.tag_name }}
      is_prerelease: ${{ steps.meta.outputs.is_prerelease }}
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      # ... extract version from pyproject.toml / package.json ...
      - name: Create and push tags
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git tag -f "v$VERSION"
          git tag -f "v$(echo $VERSION | cut -d. -f1)-latest"
          git push origin --force "v$VERSION" "v$(echo $VERSION | cut -d. -f1)-latest"

  trigger-publish:
    needs: auto-tag
    uses: ./.github/workflows/publish.yml
    secrets: inherit
    with:
      version: ${{ needs.auto-tag.outputs.version }}
      tag: ${{ needs.auto-tag.outputs.tag_name }}

  trigger-docs:
    needs: [auto-tag, trigger-publish]
    uses: ./.github/workflows/docs.yml
    secrets: inherit
    with:
      version: ${{ needs.auto-tag.outputs.version }}
```

**The `vX-latest` moving tag** lets users pin to a major version that always points at the newest release within that major. Force-push (`-f` / `--force`) is intentional here — moving tags are meant to move.

**`secrets: inherit`** is convenient on private repos but passes **all** repo secrets to called workflows. On repos where untrusted PRs can trigger workflows, scope with explicit `secrets:` declarations instead.

## GitHub Pages deploy — two approaches

**Simple (static site, no versioning)** — upload artifact and deploy via `actions/deploy-pages`:

```yaml
permissions:
  contents: read
  pages: write
  id-token: write
jobs:
  build:
    steps:
      - uses: actions/upload-pages-artifact@v3
        with: { path: dist }
  deploy:
    needs: build
    environment: { name: github-pages, url: "${{ steps.d.outputs.page_url }}" }
    steps:
      - id: d
        uses: actions/deploy-pages@v4
```

**Versioned docs with mike** — `contents: write` pushes to the `gh-pages` branch directly; `mike` handles the alias (`latest`):

```yaml
permissions:
  contents: write

jobs:
  deploy-docs:
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }           # mike needs full history
      - run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git fetch origin gh-pages --depth=1 || true
      - run: |
          VERSION="${{ inputs.version }}"
          IS_PRERELEASE="${{ inputs.is_prerelease }}"
          if [ "$IS_PRERELEASE" = "true" ]; then
            uv run mike deploy --push "$VERSION"
          else
            uv run mike deploy --push --update-aliases "$VERSION" latest
            uv run mike set-default --push latest
          fi
```

With mike, `is_prerelease` controls whether the `latest` alias moves — pre-releases publish the version but leave `latest` pointing at the previous stable.
