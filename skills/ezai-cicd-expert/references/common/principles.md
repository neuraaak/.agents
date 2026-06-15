# CI/CD Principles — Platform & Language Agnostic

The strategy that holds regardless of platform or language. Pair this with a platform file (`github/syntax.md` / `gitlab/syntax.md`, plus the matching `orchestration.md` for release tasks) and one language file.

## Pipeline shape

Order stages cheapest-and-most-likely-to-fail first, so feedback is fast and expensive jobs don't run on already-broken code:

```text
lint → type-check → test → build → publish/deploy
```

- **lint / type-check** run in parallel — they're independent and fast. They gate everything else.
- **test** can fan out into a matrix (OS × language version). Use it only where coverage genuinely matters; every matrix cell costs minutes.
- **build** produces the artifact once and hands it downstream — don't rebuild in the deploy job.
- **publish / deploy** runs only on the right ref (a tag, `main`) and behind a protected environment.

Independent jobs should declare their dependencies explicitly (`needs`) so the scheduler parallelizes the rest instead of running a single serial chain.

## Validation vs release — two modes, one set of jobs

A pipeline reasons by **lifecycle moment**, not by tool. Everything reduces to two modes driven by a single question: **does the version in the file (`pyproject.toml` / `package.json`) differ from the last tag?**

- **Validation mode** — PRs and feature branches. Everything is dry-run: execute, build, verify — **nothing mutates the world** (no real tag, no upload, no deploy).
- **Release mode** — push to the default branch **with** a version change. Strictly sequential and mutating: tag → publish → docs.

Two operating principles fall out of this:

- **Always build, conditionally deliver.** Build the package *and* the docs on **every** path (validation included — that's how you catch a broken build before merge); only `publish`/`deploy` on a real release. A PR that can't build is a failed PR, not a skipped step.
- **Sync the tag to the file version; never bump it in CI.** The human writes the version in the file. CI compares file-version vs the last tag: **changed → create the release**, **unchanged → skip** (no tag, no publish). CI never edits the version itself.

## Idempotence & replay

A release is a sequence of irreversible-then-reversible steps; design every step so a partial failure can be **re-run safely**.

- **Publish must be re-run safe.** Treat "version already present" as success: `twine upload --skip-existing` (Python), an existence check before `npm publish` (JS). A replayed publish that 409s and fails the job is a bug.
- **Docs deploys must be idempotent.** Re-deploying a version overwrites its subfolder — freely replayable.
- **Order matters: publish → docs.** Publish is irreversible; docs are not. Never deploy a `vX.Y.Z` doc before the matching package exists (a doc without a package is a broken promise).

## Maintainability — logic in scripts, not YAML

Keep the real logic (tag sync, version extraction, build, publish step) in **scripts or a task runner** (`nox`, `tox`, `just`, `make`, `package.json` scripts) called by the pipeline. YAML stays a thin orchestration layer. This is what prevents drift when the same project ships both a GitHub and a GitLab pipeline — both call the same script instead of re-encoding the logic twice.

## Caching

The goal is to skip re-downloading dependencies, **not** to skip producing a correct build. A cache is a performance optimization that must be invisible to correctness.

- **Key the cache on the lockfile hash.** When `uv.lock` / `pnpm-lock.yaml` changes, the key changes and you get a clean install. Same lockfile → cache hit.
- **Cache the package store, not `node_modules` / `.venv`.** Restoring the global store + a fast `--frozen` install is more robust than restoring a half-resolved tree.
- **Never cache build outputs as if they were inputs.** A stale `dist/` that masks a broken build is worse than no cache.

## Secrets & authentication

- **Prefer OIDC over stored secrets.** Both platforms can mint a short-lived token a cloud/registry trusts, so there's no long-lived credential to leak or rotate. Use it for PyPI/npm trusted publishing, AWS/GCP, container registries.
- **Scope and mask.** Secrets are injected per-job, masked in logs, never echoed. Never pass a secret as a CLI arg that lands in process listings or logs.
- **Forks don't get secrets.** `pull_request` from a fork must not expose secrets — keep secret-using steps off untrusted-PR triggers.

## Least privilege

- Start from **no permissions** and grant only what a job needs. A test job needs read; a release job needs `contents: write` / `id-token: write` and nothing more.
- **Pin third-party actions to a commit SHA** (a moving tag can be repointed at malicious code). Pin runner images and language versions to exact values for reproducibility.

## Environments & deploy gates

- Model each deploy target (`staging`, `production`) as a protected **environment** with its own secrets.
- **Production requires a manual gate**: required reviewers and/or a wait timer. Deploys never fire automatically on a feature-branch push.
- Make deploys **idempotent and rollback-able** — re-running the same deploy is safe, and the previous artifact is still retrievable.

## Concurrency

- Cancel superseded runs on the same branch/PR (a new push obsoletes the old run) to save minutes.
- **Never cancel in-progress deploy/publish jobs** — interrupting a release mid-flight can leave a half-published artifact. Serialize those with a dedicated concurrency group and `cancel-in-progress: false`.

## Core rules

These hold on both platforms.

- **Pin everything.** Actions to a commit SHA (or at least a major tag); runner images and language versions to exact values. Never `ubuntu-latest` for jobs that publish artifacts, push to a registry, or deploy — use a pinned runner (e.g., `ubuntu-24.04`). Never `node:latest`.
- **Self-hosted runners.** Skip runner image pinning (not applicable) but still pin all action SHAs and language versions. Flag to the user if OIDC requires additional runner configuration.
- **Least privilege.** Default `permissions: {}` (GitHub) / scoped tokens (GitLab); grant only what each job needs. Prefer OIDC over long-lived secrets.
- **Cache the dependency store, keyed on the lockfile.** A cache miss must still produce a correct build. If no lockfile is detected, warn the user that reproducible installs are not possible and block on this before writing the pipeline.
- **Fail fast on quality gates, then build.** Lint and type-check are cheap — run them before the expensive test matrix.
- **Reproducible installs.** `--frozen-lockfile` / `uv sync --frozen`. A pipeline that mutates the lockfile is a bug.
- **Guard deploys.** Production deploys go through a protected environment with required reviewers; never deploy on every push to a feature branch.
- **Release tag is immutable.** Create `vX.Y.Z` once and never move it. The moving pointer (e.g. a `vX-latest` major alias, a `latest` docs alias) lives in a **separate ref** — force-pushing is only ever for the alias, never for the release tag itself.
- **Always build, conditionally deliver.** Build package and docs on every path (validation); only publish/deploy on a real release. See "Validation vs release" above.
- **Replay-safe delivery.** Publish is re-run safe (`--skip-existing` / existence check); docs deploys are idempotent — so a partial release failure can be replayed without manual cleanup.
- **A required status check is a branch-protection setting, not a workflow property.** A CI workflow running alone doesn't block a merge — the "required check" rule in GitHub branch protection / GitLab MR settings does.

## Output format

For **write/audit**: open with a `<thinking>` block stating detected platform, language(s), request type, resolved toolchain per role, and which reference files were loaded. Then emit the YAML or audit report. Note any toolchain assumptions.

For **debug**: lead with the root cause in one sentence, then the fix, then the corrected YAML snippet.

## Success criteria

- Pipeline uses only tools the project actually declares (resolved via the tool registry).
- Every action/image/version is pinned.
- Token permissions are explicit and minimal.
- Dependency caching is keyed on the lockfile.
- Quality gates run before the test matrix; jobs parallelize where independent.
- Production deploys are gated behind a protected environment.

## Audit checklist

When reviewing an existing pipeline, report findings in this severity order:

### 🔒 Security

- Third-party actions pinned to SHA? Runner/image/versions pinned?
- `permissions` explicit and minimal (not the default broad token)?
- Secrets unexposed to fork PRs? No secrets in logs or CLI args?
- OIDC used where a long-lived secret could be avoided?

### ✅ Correctness

- Installs use `--frozen` / `--frozen-lockfile`?
- Cache keyed on the lockfile (no stale-cache correctness bug)?
- Deploy uses the artifact built upstream, not a rebuild?
- Triggers fire on the intended refs only?
- Release gated on a real version change (tag synced to file version, not bumped/tagged on every push)?
- Release tag created immutable — only the moving alias (`vX-latest`/`latest`) is force-pushed, never `vX.Y.Z`?
- Publish re-run safe (`--skip-existing` / existence check) and docs deploy idempotent?
- Order is publish → docs (the irreversible step first)?

### ⚡ Speed

- Lint/type-check gate before the test matrix?
- Independent jobs parallelized via `needs`?
- Dependency caching present and effective?
- Concurrency cancels superseded non-deploy runs?

### 🎨 Style

- Jobs and steps named clearly?
- No copy-pasted blocks that should be a reusable/composite workflow or YAML anchor?
