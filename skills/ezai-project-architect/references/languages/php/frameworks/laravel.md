# Architecture & Design — Laravel (delta)

> **Delta** on `references/languages/php/architecture.md`. Load the PHP base
> file first; this file only adds or overrides what changes when Laravel is
> used. The `interface` ports, `readonly` Value Objects, and fakes rules from
> the base still apply unchanged.

## Detection

`laravel/framework` in `composer.json`, or `artisan` + `bootstrap/app.php` present in the project.

## Where Laravel sits in the Hexagonal layers

Laravel components belong to the **Infrastructure** layer — Eloquent models,
controllers, listeners, jobs, and service providers are adapters, never domain
logic.

```text
app/
├── Domain/                 ← zero Laravel import — base rule strictly applies
│   ├── Order.php           ← entity with behavior (no Eloquent)
│   └── ValueObject/
├── Application/            ← Use Cases + Port interfaces (zero Laravel import)
│   ├── Port/
│   │   └── OrderRepositoryInterface.php
│   └── Handler/
│       └── PlaceOrderHandler.php
└── Infrastructure/         ← Laravel lives here
    ├── Persistence/
    │   ├── Eloquent/
    │   │   └── OrderModel.php         ← Eloquent Model (ORM mapping only)
    │   └── EloquentOrderRepository.php ← implements Port, maps Model ↔ Entity
    ├── Http/
    │   ├── Controllers/
    │   │   └── OrderController.php    ← thin adapter
    │   └── Requests/
    │       └── PlaceOrderRequest.php  ← Form Request (input validation)
    ├── Events/
    │   └── OrderPlaced.php            ← Laravel Event (infrastructure adapter)
    └── Listeners/
        └── SendOrderConfirmation.php  ← Listener (infrastructure side-effect)
Providers/
    └── AppServiceProvider.php         ← composition root
```

## Eloquent Model vs Domain Entity — keep them separate

Eloquent `Model` is an **ORM adapter** (Infrastructure), not a domain entity.
Map explicitly between the two at the repository boundary:

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use Illuminate\Database\Eloquent\Model;

// Eloquent model — infrastructure only, no domain behavior
final class OrderModel extends Model
{
    protected $table = 'orders';

    protected $fillable = ['status', 'customer_email'];

    // No domain methods — data mapping only
}
```

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence;

use App\Application\Port\OrderRepositoryInterface;
use App\Domain\Order;
use App\Infrastructure\Persistence\Eloquent\OrderModel;

final class EloquentOrderRepository implements OrderRepositoryInterface
{
    public function save(Order $order): void
    {
        OrderModel::updateOrCreate(
            ['id' => $order->id()],
            [
                'status'         => $order->status()->value,
                'customer_email' => $order->customerEmail()->value,
            ]
        );
    }

    public function findById(int $id): ?Order
    {
        $model = OrderModel::find($id);
        if ($model === null) {
            return null;
        }
        return Order::reconstitute($model->id, $model->status, $model->customer_email);
    }
}
```

- Domain `Order` has **no Eloquent import** — it's a plain PHP class.
- `OrderModel` has **no domain behavior** — it's a data-mapping struct.
- `$fillable` must be explicit (quality rule — no `$guarded = []`).

## Facades — boundary rule

Laravel facades provide static access to services. They are **allowed only in
Infrastructure**, never in Domain or Application layers:

```php
// ❌ Application layer — breaks testability and hexagonal isolation
namespace App\Application\Handler;

use Illuminate\Support\Facades\Mail;

class PlaceOrderHandler {
    public function handle(int $id): Order {
        Mail::send(...);  // facade in Application = hard dependency on Laravel
    }
}

// ✅ Infrastructure layer — facade as adapter behind a Port
namespace App\Infrastructure\Mail;

use App\Application\Port\OrderMailerInterface;
use App\Domain\Order;
use Illuminate\Support\Facades\Mail;

final class LaravelOrderMailer implements OrderMailerInterface
{
    public function sendConfirmation(Order $order): void
    {
        Mail::to($order->customerEmail()->value)->send(new OrderConfirmedMail($order));
    }
}
```

- Domain and Application reference `OrderMailerInterface` (port) — they never
  import a facade.
- `LaravelOrderMailer` implements the port using the `Mail` facade — the domain
  never sees it.

## Service Providers — composition root

`AppServiceProvider` (or a dedicated provider) is the composition root — it wires
interfaces to implementations, replacing the manual `ServiceProvider.php` from the
base:

```php
<?php

declare(strict_types=1);

namespace App\Providers;

use App\Application\Port\OrderRepositoryInterface;
use App\Application\Port\OrderMailerInterface;
use App\Infrastructure\Persistence\EloquentOrderRepository;
use App\Infrastructure\Mail\LaravelOrderMailer;
use Illuminate\Support\ServiceProvider;

final class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(OrderRepositoryInterface::class, EloquentOrderRepository::class);
        $this->app->bind(OrderMailerInterface::class, LaravelOrderMailer::class);
    }
}
```

- One binding per port — no service locator (`app('key')`) in Domain or
  Application code.
- Controllers receive their use-case handlers via constructor injection (Laravel
  resolves them automatically from the container).

## Controllers — thin inbound adapters

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Http\Controllers;

use App\Application\Handler\PlaceOrderHandler;
use App\Infrastructure\Http\Requests\PlaceOrderRequest;
use Illuminate\Http\JsonResponse;

final class OrderController
{
    public function __construct(
        private readonly PlaceOrderHandler $handler,
    ) {}

    public function store(PlaceOrderRequest $request): JsonResponse
    {
        $order = $this->handler->handle($request->integer('id'));
        return response()->json(['id' => $order->id()], 201);
    }
}
```

- Inject the use-case handler, never the repository directly.
- `PlaceOrderRequest` handles validation — the controller never calls `validate()`.
- No business logic; no Eloquent queries in controllers.

## Events / Listeners — infrastructure side-effects only

Laravel Events and Listeners are **infrastructure adapters** for side-effects
(email, notifications, audit log). Business rules belong in use cases, not
listeners:

```php
// ❌ business logic in a listener — hidden coupling
class OrderPlacedListener {
    public function handle(OrderPlaced $event): void {
        if ($event->order->totalExceedsLimit()) { // domain rule leaking to infra
            $this->flagForReview($event->order);
        }
    }
}

// ✅ explicit use case — side-effects delegated to ports
class PlaceOrderHandler {
    public function handle(int $id): Order {
        $order = $this->repository->save(Order::place($id));
        $this->mailer->sendConfirmation($order);   // port — testable with fake
        return $order;
    }
}
```

- Listeners handle infrastructure concerns only: sending mail, queuing jobs,
  writing audit logs.
- Business invariants live in use cases and domain entities — never in event handlers.

## Success criteria (Laravel)

- `Domain/` and `Application/` import no Laravel or Eloquent class — verified by
  PHPStan with the Larastan extension.
- Eloquent `OrderModel` and domain `Order` are separate classes; mapped explicitly
  in `EloquentOrderRepository`.
- `AppServiceProvider` is the sole composition root; no `app()` / `resolve()`
  calls in Domain or Application layers.
- Facades (`Mail`, `Queue`, `Http`, `Storage`) appear only in Infrastructure —
  Domain and Application reference Port interfaces only.
- Controllers are thin: receive a Form Request + call a use case + return a
  response. Zero business logic.
- Listeners handle infrastructure side-effects only; business rules live in use
  cases.
