# Config & Toolchain — FastAPI (delta)

> **Delta** on `references/languages/python/config.md`. Load the Python base file
> first; this file only adds or overrides what changes when FastAPI is used.

## Detection

`fastapi` in `dependencies`, or an ASGI entrypoint (`uvicorn`/`hypercorn`) in the
project.

## `pyproject.toml` — dependencies delta

Add to the base `[project]` table (the build/lint/type sections are unchanged):

```toml
[project]
dependencies = [
    "fastapi",
    "uvicorn[standard]",
    "pydantic-settings",   # typed env-var loading
]

[project.optional-dependencies]
dev = ["pytest", "ruff", "ty", "mkdocs", "httpx"]  # httpx for TestClient
```

- `httpx` is required by FastAPI's `TestClient` — keep it in `dev`.

## Project layout

```text
src/app/
  main.py        # FastAPI() instance + router includes
  settings.py    # BaseSettings (env)
  routers/
  __init__.py
```

## Environment variables — `pydantic-settings` delta

Replace the base `get_env` helper with a typed `BaseSettings` model — validation,
typing, and `.env` loading in one place:

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str        # required — fails fast at startup if missing
    api_key: str

settings = Settings()  # raises ValidationError if a required var is absent
```

- `.env` stays in `.gitignore` (base rule); in CI, inject via platform secrets.
- Never commit a populated `.env`.

## Docker — uvicorn runtime delta

Same multi-stage base, but the runtime `CMD` runs the ASGI server. The base
`/health` healthcheck already targets port 8000 — keep it.

```dockerfile
# Runtime stage (replaces base CMD)
COPY src/ src/
EXPOSE 8000
CMD [".venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Add a `/health` route so the base `HEALTHCHECK` succeeds:

```python
@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
```

## Success criteria (FastAPI)

- `fastapi` + `uvicorn[standard]` + `pydantic-settings` in dependencies; `httpx` in dev.
- Env handled by a typed `BaseSettings` model — fails fast on missing vars.
- `.env` gitignored; never committed.
- Runtime image runs `uvicorn app.main:app`; `/health` route present for the healthcheck.
