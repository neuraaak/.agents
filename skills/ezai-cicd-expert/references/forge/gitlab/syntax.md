# GitLab CI — Core Syntax

The building blocks of a `.gitlab-ci.yml`. For release automation (parent-child pipelines, modular `include`, release patterns, Pages deploy), see `gitlab/orchestration.md`. For the actual job steps, see the language file.

## Skeleton

```yaml
stages: [lint, test, build, deploy]

default:
  image: node:22-bookworm-slim     # pinned, not :latest

workflow:                          # control when the whole pipeline runs
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_TAG

lint:
  stage: lint
  script:
    - echo "..."
```

## `rules` (replaces the legacy `only`/`except`)

```yaml
deploy:
  stage: deploy
  rules:
    - if: $CI_COMMIT_TAG                       # only on tags
      when: on_success
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual                             # gated manual deploy
    - when: never                              # default: don't run
```

`rules` evaluate top-down; first match wins. Use `when: manual` for deploy gates, `when: never` as the safe default.

## `needs` — DAG parallelism

By default jobs wait for the whole previous stage. `needs` breaks that into a DAG so independent jobs start as soon as their inputs are ready:

```yaml
test:
  stage: test
  needs: [lint]          # start once lint passes, don't wait for the full stage
```

## Caching

Cache keyed on the lockfile; pull-only in jobs that shouldn't mutate it:

```yaml
.cache-pnpm: &cache-pnpm
  cache:
    key:
      files: [pnpm-lock.yaml]
    paths: [.pnpm-store]
    policy: pull-push                # use pull for read-only consumer jobs

test:
  <<: *cache-pnpm
  cache:
    policy: pull
```

YAML anchors (`&`/`*`) and `extends:` keep repeated config DRY — the GitLab equivalent of reusable steps.

## Artifacts pass build output downstream

```yaml
build:
  stage: build
  script: [pnpm build]
  artifacts:
    paths: [dist/]
    expire_in: 1 week

deploy:
  stage: deploy
  needs: [build]                     # consumes dist/ — does NOT rebuild
```

## Secrets & OIDC (`id_tokens`)

```yaml
publish:
  id_tokens:
    PYPI_ID_TOKEN:
      aud: https://pypi.org          # short-lived OIDC token, no stored secret
  script:
    - uv publish
```

Project/group CI variables hold secrets; mark them **Masked** and **Protected** so they're only exposed on protected branches/tags and never printed.

## Environments & gates

```yaml
deploy:prod:
  stage: deploy
  environment:
    name: production
    url: https://example.com
  rules:
    - if: $CI_COMMIT_TAG
      when: manual                   # the gate
  resource_group: production         # serialize: one deploy at a time
```

`resource_group` prevents concurrent deploys to the same target. Protected environments + approval rules are configured in **Settings → CI/CD → Environments**.
