# Project Quality — Languages Index

Route to the correct language subdirectory. For mixed repos, load both language files.

## Supported languages

| Language              | Detect via       | File                              |
| :-------------------- | :--------------- | :-------------------------------- |
| Python                | `pyproject.toml` | `languages/python/quality.md`     |
| JavaScript/TypeScript | `package.json`   | `languages/javascript/quality.md` |
| PHP                   | `composer.json`  | `languages/php/quality.md`        |

## What each file owns

- **`python/quality.md`** — pytest, hypothesis, Pydantic validation, secret management, python-dotenv, bcrypt, structured logging.
- **`javascript/quality.md`** — node:test / Vitest, Zod validation, fast-check, secret management, Node.js permission model.
- **`php/quality.md`** — PHPUnit 11+ (#[Test] / #[DataProvider]), fakes over mocks, symfony/validator, argon2id, PDO prepared statements, Monolog JsonFormatter.

## Frameworks (delta-only)

A framework only exists on top of a language, so its file is nested under the
language: `<lang>/frameworks/<framework>.md`. It is a **delta** — load it *in
addition to* the language file (cascade `common → language → framework`), and it
repeats nothing from the base.

| Framework | Detect via                                                              | File                             |
| :-------- | :---------------------------------------------------------------------- | :------------------------------- |
| React     | `react` dep, or `vite` + `@vitejs/plugin-react`                         | `javascript/frameworks/react.md` |
| FastAPI   | `fastapi` dep, or a uvicorn/ASGI entrypoint                             | `python/frameworks/fastapi.md`   |
| Django    | `django` dep, or `manage.py` / `DJANGO_SETTINGS_MODULE`                 | `python/frameworks/django.md`    |
| Symfony   | `symfony/framework-bundle` dep, or `bin/console` + `config/bundles.php` | `php/frameworks/symfony.md`      |
| Laravel   | `laravel/framework` dep, or `artisan` + `bootstrap/app.php`             | `php/frameworks/laravel.md`      |

## Adding a new language

1. Create `<language>/` here with `quality.md`.
2. Register in the table above and in `references/index.md`.

## Adding a new framework

1. Create `<language>/frameworks/<framework>.md` as a delta on the language file.
2. Open with `> Delta on <base>. Load base first.` and close with its own Success criteria.
3. Register in the framework table above and in `references/index.md`.
