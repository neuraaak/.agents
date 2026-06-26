# Quality — Laravel (delta)

> **Delta** on `references/languages/php/quality.md`. Load the PHP base file
> first; this file only adds or overrides what changes when Laravel is used.

## Detection

`laravel/framework` in `composer.json`, or `artisan` + `bootstrap/app.php` present in the project.

## Test stack delta

Laravel tests use `Orchestra\Testbench` (for packages) or the built-in
`Illuminate\Foundation\Testing\TestCase` base. The `RefreshDatabase` trait
handles database isolation between tests.

```json
{
    "require-dev": {
        "phpunit/phpunit": "^11.0"
    }
}
```

PHPUnit is the test runner — `php artisan test` is a thin wrapper around it.
Keep `#[Test]` + `#[DataProvider]` attributes (base rule) — they work unchanged.

## Test layers

```text
tests/
├── Unit/           ← pure PHPUnit TestCase — no Laravel app, no DB
│   └── Domain/
│       └── MoneyTest.php
├── Integration/    ← TestCase + RefreshDatabase — real DB, real container
│   └── Infrastructure/
│       └── EloquentOrderRepositoryTest.php
└── Feature/        ← full HTTP stack via $this->getJson() / $this->postJson()
    └── Http/
        └── OrderControllerTest.php
```

## Unit tests — fakes over facades (base rule)

Unit tests must not boot the Laravel application. Use the fakes pattern from the
base — **not** Laravel's `Mail::fake()` / `Queue::fake()` — for domain and
application layer tests:

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

- `TestCase` only (not `Illuminate\Foundation\Testing\TestCase`) — no app boot.
- No `app()`, `resolve()`, or facade calls in unit tests.

## Integration tests — `RefreshDatabase`

```php
<?php

declare(strict_types=1);

namespace App\Tests\Integration\Infrastructure;

use App\Infrastructure\Persistence\EloquentOrderRepository;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class EloquentOrderRepositoryTest extends TestCase
{
    use RefreshDatabase;

    private EloquentOrderRepository $repository;

    protected function setUp(): void
    {
        parent::setUp();
        $this->repository = $this->app->make(EloquentOrderRepository::class);
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

- `RefreshDatabase` wraps each test in a transaction and rolls back — fast
  isolation without truncating tables.
- `$this->app->make()` resolves from the real container — use only in
  integration/feature tests, never in unit tests.

## Feature tests — HTTP layer

```php
<?php

declare(strict_types=1);

namespace App\Tests\Feature\Http;

use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class OrderControllerTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function post_order_returns_201(): void
    {
        $this->actingAs($this->createUser())
             ->postJson('/api/orders', ['id' => 99])
             ->assertCreated();
    }

    #[Test]
    public function unauthenticated_post_returns_401(): void
    {
        $this->postJson('/api/orders')->assertUnauthorized();
    }
}
```

- Always test **both** authenticated (2xx) and unauthenticated (401) paths.
- Use `assertCreated()`, `assertOk()`, `assertUnauthorized()` — not bare
  `assertStatus()` on numbers.
- `$this->actingAs($user)` bypasses auth; test the 401 path with an
  unauthenticated client.

## Facades in tests — boundary rule

Laravel's built-in test fakes (`Mail::fake()`, `Queue::fake()`, `Http::fake()`,
`Storage::fake()`) are **allowed in Feature and Integration tests only**, and
only for **Infrastructure concerns** at the system boundary. They must not
substitute for domain fakes in unit tests.

```php
// ✅ Feature test — Mail::fake() for an infrastructure side-effect
#[Test]
public function registration_sends_welcome_email(): void
{
    Mail::fake();
    $this->postJson('/api/register', ['email' => 'a@b.com', 'password' => 'secret']);
    Mail::assertSent(WelcomeMail::class);
}

// ❌ Unit test — use a fake mailer interface instead
// $mailer = new InMemoryMailer();
// $handler = new RegisterUserHandler($repo, $mailer);
```

## Mass-assignment — Eloquent security rule

Every Eloquent Model must declare `$fillable` explicitly — never use an empty
`$guarded = []` (opens mass-assignment vulnerabilities):

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use Illuminate\Database\Eloquent\Model;

final class OrderModel extends Model
{
    protected $table = 'orders';

    // Explicit allowlist — never $guarded = []
    protected $fillable = ['status', 'customer_email'];

    protected $casts = [
        'status' => 'string',
    ];
}
```

- `$fillable` allowlist is mandatory — every column that can be set via `create()`
  or `fill()` must be listed.
- Never use `$guarded = []` — it disables protection entirely.
- Never pass raw `$request->all()` to `create()` without a Form Request or
  explicit key extraction.

## Password hashing — argon2id override

Laravel defaults to bcrypt. Override to argon2id to align with the base rule:

```php
// config/hashing.php
return [
    'driver' => 'argon2id',
    'argon' => [
        'memory' => 65536,
        'threads' => 1,
        'time' => 4,
    ],
];
```

```php
// Usage — unchanged, Hash facade delegates to the configured driver
use Illuminate\Support\Facades\Hash;

$hash    = Hash::make($plainPassword);   // argon2id
$isValid = Hash::check($plainPassword, $hash);
```

- Configuring `driver: argon2id` in `config/hashing.php` is sufficient — no
  code change required. Laravel's `Hash` facade delegates to the configured driver.

## Form Requests — input validation

Use Laravel's Form Requests for HTTP input validation (replaces `symfony/validator`
for the HTTP boundary in Laravel projects):

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class PlaceOrderRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'id'    => ['required', 'integer', 'min:1'],
            'email' => ['required', 'email'],
        ];
    }
}
```

```php
// Controller — type-hint the FormRequest; Laravel injects and validates automatically
public function store(PlaceOrderRequest $request): JsonResponse
{
    $order = $this->handler->handle($request->integer('id'));
    return response()->json(['id' => $order->id()], 201);
}
```

- If validation fails, Laravel returns a 422 automatically — no `try/catch` needed.
- Validate **all** HTTP input through Form Requests, never raw `$request->input()`
  without rules.

## Success criteria (Laravel)

- Unit tests (`TestCase` only) boot no Laravel app and use domain fakes (base rule).
- Integration / Feature tests use `RefreshDatabase` for DB isolation.
- `Mail::fake()` / `Queue::fake()` used only in Feature/Integration tests, not in unit tests.
- Every Eloquent Model declares `$fillable` explicitly — no `$guarded = []`.
- `config/hashing.php` sets `driver: argon2id`.
- All HTTP input validated through Form Requests (422 on failure); `$request->all()` never passed raw to `create()`.
- Both authenticated and unauthenticated paths tested in Feature tests.
