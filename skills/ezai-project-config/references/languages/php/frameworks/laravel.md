# Config & Toolchain — Laravel (delta)

> **Delta** on `references/languages/php/config.md`. Load the PHP base file
> first; this file only adds or overrides what changes when Laravel is used.

## Detection

`laravel/framework` in `composer.json`, or `artisan` + `bootstrap/app.php` present in the project.

## `composer.json` — dependencies delta

Laravel overrides the base autoload mapping (`src/` → `app/`):

```json
{
    "require": {
        "php": ">=8.3",
        "laravel/framework": "^12.0"
    },
    "require-dev": {
        "phpunit/phpunit": "^11.0",
        "larastan/larastan": "^3.0",
        "laravel/pint": "^1.0",
        "laravel/sail": "^1.0"
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/",
            "Database\\Factories\\": "database/factories/",
            "Database\\Seeders\\": "database/seeders/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "App\\Tests\\": "tests/"
        }
    }
}
```

- `larastan/larastan` is **required** — it extends PHPStan with Laravel-aware
  stubs for Eloquent, facades, and the service container. PHPStan alone produces
  false positives on every `Model::find()` call.
- `laravel/pint` replaces PHP-CS-Fixer for Laravel projects — it ships
  opinionated defaults aligned with Laravel conventions. **Do not run both.**

## Linting — Pint replaces PHP-CS-Fixer

Replace the base PHP-CS-Fixer scripts with Pint:

```json
{
    "scripts": {
        "lint": "pint --test",
        "lint:fix": "pint",
        "analyse": "phpstan analyse",
        "test": "phpunit",
        "check": ["@lint", "@analyse", "@test"]
    }
}
```

`pint.json` (project root):

```json
{
    "preset": "laravel"
}
```

- The `laravel` preset enforces Laravel's coding style on top of PER-CS.
- `declare(strict_types=1)` is **not** enforced by the Laravel preset — add it
  manually to every file in `app/Domain/` and `app/Application/` (base rule still
  applies to the layers you own).

## PHPStan — `phpstan.neon` Laravel delta

```neon
includes:
    - vendor/larastan/larastan/extension.neon

parameters:
    level: 8
    paths:
        - app
    excludePaths:
        - app/Http/Middleware/
    checkMissingIterableValueType: true
```

- The Larastan extension resolves Eloquent magic (`Model::find()`, `HasMany`,
  `BelongsTo`) and facade static calls — without it, PHPStan reports hundreds of
  false positives.

## Project layout

```text
app/
  Domain/           ← Entities, Value Objects, Domain Events (zero Laravel import)
  Application/      ← Use Cases, Port interfaces (zero Laravel import)
  Infrastructure/   ← Eloquent models, repositories, listeners, jobs, mail
  Http/
    Controllers/    ← thin inbound adapters
    Requests/       ← Form Requests (input validation)
    Middleware/
  Providers/        ← Service Providers = composition root
config/             ← PHP config files (hashing, database, mail…)
database/
  migrations/
  factories/        ← Eloquent model factories (Infrastructure)
routes/
  api.php
  web.php
```

- The base PHP hexagonal structure (`Domain/`, `Application/`, `Infrastructure/`)
  is preserved inside `app/` — no business logic in `Http/` or `Providers/`.
- `domain_path()` / `app_path()` helpers can reference these subdirectories.

## Environment variables — Laravel `.env` system

Laravel uses its own `.env` loader — replace the base `function env()` helper
with Laravel's typed `config()` pattern:

```text
.env               ← gitignored (never committed with real secrets)
.env.example       ← committed template — all keys, no values
```

```php
// config/app.php — wrap env() in a config value
'url' => env('APP_URL', 'http://localhost'),
```

```php
// In application code — always use config(), never env() directly
$url = config('app.url');   // ✅ works after config:cache
$url = env('APP_URL');      // ❌ breaks silently after php artisan config:cache
```

**Critical rule**: `env()` stops reading `.env` after `php artisan config:cache`
runs. All code that calls `env()` directly will silently return `null` in
production. Only `config/*.php` files may call `env()`.

## Docker — Laravel runtime delta

Same multi-stage PHP base, but the runtime stage adds Laravel build steps:

```dockerfile
# ---- Build stage ----
FROM composer:2.8 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-interaction --prefer-dist

# ---- Runtime stage ----
FROM php:8.3-fpm-alpine AS runtime
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

RUN docker-php-ext-install pdo_pgsql opcache
RUN echo "opcache.enable=1\nopcache.memory_consumption=128\nopcache.max_accelerated_files=10000\nopcache.validate_timestamps=0" \
    >> /usr/local/etc/php/conf.d/opcache.ini

WORKDIR /app
COPY --from=vendor /app/vendor ./vendor
COPY . .

# Cache Laravel artefacts at build time — not at container startup
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

RUN chown -R appuser:appgroup storage/ bootstrap/cache/
USER appuser
EXPOSE 9000
HEALTHCHECK --interval=30s --timeout=5s \
    CMD php-fpm-healthcheck || exit 1
```

- `config:cache`, `route:cache`, `view:cache` at build time — never at startup.
- `storage/` and `bootstrap/cache/` must be writable by the runtime user.
- `APP_KEY` is a required env var at runtime — inject via orchestrator secrets,
  never hardcode.

## Success criteria (Laravel)

- `larastan/larastan` in dev deps; PHPStan level 8 with the Larastan extension included.
- `laravel/pint` used for formatting (`preset: laravel`); PHP-CS-Fixer not present.
- All application code uses `config('key')`, never `env('KEY')` directly.
- `config:cache`, `route:cache`, `view:cache` run at Docker build time, not startup.
- `APP_KEY` injected via orchestrator secrets; `.env` gitignored and never committed with real values.
- `declare(strict_types=1)` in every file under `app/Domain/` and `app/Application/`.
