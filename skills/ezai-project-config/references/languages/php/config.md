# Config & Toolchain — PHP

## Rules

- **PACKAGE MANAGER**: `composer` 2.x exclusively. Never install packages globally.
- **TOOLS**: `composer` (deps), `PHP-CS-Fixer` (format), `PHPStan` (static analysis), `captainhook` or composer scripts (git hooks).
- **TYPES**: `declare(strict_types=1)` at the top of **every** PHP file — no exceptions.
- **CENTRAL**: all project metadata in `composer.json`. Tool config in dedicated files (`phpstan.neon`, `.php-cs-fixer.php`).
- **VERSION**: PHP 8.3+ minimum. Pin in `.php-version` and in `composer.json` → `require.php`.
- **LOCKFILE**: `composer.lock` committed. CI must run `composer install --frozen-lockfile` (Composer 2.2+: `COMPOSER_MIRROR_PATH_REPOS=1 composer install`).

## Environment

```bash
composer install                  # install deps including dev
composer install --no-dev         # production install
composer run lint                 # PHP-CS-Fixer dry-run
composer run lint:fix             # PHP-CS-Fixer apply
composer run analyse              # PHPStan
composer run test                 # PHPUnit
```

## `.php-version`

```text
8.3
```

Commit this file to pin the PHP version used by tooling and runtime environments.

## `composer.json` — full structure

```json
{
    "name": "vendor/my-project",
    "description": "My project description",
    "type": "project",
    "license": "MIT",
    "require": {
        "php": ">=8.3",
        "symfony/dotenv": "^7.2"
    },
    "require-dev": {
        "phpunit/phpunit": "^11.0",
        "phpstan/phpstan": "^2.0",
        "friendsofphp/php-cs-fixer": "^3.65"
    },
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "App\\Tests\\": "tests/"
        }
    },
    "scripts": {
        "lint": "php-cs-fixer check --diff",
        "lint:fix": "php-cs-fixer fix",
        "analyse": "phpstan analyse",
        "test": "phpunit",
        "check": ["@lint", "@analyse", "@test"]
    },
    "config": {
        "sort-packages": true,
        "allow-plugins": {
            "phpstan/extension-installer": true
        }
    }
}
```

## PHPStan — `phpstan.neon`

```neon
parameters:
    level: 8                        # target level 8 minimum; raise to 9-10 progressively
    paths:
        - src
    excludePaths:
        - src/Kernel.php
    checkMissingIterableValueType: true
    treatPhpDocTypesAsCertain: false
```

PHPStan levels: 0 (basic) → 10 (strictest). New projects start at 8, existing projects raise gradually.

## PHP-CS-Fixer — `.php-cs-fixer.php`

```php
<?php

declare(strict_types=1);

$finder = PhpCsFixer\Finder::create()
    ->in(__DIR__ . '/src')
    ->in(__DIR__ . '/tests');

return (new PhpCsFixer\Config())
    ->setRules([
        '@PER-CS'                   => true,     // PSR-12 successor — the current standard
        '@PHP83Migration'           => true,     // PHP 8.3 migration rules
        'declare_strict_types'      => true,     // enforce declare(strict_types=1)
        'array_syntax'              => ['syntax' => 'short'],
        'ordered_imports'           => ['sort_algorithm' => 'alpha'],
        'no_unused_imports'         => true,
        'trailing_comma_in_multiline' => true,
        'single_quote'              => true,
    ])
    ->setFinder($finder)
    ->setRiskyAllowed(true);
```

## `phpunit.xml.dist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/11.0/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true"
         displayDetailsOnTestsThatTriggerDeprecations="true"
         displayDetailsOnTestsThatTriggerErrors="true">
    <testsuites>
        <testsuite name="unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="integration">
            <directory>tests/Integration</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory>src</directory>
        </include>
    </source>
    <coverage/>
</phpunit>
```

## Core syntax (PHP 8.3+)

```php
<?php

declare(strict_types=1);                                  // always — top of every file

namespace App\Domain;

use App\Domain\ValueObject\EmailAddress;

// Enum (8.1+) — prefer over class constants for finite state
enum Status: string
{
    case Active  = 'active';
    case Pending = 'pending';
    case Closed  = 'closed';
}

// Readonly class (8.2+) — Value Object idiom
readonly class Money
{
    public function __construct(
        public readonly int    $amount,    // cents — never float for money
        public readonly string $currency,
    ) {
        if ($this->amount < 0) {
            throw new \InvalidArgumentException('Amount cannot be negative');
        }
    }
}

// Constructor property promotion (8.0+) — always use in DTOs and value objects
class UserDto
{
    public function __construct(
        public readonly int          $id,
        public readonly EmailAddress $email,
        public readonly Status       $status = Status::Pending,
    ) {}
}

// Named arguments (8.0+)
$user = new UserDto(id: 1, email: new EmailAddress('foo@bar.com'));

// First-class callables (8.1+)
$lengths = array_map(strlen(...), $strings);

// Fibers (8.1+) — for cooperative multitasking (use a library like ReactPHP/Revolt)
```

- `declare(strict_types=1)` in **every** file — no exception
- `readonly` classes for immutable Value Objects (8.2+)
- Backed enums (`enum Foo: string`) instead of class constants
- Constructor property promotion for DTOs and simple classes
- Named arguments for clarity on multi-param calls
- `\Throwable` instead of bare `\Exception` in catch-all handlers
- Union types (`int|string`), intersection types (`Countable&Iterator`), `never` return type

## Docker multi-stage (PHP)

```dockerfile
# ---- Build stage ----
FROM composer:2.8 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-interaction --prefer-dist

# ---- Runtime stage ----
FROM php:8.3-fpm-alpine AS runtime
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Install system extensions — only what the app actually needs
RUN docker-php-ext-install pdo_mysql opcache

# Opcache tuning for production
RUN echo "opcache.enable=1\nopcache.memory_consumption=128\nopcache.max_accelerated_files=10000\nopcache.validate_timestamps=0" \
    >> /usr/local/etc/php/conf.d/opcache.ini

WORKDIR /app
COPY --from=vendor /app/vendor ./vendor
COPY src/ ./src/
COPY public/ ./public/

USER appuser
EXPOSE 9000
HEALTHCHECK --interval=30s --timeout=5s \
    CMD php-fpm-healthcheck || exit 1
```

- Exact image tags — never `php:latest` or `composer:latest`
- Separate `vendor` stage — only production deps copied to runtime
- Non-root user (`appuser`) in the runtime stage
- `opcache.validate_timestamps=0` in production (timestamps validation in dev only)

## Environment variables

```php
<?php

declare(strict_types=1);

// Use symfony/dotenv in dev — auto-loaded via bootstrap
// In production, set vars in the environment directly (container, secrets manager)

function env(string $key, ?string $default = null): string
{
    $value = $_ENV[$key] ?? $_SERVER[$key] ?? getenv($key);

    if ($value === false || $value === null) {
        if ($default !== null) {
            return $default;
        }
        throw new \RuntimeException(sprintf("Required environment variable '%s' is not set", $key));
    }

    return (string) $value;
}

// Usage
$databaseUrl = env('DATABASE_URL');
$apiKey      = env('API_KEY');
```

`.env` (git-ignored) for dev, never committed. Reference secrets via env vars only.

## Success criteria

- `declare(strict_types=1)` at the top of every PHP file.
- `composer.lock` committed; CI uses `--frozen-lockfile` or equivalent.
- PHPStan at level 8 minimum, zero errors.
- PHP-CS-Fixer configured with `@PER-CS` + `@PHP83Migration` + `declare_strict_types`.
- Multi-stage Docker image: `composer` build stage + `php:8.3-fpm-alpine` runtime, non-root user.
- Secrets only from environment variables — never hardcoded.
- `enum` used for finite state (not class constants), `readonly` classes for Value Objects.
