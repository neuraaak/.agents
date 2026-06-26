# Config & Toolchain — Django (delta)

> **Delta** on `references/languages/python/config.md`. Load the Python base file
> first; this file only adds or overrides what changes when Django is used.

## Detection

`django` in `dependencies`, or a `manage.py` / `DJANGO_SETTINGS_MODULE` present
in the project.

## `pyproject.toml` — dependencies delta

```toml
[project]
dependencies = [
    "django>=5.0",
    "django-environ",          # DATABASE_URL + 12-factor env
    "gunicorn",                # WSGI production server
    "psycopg[binary]",         # PostgreSQL adapter (swap for mysqlclient if MySQL)
]

[project.optional-dependencies]
dev = ["pytest", "pytest-django", "ruff", "ty", "factory-boy", "coverage"]
```

- Use `pytest-django` (not bare `pytest`) — it wires Django settings automatically.
- `factory-boy` replaces manual fixture setup for ORM objects.

## Project layout

```text
src/
  manage.py
  config/
    settings/
      base.py          # shared settings
      local.py         # dev overrides (gitignored)
      production.py    # prod overrides
    urls.py
    wsgi.py
  apps/
    {app_name}/
      models.py
      views.py
      urls.py
      admin.py
      apps.py
```

- Keep settings split across `base / local / production` — never one fat `settings.py`.
- Group apps under `apps/` to separate them from the config package.

## Environment variables — `django-environ` delta

Replace raw `os.environ` with `django-environ`'s typed loader and `DATABASE_URL`
shorthand:

```python
# config/settings/base.py
import environ

env = environ.Env(
    DEBUG=(bool, False),
    ALLOWED_HOSTS=(list, ["localhost"]),
)
environ.Env.read_env(".env")  # reads .env if present; CI injects vars directly

SECRET_KEY = env("SECRET_KEY")           # required — fails fast if missing
DEBUG = env("DEBUG")
DATABASES = {"default": env.db("DATABASE_URL")}
ALLOWED_HOSTS = env("ALLOWED_HOSTS")
```

- `.env` stays gitignored (base rule); in CI, inject via platform secrets.
- Never commit a populated `.env`.

## Docker — gunicorn runtime delta

Same multi-stage base, but the runtime stage runs `gunicorn` + `collectstatic`:

```dockerfile
# Build stage: install deps (same as base)
# Runtime stage — Django-specific overrides:
COPY src/ src/
EXPOSE 8000

# Collect static files at build time (not at startup)
RUN .venv/bin/python manage.py collectstatic --noinput

HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8000/health/ || exit 1

CMD [".venv/bin/gunicorn", "config.wsgi:application", \
     "--bind", "0.0.0.0:8000", "--workers", "2"]
```

Add a `/health/` view so the healthcheck succeeds:

```python
# config/urls.py
from django.http import JsonResponse

def health(request):
    return JsonResponse({"status": "ok"})

urlpatterns = [
    path("health/", health),
    ...
]
```

## `pytest.ini` / `pyproject.toml` — pytest-django config

```toml
[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings.local"
python_files = ["tests.py", "test_*.py"]
```

## Success criteria (Django)

- `django-environ` used for all env vars; `DATABASE_URL` for DB config; fails fast on missing required vars.
- Settings split into `base / local / production`; `local.py` gitignored.
- `pytest-django` in dev deps with `DJANGO_SETTINGS_MODULE` set.
- Runtime image runs `gunicorn config.wsgi:application`; `/health/` route present for the healthcheck.
- `collectstatic` runs at build time, not at container startup.
