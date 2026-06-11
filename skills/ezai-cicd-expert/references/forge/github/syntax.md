# GitHub Actions — Core Syntax

The building blocks of a GitHub Actions workflow. For multi-workflow release automation (auto-tag, `workflow_call` cascades, Pages deploy), see `github/orchestration.md`. For the actual job steps, see the language file.

## Skeleton

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

# Least privilege: start empty, grant per job.
permissions: {}

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-24.04          # pinned, not ubuntu-latest
    steps:
      - uses: actions/checkout@v4
```

## Triggers (`on`)

- `push` / `pull_request` — gate on `branches`/`paths` to avoid wasteful runs.
- `pull_request_target` runs with the **base** repo's secrets against fork code — dangerous; avoid unless you fully understand it.
- `workflow_dispatch` — manual trigger; expose `inputs` for parameterized runs.
- `release` / `push` on `tags: ['v*']` — release pipelines.

## Permissions & OIDC

```yaml
permissions: {}            # workflow default

jobs:
  publish:
    permissions:
      contents: read
      id-token: write      # mint an OIDC token for trusted publishing
```

`id-token: write` lets the job exchange a short-lived OIDC token with PyPI/npm/AWS — no stored credential. This is the preferred auth path.

## Matrix

```yaml
strategy:
  fail-fast: false
  matrix:
    os: [ubuntu-24.04, windows-2022, macos-14]
    version: ["3.11", "3.12", "3.13"]
runs-on: ${{ matrix.os }}
```

`fail-fast: false` lets every cell report rather than aborting the matrix on the first failure — better signal when debugging.

## Caching

Most setup actions cache natively — prefer that over hand-rolled `actions/cache`:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: "22"
    cache: pnpm                    # keyed on pnpm-lock.yaml automatically
```

For manual caching, key on the lockfile:

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/uv
    key: uv-${{ runner.os }}-${{ hashFiles('uv.lock') }}
    restore-keys: uv-${{ runner.os }}-
```

## Pinning actions

```yaml
# Best: pin to a commit SHA (immutable)
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11   # v4.1.1
# Acceptable: major tag
- uses: actions/checkout@v4
```

## Environments & gates

```yaml
jobs:
  deploy:
    environment:
      name: production              # configure required reviewers in repo settings
      url: ${{ steps.deploy.outputs.url }}
    concurrency:
      group: deploy-production
      cancel-in-progress: false     # never interrupt a live deploy
```

Required reviewers, wait timers, and environment secrets are configured in **Settings → Environments**, not in YAML.
