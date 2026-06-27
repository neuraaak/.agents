# CI Tool Registry — PHP

This file is **data, not a rule**. Detect → look up → substitute:

1. **Detect** which tool fills each role (config files, lockfiles — see the detection signal).
2. **Look up** the CI command below.
3. **Substitute** into the pipeline skeleton (role sequence in `php/pipelines.md`, step syntax in the platform file).

Never hard-code a fixed stack. A Laravel + Pest + Psalm project must yield a Laravel/Pest/Psalm pipeline, not a vanilla PHPUnit/PHPStan one.

**Runner prefix:** commands below are run directly from `vendor/bin/` or via `composer run-script`. Prefer Composer scripts (`composer lint`, `composer test`) when defined — they stay correct as the project evolves.

**If multiple candidates match,** the one with a config file present wins. If still ambiguous, ask.

---

## Package install (reproducible)

- composer — `composer.lock` present · `composer install --no-interaction --prefer-dist`

> Never use `composer update` in CI — always install from the committed lockfile.

## PHP setup (runner)

- shivammathur/setup-php — GitHub Actions · `uses: shivammathur/setup-php@v2` with `php-version`, `extensions`, `coverage`
- GitLab Docker image — `.gitlab-ci.yml` · `image: php:8.3-cli` + `apt-get install` for extensions

## Lint

- PHPStan — `phpstan.neon` or `phpstan.neon.dist` · `vendor/bin/phpstan analyse`
- Psalm — `psalm.xml` · `vendor/bin/psalm`
- PHP_CodeSniffer (phpcs) — `phpcs.xml` or `.phpcs.xml` · `vendor/bin/phpcs`

## Format check

- PHP-CS-Fixer — `.php-cs-fixer.php` or `.php-cs-fixer.dist.php` · `vendor/bin/php-cs-fixer check --diff`
- PHP_CodeSniffer (phpcs) — `phpcs.xml` · `vendor/bin/phpcs` (overlaps with lint; detect from config)

## Type check

- PHPStan — `phpstan.neon` · `vendor/bin/phpstan analyse` (also covers static analysis / lint)
- Psalm — `psalm.xml` · `vendor/bin/psalm --show-info=false`

## Test (+ coverage)

- PHPUnit — `phpunit.xml` or `phpunit.xml.dist` · `vendor/bin/phpunit` (coverage: `vendor/bin/phpunit --coverage-clover coverage.xml`)
- Pest — `pest.config.php` or Pest in `composer.json` require-dev · `vendor/bin/pest` (coverage: `vendor/bin/pest --coverage --coverage-clover coverage.xml`)

## Security scan (SAST + dependencies)

- composer audit (dependencies) — `composer.lock` present · `composer audit --locked --no-dev`
- psalm taint (SAST) — `psalm.xml` + Psalm in deps · `vendor/bin/psalm --taint-analysis`
- roave/security-advisories (resolution guard) — `roave/security-advisories` in `require-dev` · enforced at install, no separate command

## Build (package artifact)

PHP packages are not compiled. No build step in CI — skip this role.

## Publish (to Packagist)

- Packagist webhook (preferred) — configure the webhook on packagist.org; a Git tag push triggers automatic indexing. No CI step required.
- Private Satis / Private Packagist — set `COMPOSER_AUTH` secret with a JSON token; no publish command in CI.

## Docs build / deploy

- phpDocumentor — `phpdoc.xml` or `phpdoc.dist.xml` · `vendor/bin/phpdoc`
- Doctum — `doctum.php` or `doctum.config.php` · `vendor/bin/doctum.php update`

---

## Example resolution

`composer.json` with `phpstan/phpstan`, `friendsofphp/php-cs-fixer`, `phpunit/phpunit`, `phpunit.xml`, `phpstan.neon`, `.php-cs-fixer.php`:

| Role         | Resolved command                                    |
| :----------- | :-------------------------------------------------- |
| install      | `composer install --no-interaction --prefer-dist`   |
| lint         | `vendor/bin/phpstan analyse`                        |
| format check | `vendor/bin/php-cs-fixer check --diff`              |
| type check   | `vendor/bin/phpstan analyse` (shared with lint)     |
| test         | `vendor/bin/phpunit --coverage-clover coverage.xml` |
| build        | _(skipped — PHP packages have no build artifact)_   |
| publish      | _(Packagist webhook — no CI step)_                  |
