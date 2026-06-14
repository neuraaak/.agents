# Config & Infrastructure — Cross-cutting principles

These principles apply regardless of language. Load alongside the matching language file.

## Core rules

- **Lockfiles**: always commit lockfiles (`uv.lock`, `pnpm-lock.yaml`) for reproducible builds.
- **Docker**: multi-stage builds — separate build-time dependencies from the runtime image. Non-root user in production.
- **Observability**: OpenTelemetry for tracing, metrics, and structured logs. JSON output.
- **Health checks**: define `HEALTHCHECK` in Docker for orchestration awareness.
- **Never `latest`** in Docker — pin exact tags.

## Secret & environment-variable management

- **Never secrets in the repo**: no API keys, tokens, or passwords in cleartext in code or config files.
- `.env` local only — always in `.gitignore`.
- In CI/CD: inject via the platform's secrets (GitHub Actions secrets, Vault, etc.).
- Validate env vars at startup — fail fast if a required variable is missing.

```bash
# Startup validation pattern (shell)
: "${DATABASE_URL:?DATABASE_URL is required}"
: "${API_KEY:?API_KEY is required}"
```

## Monorepo tooling

| Tool   | Workspace command                                     |
| :----- | :---------------------------------------------------- |
| `pnpm` | `pnpm -r run build` / `pnpm --filter <pkg> add <dep>` |
| `uv`   | `uv sync --all-packages` / `uv run -p <pkg> pytest`   |

- Define workspace packages in `pnpm-workspace.yaml` (JS) or `[tool.uv.workspace]` (Python).
- Share linter configs at the root; packages inherit via `extends`.

## Anti-patterns to avoid

| Anti-pattern                                     | Problem                    | Fix                                                        |
| :----------------------------------------------- | :------------------------- | :--------------------------------------------------------- |
| Hard-coded secret in code                        | Exposure in repo / logs    | Environment variable + vault                               |
| `latest` Docker tag                              | Non-reproducible build     | Exact tag (`node:24.1.0-alpine`)                           |
| Tool config in multiple files                    | Fragmented source of truth | Centralize everything in `pyproject.toml` / `package.json` |
| `pnpm install` without `--frozen-lockfile` in CI | Lockfile silently updated  | Always `--frozen-lockfile` in CI                           |
| Dev dependencies in the runtime image            | Bloated image              | Multi-stage, copy only the artifact                        |
