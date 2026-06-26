# Project Config — Languages Index

Route to the correct language subdirectory. For monorepos using both languages, load both files.

## Supported languages

| Language              | Detect via       | File                             |
| :-------------------- | :--------------- | :------------------------------- |
| Python                | `pyproject.toml` | `languages/python/config.md`     |
| JavaScript/TypeScript | `package.json`   | `languages/javascript/config.md` |
| PHP                   | `composer.json`  | `languages/php/config.md`        |

## What each file owns

- **`python/config.md`** — uv, ruff, ty, hatchling, pyproject.toml structure, 3.11+ syntax rules, Docker multi-stage pattern.
- **`javascript/config.md`** — pnpm, TypeScript 6.0+, ESM, Node.js 24+, package.json, tsconfig.json, ES2026 features, Docker multi-stage pattern.
- **`php/config.md`** — Composer 2, PHP-CS-Fixer (@PER-CS), PHPStan (level 8+), composer.json structure, PHP 8.3+ syntax rules, Docker multi-stage pattern.

## Frameworks (delta-only)

A framework only exists on top of a language, so its file is nested under the
language: `<lang>/frameworks/<framework>.md`. It is a **delta** — load it *in
addition to* the language file (cascade `common → language → framework`), and it
repeats nothing from the base.

| Framework | Detect via                                                              | File                             |
| :-------- | :---------------------------------------------------------------------- | :------------------------------- |
| React     | `react` dep, or `vite` + `@vitejs/plugin-react`                         | `javascript/frameworks/react.md` |
| Vue       | `vue` dep, or `vite` + `@vitejs/plugin-vue`                             | `javascript/frameworks/vue.md`   |
| FastAPI   | `fastapi` dep, or a uvicorn/ASGI entrypoint                             | `python/frameworks/fastapi.md`   |
| Django    | `django` dep, or `manage.py` / `DJANGO_SETTINGS_MODULE`                 | `python/frameworks/django.md`    |
| Symfony   | `symfony/framework-bundle` dep, or `bin/console` + `config/bundles.php` | `php/frameworks/symfony.md`      |
| Laravel   | `laravel/framework` dep, or `artisan` + `bootstrap/app.php`             | `php/frameworks/laravel.md`      |

## Adding a new language

1. Create `<language>/` here with `config.md`.
2. Register in the table above and in `references/index.md`.
