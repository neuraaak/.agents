# PHP Style & Layout Standards (UIA)

Visual structure, import organization, and documentation standards for PHP source files.

<rules>
- **SECTIONING:** Use `// ///////////////////////////////////////////////////////////////` for main sections.
- **DOCBLOCKS:** Use PHPDoc (`/** */`) for all public classes, methods, and properties.
- **USE STATEMENTS:** Group by: 1. PHP built-ins / SPL, 2. vendor (alphabetical by namespace), 3. local. One blank line between groups.
- **LANGUAGE:** Always use English for comments and docblocks.
- **COMMENTS:** Explain "why", not "what". Avoid noise.
</rules>

## Main Section Separators

Use the forward slash separator to create clear visual boundaries.

```php
// ///////////////////////////////////////////////////////////////
// USE STATEMENTS
// ///////////////////////////////////////////////////////////////
```

## Subsection Markers

Use dashes for internal organization within classes or functions.

```php
// ------------------------------------------------
// PRIVATE METHODS
// ------------------------------------------------
```

## Use Statement Organization Pattern

```php
<?php

declare(strict_types=1);

// ///////////////////////////////////////////////////////////////
// USE STATEMENTS
// ///////////////////////////////////////////////////////////////
// PHP built-ins / SPL
use InvalidArgumentException;
use RuntimeException;

// Vendor
use Psr\Log\LoggerInterface;
use Symfony\Component\HttpFoundation\Request;

// Local
use App\Domain\Exceptions\DomainException;
use App\Infrastructure\Repository\UserRepository;
```

<examples>
/**
 * Calculates statistical metrics for a dataset.
 *
 * @param array<float> $data A list of numeric measurements.
 * @return array<string, float> A mapping of metric names to values.
 */
public function calculateMetrics(array $data): array
{
    // Implementation
}
</examples>

<success_criteria>

- Section markers used for navigation.
- Use statements correctly grouped with blank lines between groups.
- PHPDoc present for all public symbols (class, method, property).
- `declare(strict_types=1)` present at the top of every file.

</success_criteria>
