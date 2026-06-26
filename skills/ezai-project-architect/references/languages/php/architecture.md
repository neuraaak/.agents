# Architecture & Design — PHP

## Visibility & API surface

| Keyword     | Meaning   | Usage                                                                     |
| :---------- | :-------- | :------------------------------------------------------------------------ |
| `public`    | Public    | External contract — changes are breaking                                  |
| `protected` | Protected | Inheritance contract — keep minimal; prefer composition over inheritance  |
| `private`   | Private   | Encapsulated detail — default for all properties; expose via methods only |

```php
<?php

declare(strict_types=1);

namespace App\Domain;

final class Order
{
    private int    $id;
    private Status $status;

    // Expose only what the domain model needs to reveal
    public function id(): int      { return $this->id; }
    public function status(): Status { return $this->status; }

    // Behavior on the entity — not a plain data bag
    public function confirm(): void
    {
        if ($this->status !== Status::Pending) {
            throw new \DomainException('Only pending orders can be confirmed');
        }
        $this->status = Status::Confirmed;
    }
}
```

- Declare all properties `private` by default; expose via methods.
- Mark classes `final` unless designed for inheritance.
- No public properties on Entities (use `readonly` on Value Objects only).

## Design patterns

```php
<?php

declare(strict_types=1);

namespace App\Application\Port;

// Interface for structural contracts — not abstract classes as the primary abstraction
interface OrderRepositoryInterface
{
    public function save(Order $order): void;
    public function findById(int $id): ?Order;
    /** @return list<Order> */
    public function findByStatus(Status $status): array;
}

// Enum (8.1+) for finite state — never bare string/int constants
enum Status: string
{
    case Pending   = 'pending';
    case Confirmed = 'confirmed';
    case Cancelled = 'cancelled';
}

// Factory via named constructor — avoid `new` in business logic
final class Order
{
    private function __construct(
        private int    $id,
        private Status $status,
    ) {}

    public static function place(int $id): self
    {
        return new self($id, Status::Pending);
    }
}
```

## Value Objects — `readonly` class (PHP 8.2+)

A Value Object encapsulates a primitive with strong semantics. Immutable, compared by value, no identity of its own.

```php
<?php

declare(strict_types=1);

namespace App\Domain\ValueObject;

// readonly class (8.2+) — all properties readonly, no setters
readonly class Money
{
    public function __construct(
        public int    $amount,    // cents — never float for monetary values
        public string $currency,
    ) {
        if ($this->amount < 0) {
            throw new \InvalidArgumentException('Amount cannot be negative');
        }
        if (!preg_match('/^[A-Z]{3}$/', $this->currency)) {
            throw new \InvalidArgumentException("Invalid currency code: {$this->currency}");
        }
    }

    public function add(self $other): self
    {
        if ($this->currency !== $other->currency) {
            throw new \DomainException('Cannot add different currencies');
        }
        return new self($this->amount + $other->amount, $this->currency);
    }

    public function equals(self $other): bool
    {
        return $this->amount === $other->amount && $this->currency === $other->currency;
    }
}

readonly class EmailAddress
{
    public function __construct(public string $value)
    {
        if (!filter_var($this->value, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException("Invalid email: {$this->value}");
        }
    }
}
```

- Use `readonly class` (8.2+) — PHP enforces immutability at the engine level.
- On PHP 8.1, use `readonly` on individual properties + `private __clone()` to prevent cloning.
- Validate invariants in the constructor — throw `\InvalidArgumentException` on bad input.
- Implement equality via an `equals()` method — PHP has no `__equals` magic.

## Type system

```php
<?php

declare(strict_types=1);

namespace App\Domain;

// Union types (8.0+)
function findUser(int|string $idOrEmail): ?User { ... }

// Intersection types (8.1+) — Countable AND Traversable
function process(Countable&\Traversable $collection): void { ... }

// never return type — function that always throws or exits
function fail(string $message): never
{
    throw new \RuntimeException($message);
}

// Nullsafe operator (8.0+)
$city = $user?->getAddress()?->getCity();

// Named arguments (8.0+) — use on multi-param calls for readability
$result = array_slice(array: $items, offset: 2, length: 5, preserve_keys: true);

// Fibers (8.1+) — cooperative multitasking (used by ReactPHP/Revolt internally)
$fiber = new \Fiber(function (): void {
    $value = \Fiber::suspend('fiber started');
    echo "fiber received: {$value}\n";
});
```

- `declare(strict_types=1)` everywhere — disables implicit type coercion.
- Prefer union types over nullable when both non-null branches are semantically valid.
- Use `never` return type for functions that unconditionally throw or exit.
- Avoid `mixed` — be explicit; use union types instead.

## Hexagonal structure

```text
src/
├── Domain/                 ← Entities, Value Objects, Enums, Domain Events (zero framework imports)
│   ├── Order.php
│   ├── ValueObject/
│   │   └── Money.php
│   └── Event/
│       └── OrderPlaced.php
├── Application/            ← Use Cases (Command/Query handlers) + Port interfaces
│   ├── Port/
│   │   └── OrderRepositoryInterface.php
│   └── Handler/
│       └── PlaceOrderHandler.php
└── Infrastructure/         ← Adapters (DB, HTTP, Queue) + Composition Root
    ├── Persistence/
    │   └── DoctrineOrderRepository.php
    ├── Http/
    │   └── OrderController.php
    └── ServiceProvider.php  ← Composition root — wires interfaces to adapters
```

Dependency rule: **always inward** — Infrastructure → Application → Domain. The Domain knows nothing of Doctrine, HTTP, or any framework.

```php
<?php

declare(strict_types=1);

namespace App\Application\Port;

// Port as an interface in the Application layer
interface OrderRepositoryInterface
{
    public function save(Order $order): void;
    public function findById(int $id): ?Order;
}

// ---

namespace App\Infrastructure\Persistence;

use App\Application\Port\OrderRepositoryInterface;
use App\Domain\Order;

// Adapter in Infrastructure — Domain never sees Doctrine
final class DoctrineOrderRepository implements OrderRepositoryInterface
{
    public function __construct(private readonly \Doctrine\ORM\EntityManagerInterface $em) {}

    public function save(Order $order): void
    {
        $this->em->persist($order);
        $this->em->flush();
    }

    public function findById(int $id): ?Order
    {
        return $this->em->find(Order::class, $id);
    }
}
```

## Fakes for Port tests

Prefer fakes (lightweight in-memory implementations) over `createMock()` for testing Ports.

```php
<?php

declare(strict_types=1);

namespace App\Tests\Fake;

use App\Application\Port\OrderRepositoryInterface;
use App\Domain\Order;

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
}

// In the test — no createMock(), no Prophecy, pure PHP
final class PlaceOrderHandlerTest extends \PHPUnit\Framework\TestCase
{
    #[\PHPUnit\Framework\Attributes\Test]
    public function it_persists_a_new_order(): void
    {
        $repo    = new InMemoryOrderRepository();
        $handler = new PlaceOrderHandler($repo);

        $handler->handle(new PlaceOrderCommand(orderId: 42));

        self::assertNotNull($repo->findById(42));
    }
}
```

## Success criteria

- `declare(strict_types=1)` at the top of every PHP file.
- `final` on all classes not designed for inheritance.
- `interface` for all structural contracts (never `abstract class` as the primary abstraction).
- `readonly class` (8.2+) for immutable Value Objects with constructor validation.
- `enum` (8.1+) for all finite state — no bare string/int constants.
- No infrastructure imports in Domain or Application layers.
- Fakes (not mocks) used to test Port implementations.
- All properties declared `private`; behavior exposed via methods.
- Zero `mixed`, zero undeclared return types.
