# Config & Infrastructure — Cross-Language Principles

These apply regardless of language. Load alongside the language-specific config file.

- **Lockfiles:** Always commit lockfiles (`uv.lock`, `pnpm-lock.yaml`) for reproducible builds.
- **Docker:** Multi-stage builds — separate build-time deps from the runtime image. Non-root user in production.
- **Observability:** OpenTelemetry for tracing, metrics, and structured logs. JSON output.
- **Health checks:** Define `HEALTHCHECK` in Docker for orchestration awareness.
- **Never `latest` tags** in Docker — pin to exact versions.
