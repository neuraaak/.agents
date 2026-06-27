# PHP — Pipeline Blueprint

The role sequence and PHP-specific concerns for a CI pipeline. **Do not hard-code tools here** — detect the project's toolchain and resolve each role to a command via `php/tool-registry.md`. Wrap the resolved commands as steps/scripts using the platform file (`github/syntax.md` or `gitlab/syntax.md`).

## Role sequence

```text
install → lint → format-check → type-check → security-scan → test → build → publish → docs
```

Lint / format-check / type-check / security-scan are independent and gate the rest. `security-scan` covers dependency CVEs (`composer audit`) plus taint SAST (`psalm --taint-analysis`) — resolve via the registry. `test` fans out across a PHP version matrix. `build`, `publish`, `docs` run only on a release ref.

## PHP-specific concerns

- **Version matrix:** test the project's supported PHP range (the `php` constraint floor in `composer.json` up to current stable, e.g. `["8.2", "8.3"]`).
- **Runner prefix:** PHP tools run via Composer scripts (`composer lint`, `composer test`) or directly (`vendor/bin/phpstan`, `vendor/bin/phpunit`). The registry commands omit the prefix; add it based on detection.
- **Frozen installs:** the install command must respect the lockfile — `composer install --no-interaction --prefer-dist` with a committed `composer.lock`. Never use `composer update` in CI.
- **PHP extensions:** declare required extensions in `composer.json` under `require` (`ext-pdo`, `ext-mbstring`). If extensions beyond the runner default are needed, add them via `sudo apt-get install php-<ext>` or a `shivammathur/setup-php` option.
- **Publish auth:** PHP packages publish to Packagist via webhook on a Git tag push — no CI step needed. For private Satis registries, set auth with `COMPOSER_AUTH` secret.

## Worked example (Composer + PHPStan + PHP-CS-Fixer + PHPUnit)

Detection: `composer.json`, `phpstan.neon`, `.php-cs-fixer.php`, `phpunit.xml` → registry lookup yields `composer install --no-interaction --prefer-dist`, `vendor/bin/phpstan analyse`, `vendor/bin/php-cs-fixer check`, `vendor/bin/phpunit`. Wrapped for **GitHub Actions**:

```yaml
jobs:
  quality:
    runs-on: ubuntu-24.04
    permissions: { contents: read }
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: "8.3"
          extensions: mbstring, pdo
          coverage: none
      - run: composer install --no-interaction --prefer-dist
      - run: vendor/bin/phpstan analyse
      - run: vendor/bin/php-cs-fixer check --diff

  test:
    needs: [quality]
    runs-on: ubuntu-24.04
    strategy:
      fail-fast: false
      matrix: { php: ["8.2", "8.3"] }
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: "${{ matrix.php }}"
          extensions: mbstring, pdo
          coverage: xdebug
      - run: composer install --no-interaction --prefer-dist
      - run: vendor/bin/phpunit --coverage-clover coverage.xml
```

For **GitLab CI**, wrap the same resolved commands as `script:` entries with a `composer`-keyed `cache:` on `vendor/` (see `gitlab/syntax.md`). For **publish** and **docs deploy**, resolve those roles in the registry and place them in the orchestration file's release flow.

A Laravel / Pest / Psalm project keeps this exact structure but every command differs — re-resolve from the registry, never copy the PHPStan/PHPUnit commands above.
