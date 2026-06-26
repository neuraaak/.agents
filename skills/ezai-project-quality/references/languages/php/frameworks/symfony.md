# Quality — Symfony (delta)

> **Delta** on `references/languages/php/quality.md`. Load the PHP base file
> first; this file only adds or overrides what changes when Symfony is used.

## Detection

`symfony/framework-bundle` in `composer.json`, or `bin/console` + `config/bundles.php` present in the project.

## Test stack delta

Symfony tests use **`symfony/phpunit-bridge`** on top of PHPUnit 11+. It adds
deprecation reporting and the `KernelTestCase` / `WebTestCase` base classes.

```json
{
    "require-dev": {
        "symfony/phpunit-bridge": "^7.2",
        "dama/doctrine-test-bundle": "^8.0"
    }
}
```

- `dama/doctrine-test-bundle` wraps each test in a transaction that rolls back
  after the test — fast, isolated DB tests without truncating tables.
- Keep `#[Test]` + `#[DataProvider]` attributes (base rule) — they work with
  `symfony/phpunit-bridge` unchanged.

## Test layers

```text
tests/
├── Unit/           ← pure PHPUnit TestCase — no Symfony kernel, no DB
│   └── Domain/
│       └── MoneyTest.php
├── Integration/    ← KernelTestCase — real container, real DB
│   └── Infrastructure/
│       └── DoctrineOrderRepositoryTest.php
└── Functional/     ← WebTestCase — full HTTP stack, real DB
    └── Controller/
        └── OrderControllerTest.php
```

Use `KernelTestCase` for integration tests (container + DB), `WebTestCase` for
HTTP-level functional tests. **Never use `WebTestCase` to test domain logic.**

## Unit tests — fakes over container (base rule)

Unit tests must not boot the Symfony kernel. Use the fakes pattern from the base:

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\Domain;

use App\Domain\Order;
use App\Tests\Fake\InMemoryOrderRepository;
use App\Application\Handler\PlaceOrderHandler;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

final class PlaceOrderHandlerTest extends TestCase
{
    #[Test]
    public function it_persists_a_new_order(): void
    {
        $repo    = new InMemoryOrderRepository();
        $handler = new PlaceOrderHandler($repo);

        $handler->handle(orderId: 42);

        self::assertNotNull($repo->findById(42));
    }
}
```

- No `static::getContainer()` in unit tests — that boots the kernel.
- `static::getContainer()->get()` is allowed **only** in `KernelTestCase`
  integration tests, and only to fetch infrastructure adapters (not domain
  objects).

## Integration tests — `KernelTestCase` + DAMA

```php
<?php

declare(strict_types=1);

namespace App\Tests\Integration\Infrastructure;

use App\Infrastructure\Persistence\DoctrineOrderRepository;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;
use PHPUnit\Framework\Attributes\Test;

final class DoctrineOrderRepositoryTest extends KernelTestCase
{
    private DoctrineOrderRepository $repository;

    protected function setUp(): void
    {
        self::bootKernel(['environment' => 'test']);
        $this->repository = static::getContainer()->get(DoctrineOrderRepository::class);
    }

    #[Test]
    public function it_saves_and_retrieves_an_order(): void
    {
        $order = Order::place(id: 1);
        $this->repository->save($order);

        $found = $this->repository->findById(1);
        self::assertNotNull($found);
        self::assertSame(1, $found->id());
    }
}
```

- `DAMA\DoctrineTestBundle` rolls back every test — no `TRUNCATE` needed.
- Mark integration tests with `@group integration` (base rule) to allow fast
  unit-only CI runs.

## Functional tests — `WebTestCase`

```php
<?php

declare(strict_types=1);

namespace App\Tests\Functional\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
use PHPUnit\Framework\Attributes\Test;

final class OrderControllerTest extends WebTestCase
{
    #[Test]
    public function post_order_returns_201(): void
    {
        $client = static::createClient();

        $client->request('POST', '/api/orders', content: '{"id": 99}', server: [
            'CONTENT_TYPE' => 'application/json',
        ]);

        self::assertResponseStatusCodeSame(201);
    }

    #[Test]
    public function unauthenticated_post_returns_401(): void
    {
        $client = static::createClient();
        $client->request('POST', '/api/orders');

        self::assertResponseStatusCodeSame(401);
    }
}
```

- Always test **both** the authenticated (2xx) and unauthenticated (401/403) paths.
- Prefer `assertResponseStatusCodeSame()` and `assertResponseIsSuccessful()` over
  manual `$response->getStatusCode()` checks.

## Security delta

- **CSRF**: Symfony's `CsrfTokenManager` is active by default for forms;
  `WebTestCase` HTTP client handles tokens automatically — test CSRF behavior on
  custom token endpoints explicitly.
- **Firewall / Authorization**: test both the 200 (authenticated) and 401/403
  (no or wrong credentials) paths. Use `$client->loginUser($user)` or
  `$client->request()` with HTTP Basic for token tests.
- **Form validation**: Symfony's `symfony/validator` (already in the base) is
  the canonical validation layer — no override needed. Use `#[Assert\…]`
  attributes on DTOs and `FormRequest` objects.
- **Never** test security by mocking the firewall — use the real kernel.

## Success criteria (Symfony)

- `symfony/phpunit-bridge` in dev deps; `dama/doctrine-test-bundle` for DB isolation.
- Unit tests (`TestCase`) boot no kernel and use fakes (base rule).
- Integration tests (`KernelTestCase`) use the real container and real DB; wrapped by DAMA transactions.
- Functional tests (`WebTestCase`) cover both authenticated and unauthenticated paths.
- `static::getContainer()->get()` appears only in `KernelTestCase` subclasses, never in `TestCase`.
- Integration tests tagged `@group integration` for selective CI runs.
