# Badge Registry — PHP

PHP-specific badges: Packagist version/PHP-version + tool badges. Combine with the forge badge registry (`forge/github/badge-registry.md` or `forge/gitlab/badge-registry.md`) for the full badge block.

This file is **data, not a rule**. Detect → look up → emit:

1. **Detect** which tools the project actually uses (signals below).
2. **Look up** the badge template.
3. **Emit** only for confirmed tools. Never emit a badge for a tool not present.

Replace `{vendor}/{pkg}` with the `name` field from `composer.json` (e.g. `acme/widget`).

**Logo and color** follow [simple-icons](https://simpleicons.org): logo is the icon slug, color is the brand hex (no `#`). Never guess — a wrong slug renders a blank icon.

---

## Registry version badges

Always emit both for packages published to Packagist:

```markdown
[![Packagist version](https://img.shields.io/packagist/v/{vendor}/{pkg}?style=flat&logo=packagist&logoColor=white)](https://packagist.org/packages/{vendor}/{pkg})
[![PHP version](https://img.shields.io/packagist/php-v/{vendor}/{pkg}?style=flat&logo=php&logoColor=white)](https://packagist.org/packages/{vendor}/{pkg})
```

---

## Tool badges

Each entry: **tool** — detect via · logo slug · brand hex

### Package manager

- composer — `composer.json` (always present for PHP) · `composer` · `885630`

### Linter / static analysis

- PHPStan — `phpstan.neon` or `phpstan.neon.dist` · `phpstan` · `5A0FC8`
- Psalm — `psalm.xml` · _no logo_ · `lightgrey`
- PHP_CodeSniffer — `phpcs.xml` or `.phpcs.xml` · _no logo_ · `lightgrey`

### Formatter

- PHP-CS-Fixer — `.php-cs-fixer.php` or `.php-cs-fixer.dist.php` · _no logo_ · `lightgrey`
- Pint — `pint.json` (Laravel) · `laravel` · `FF2D20`

### Test runner

- PHPUnit — `phpunit.xml` or `phpunit.xml.dist` · `php` · `8892BF`
- Pest — `pest.config.php` or Pest in `require-dev` · `pestphp` · `8BC34A`

### Framework

- Laravel — `laravel/framework` in `composer.json`, or `artisan` · `laravel` · `FF2D20`
- Symfony — `symfony/framework-bundle`, or `bin/console` · `symfony` · `000000`

---

## Badge template

```markdown
[![{role}](https://img.shields.io/badge/{role}-{tool}-{color}?style=flat&logo={logo}&logoColor=white)]({link})
```

Omit `&logo={logo}&logoColor=white` when the tool has no logo slug. Use the tool's homepage as `{link}`.

---

## Example

Project with `composer.json` (`acme/widget`), `phpstan.neon`, `.php-cs-fixer.php`, `phpunit.xml` on GitHub → emit (in order): Packagist version + PHP version, then tool badges for composer, PHPStan, PHP-CS-Fixer, PHPUnit.
