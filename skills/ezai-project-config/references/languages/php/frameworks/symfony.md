# Config & Toolchain — Symfony (delta)

> **Delta** on `references/languages/php/config.md`. Load the PHP base file
> first; this file only adds or overrides what changes when Symfony is used.

## Detection

`symfony/framework-bundle` in `composer.json`, or `bin/console` + `config/bundles.php` present in the project.

## `composer.json` — dependencies delta

```json
{
    "require": {
        "php": ">=8.3",
        "symfony/framework-bundle": "^7.2",
        "symfony/console": "^7.2",
        "symfony/dotenv": "^7.2",
        "symfony/runtime": "^7.2"
    },
    "require-dev": {
        "symfony/maker-bundle": "^1.60",
        "phpunit/phpunit": "^11.0",
        "phpstan/phpstan": "^2.0",
        "phpstan/phpstan-symfony": "^2.0",
        "friendsofphp/php-cs-fixer": "^3.65",
        "symfony/browser-kit": "^7.2",
        "symfony/css-selector": "^7.2"
    }
}
```

- `phpstan/phpstan-symfony` is **required** — without it PHPStan produces false
  positives on container-injected services and `#[Autowire]` attributes.
- `symfony/browser-kit` + `symfony/css-selector` enable `WebTestCase` in tests.

## PHPStan — `phpstan.neon` Symfony delta

Extend the base `phpstan.neon` with the Symfony extension:

```neon
includes:
    - vendor/phpstan/phpstan-symfony/extension.neon

parameters:
    level: 8
    paths:
        - src
    excludePaths:
        - src/Kernel.php
    symfony:
        container_xml_path: var/cache/dev/App_KernelDevDebugContainer.xml
```

- The `container_xml_path` lets PHPStan resolve dynamic service lookups — always
  set it for Symfony projects.

## Project layout

```text
config/
  bundles.php
  packages/         ← per-bundle YAML config
  routes/           ← route loaders
  services.yaml     ← service wiring (prefer autowiring)
src/
  Kernel.php
  Controller/       ← inbound adapters (thin — delegate to use cases)
  Domain/           ← Entities, Value Objects, Domain Events (zero Symfony import)
  Application/      ← Use Cases, Port interfaces
  Infrastructure/   ← Adapters: Doctrine repositories, Mailer, Messenger…
public/
  index.php         ← front controller (do not touch)
var/                ← gitignored: cache/, log/
```

- Keep `Domain/` and `Application/` free of any Symfony import.
- `var/` must be gitignored and excluded from PHPStan `paths`.

## Environment variables — Symfony `.env` system

Symfony ships its own multi-tier `.env` loader — replace the base `function env()` helper with Symfony's native mechanism:

```text
.env               ← committed defaults (no secrets)
.env.local         ← gitignored dev overrides
.env.test          ← committed test defaults
.env.test.local    ← gitignored test overrides
```

```php
// config/services.yaml — bind env vars to parameters
parameters:
    app.database_url: '%env(DATABASE_URL)%'
    app.api_key: '%env(API_KEY)%'
```

- In **production**, never rely on `.env` files — inject vars via container env
  (Docker, K8s). Run `composer dump-env prod` to bake them at build time.
- Use `%env(resolve:DATABASE_URL)%` or typed processors (`%env(int:PORT)%`) for
  type-safe env vars.
- **Never** commit `.env.local` or a populated `.env` with real secrets.

## Symfony Secrets — for sensitive values

For sensitive production values, prefer Symfony's encrypted vault over plain env vars:

```bash
bin/console secrets:set DATABASE_PASSWORD   # encrypts and commits to config/secrets/
bin/console secrets:decrypt-to-local        # dev only, gitignored
```

The vault key stays outside the repo (CI secret or mounted volume).

## Docker — runtime delta

Same multi-stage base, but the runtime stage adds Symfony-specific build steps:

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

# Bake env vars + warm up cache at build time (not at startup)
RUN composer dump-env prod
RUN APP_ENV=prod php bin/console cache:warmup

RUN chown -R appuser:appgroup var/
USER appuser
EXPOSE 9000
HEALTHCHECK --interval=30s --timeout=5s \
    CMD php-fpm-healthcheck || exit 1
```

- `composer dump-env prod` bakes `.env` defaults + CI env vars into `var/.env.local.php` — faster than runtime parsing.
- `cache:warmup` at build time prevents slow cold starts and permission issues.
- `var/` must be writable by the runtime user — `chown` before switching to non-root.

## Success criteria (Symfony)

- `phpstan/phpstan-symfony` in dev deps; `phpstan.neon` includes the extension with `container_xml_path`.
- `.env.local` and `.env.*.local` gitignored; secrets in the vault or CI secrets, never in committed files.
- `var/` gitignored and excluded from PHPStan paths.
- `composer dump-env prod` + `cache:warmup` run at Docker build time, not at container startup.
- `Domain/` and `Application/` import no Symfony class.
