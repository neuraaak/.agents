# Quality — PHP

## Test structure

```text
tests/
├── bootstrap.php               ← autoload + dotenv for test env
├── Unit/                       ← fast, isolated, zero real I/O
│   └── Domain/
└── Integration/                ← hits real infra (DB, HTTP, filesystem)
    └── Infrastructure/
```

```xml
<!-- phpunit.xml.dist — custom markers via groups -->
<groups>
    <!-- run: phpunit --group unit -->
    <!-- run: phpunit --group integration -->
</groups>
```

Tag integration tests with `@group integration` to allow fast unit-only runs in CI.

## PHPUnit 11+ — unit tests

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\Domain;

use App\Domain\Money;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

final class MoneyTest extends TestCase
{
    #[Test]
    public function it_creates_valid_money(): void
    {
        $money = new Money(1000, 'EUR');

        self::assertSame(1000, $money->amount);
        self::assertSame('EUR', $money->currency);
    }

    #[Test]
    public function it_rejects_negative_amount(): void
    {
        $this->expectException(\InvalidArgumentException::class);

        new Money(-1, 'EUR');
    }

    #[Test]
    #[DataProvider('currencyProvider')]
    public function it_handles_multiple_currencies(string $currency): void
    {
        $money = new Money(500, $currency);

        self::assertSame($currency, $money->currency);
    }

    /** @return array<string, array{string}> */
    public static function currencyProvider(): array
    {
        return [
            'EUR' => ['EUR'],
            'USD' => ['USD'],
            'GBP' => ['GBP'],
        ];
    }
}
```

- Use `#[Test]` attribute (PHPUnit 10+) instead of `test` prefix
- Use `#[DataProvider]` attribute (PHPUnit 10+) instead of `@dataProvider` annotation
- `final` test classes — prevents accidental inheritance
- `self::` (not `$this->`) for assertions — static call, cleaner stack trace

## Fakes for interfaces (prefer over Mocks)

```php
<?php

declare(strict_types=1);

namespace App\Tests\Fake;

use App\Domain\Order;
use App\Application\Port\OrderRepositoryInterface;

final class InMemoryOrderRepository implements OrderRepositoryInterface
{
    /** @var array<int, Order> */
    private array $store = [];

    public function save(Order $order): void
    {
        $this->store[$order->id()] = $order;
    }

    public function findById(int $id): ?Order
    {
        return $this->store[$id] ?? null;
    }

    /** @return list<Order> */
    public function all(): array
    {
        return array_values($this->store);
    }
}
```

Prefer fakes (lightweight in-memory implementations of an interface) over `$this->createMock()` — fakes test real behavior, not interaction expectations.

Use `createMock()` / `getMockBuilder()` only for third-party dependencies that cannot be replaced with a fake (e.g., Mailer, external SDK).

## Input validation at boundaries

```php
<?php

declare(strict_types=1);

namespace App\Application\Handler;

use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\Validator\Validation;

final readonly class CreateUserRequest
{
    public function __construct(
        #[Assert\NotBlank]
        #[Assert\Length(min: 2, max: 64)]
        #[Assert\Regex(pattern: '/^[a-zA-Z0-9_]+$/', message: 'Username contains invalid characters')]
        public string $username,

        #[Assert\NotBlank]
        #[Assert\Email]
        public string $email,
    ) {}

    public static function validate(self $request): void
    {
        $validator  = Validation::createValidatorBuilder()->enableAttributeMapping()->getValidator();
        $violations = $validator->validate($request);

        if (count($violations) > 0) {
            throw new \InvalidArgumentException((string) $violations);
        }
    }
}
```

Validate at **every I/O boundary**: HTTP requests, CLI args, message queue payloads, external API responses.
Never trust incoming data — even from internal services.

## Secret management

```php
<?php

declare(strict_types=1);

// Dev: .env loaded by symfony/dotenv in bootstrap
// Prod: environment variables injected by the container/orchestrator (Docker, K8s, AWS ECS)
// Never: hardcoded values, committed .env files, var_dump() of sensitive data

// Reading secrets safely
$apiKey = $_ENV['API_KEY'] ?? throw new \RuntimeException('API_KEY is not set');

// Hashing passwords — argon2id is the modern default
$hash    = password_hash($plainPassword, PASSWORD_ARGON2ID);
$isValid = password_verify($plainPassword, $hash);

// Generating secure tokens
$token = bin2hex(random_bytes(32));  // 64-char hex token
```

- **Dev:** `.env` (git-ignored) loaded via `symfony/dotenv`
- **Prod:** secrets from container env vars, AWS Secrets Manager, HashiCorp Vault, or equivalent
- **Audit:** `trufflehog` or `gitleaks` before open-sourcing
- **Never** use `rand()` or `mt_rand()` for security-sensitive values — always `random_bytes()`

## Security rules

```php
<?php

declare(strict_types=1);

// SQL injection — always use prepared statements via PDO
$stmt = $pdo->prepare('SELECT * FROM users WHERE email = :email');
$stmt->execute([':email' => $email]);

// XSS — always escape before output
echo htmlspecialchars($userInput, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');

// Passwords — always argon2id (or bcrypt as fallback for legacy)
$hash = password_hash($password, PASSWORD_ARGON2ID);

// File uploads — never trust the original filename
$safeFilename = preg_replace('/[^a-zA-Z0-9._-]/', '_', $upload->getClientOriginalName());
$extension    = pathinfo($safeFilename, PATHINFO_EXTENSION);
if (!in_array(strtolower($extension), ['jpg', 'png', 'pdf'], true)) {
    throw new \InvalidArgumentException('Unsupported file type');
}

// Shell commands — avoid shell_exec/exec entirely; if unavoidable, escapeshellarg()
$escaped = escapeshellarg($userInput);
```

- PDO prepared statements — no string interpolation in SQL, ever
- `htmlspecialchars()` with `ENT_QUOTES | ENT_SUBSTITUTE` for HTML output
- `password_hash(PASSWORD_ARGON2ID)` + `password_verify()` for passwords
- `random_bytes()` for all cryptographic randomness
- Validate and whitelist file extensions before saving uploads
- Never use `eval()`, `exec()`, `shell_exec()`, `system()` with user input

## Structured logging

```php
<?php

declare(strict_types=1);

use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Monolog\Formatter\JsonFormatter;
use Monolog\Processor\UidProcessor;

// Bootstrap (once per request/process)
$logger = new Logger('app');
$handler = new StreamHandler('php://stdout', Logger::DEBUG);
$handler->setFormatter(new JsonFormatter());
$handler->pushProcessor(new UidProcessor(16));   // request correlation ID
$logger->pushHandler($handler);

// Usage — always structured, never interpolated strings
$logger->info('User registered', [
    'user_id'  => $userId,
    'email'    => $email,
    'duration' => $durationMs,
]);

$logger->error('Payment failed', [
    'order_id' => $orderId,
    'reason'   => $exception->getMessage(),
    'trace'    => $exception->getTraceAsString(),
]);
```

- Use **Monolog** with `JsonFormatter` — one JSON object per line, parseable by Datadog/CloudWatch/Loki
- Always include a correlation ID (`UidProcessor` or inject from HTTP header `X-Request-ID`)
- Log structured arrays — never `"User {$id} logged in"` interpolated strings
- **Never** log passwords, tokens, PII (emails, names) — log IDs only

## Success criteria

- Tests are `final` classes, use `#[Test]` + `#[DataProvider]` attributes (PHPUnit 11+).
- Fakes implement the domain interface — no `createMock()` for internal ports.
- All I/O boundaries validated (HTTP, CLI, queue) with `symfony/validator` or equivalent.
- `password_hash(PASSWORD_ARGON2ID)` for passwords; `random_bytes()` for tokens.
- PDO prepared statements — zero string interpolation in SQL.
- `htmlspecialchars(ENT_QUOTES | ENT_SUBSTITUTE)` on every untrusted HTML output.
- Monolog with `JsonFormatter` + correlation ID processor.
- No secrets in source code, logs, or committed `.env` files.
- Coverage 80–90% on domain/application logic.
