# Project Architect — Languages Index

Route to the correct language subdirectory. For polyglot repos, load both language files.

## Supported languages

| Language              | Detect via       | File                                   |
| :-------------------- | :--------------- | :------------------------------------- |
| Python                | `pyproject.toml` | `languages/python/architecture.md`     |
| JavaScript/TypeScript | `package.json`   | `languages/javascript/architecture.md` |
| PHP                   | `composer.json`  | `languages/php/architecture.md`        |

## What each file owns

- **`python/architecture.md`** — Python 3.11+: visibility rules, `__all__`, Protocol-based interfaces, TypedDict, Hexagonal structure, Ports & Adapters.
- **`javascript/architecture.md`** — ES2026/TypeScript 6.0+: module organization, `#private` fields, Repository pattern, TS type system, Hexagonal equivalent.
- **`php/architecture.md`** — PHP 8.3+: visibility rules, `interface` contracts, `readonly class` Value Objects, `enum` for state, Hexagonal layers, Fakes over mocks.

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

1. Create `<language>/` here with `architecture.md`.
2. Register in the table above and in `references/index.md`.

## Adding a new framework

1. Create `<language>/frameworks/<framework>.md` as a delta on the language file.
2. Open with `> Delta on <base>. Load base first.` and close with its own Success criteria.
3. Register in the framework table above and in `references/index.md`.
