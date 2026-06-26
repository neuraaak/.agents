# Architecture & Design — Symfony (delta)

> **Delta** on `references/languages/php/architecture.md`. Load the PHP base
> file first; this file only adds or overrides what changes when Symfony is
> used. The Hexagonal layering, `interface` ports, `readonly` Value Objects,
> and fakes rules from the base still apply unchanged.

## Detection

`symfony/framework-bundle` in `composer.json`, or `bin/console` + `config/bundles.php` present in the project.

## Where Symfony sits in the Hexagonal layers

Symfony components belong to the **Infrastructure** layer — controllers, forms,
Doctrine entities, Messenger handlers, and the DI container are all adapters,
never domain logic.

```text
src/
├── Domain/                 ← zero Symfony import — base rule strictly applies
│   ├── Order.php           ← entity with behavior
│   └── ValueObject/
├── Application/            ← Use Cases + Port interfaces (no Symfony import)
│   ├── Port/
│   │   └── OrderRepositoryInterface.php
│   └── Handler/
│       └── PlaceOrderHandler.php
└── Infrastructure/         ← Symfony lives here
    ├── Persistence/
    │   └── DoctrineOrderRepository.php   ← implements Port
    ├── Http/
    │   └── OrderController.php           ← thin adapter
    ├── Messenger/
    │   └── PlaceOrderMessageHandler.php  ← async command bus adapter
    └── config/
        └── services.yaml                 ← composition root
```

## DI Container as composition root

Symfony's autowiring replaces the manual `ServiceProvider.php` from the base.
Wire interfaces to implementations in `config/services.yaml`, not inside the
domain or application layer:

```yaml
# config/services.yaml
services:
    _defaults:
        autowire: true
        autoconfigure: true

    App\Application\Port\OrderRepositoryInterface:
        class: App\Infrastructure\Persistence\DoctrineOrderRepository

    App\Application\Handler\PlaceOrderHandler:
        arguments:
            $repository: '@App\Application\Port\OrderRepositoryInterface'
```

Or use `#[Autowire]` on the adapter for explicit injection:

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence;

use App\Application\Port\OrderRepositoryInterface;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

final class DoctrineOrderRepository implements OrderRepositoryInterface
{
    public function __construct(
        #[Autowire(service: 'doctrine.orm.entity_manager')]
        private readonly EntityManagerInterface $em,
    ) {}
}
```

- Prefer constructor injection over `#[Autowire]` on properties — it stays
  testable with fakes.
- `services.yaml` is the single composition root; no service locator, no
  `ContainerInterface` injected into domain classes.

## Doctrine — adapter, not domain entity

Doctrine `Entity` classes are **infrastructure adapters** (ORM mapping), not
domain entities. Keep them separate and map explicitly at the repository boundary:

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Doctrine;

use Doctrine\ORM\Mapping as ORM;

// ORM entity — infrastructure only, no domain behavior
#[ORM\Entity]
#[ORM\Table(name: 'orders')]
class OrderRecord
{
    #[ORM\Id, ORM\GeneratedValue, ORM\Column]
    public int $id;

    #[ORM\Column(length: 20)]
    public string $status;
}
```

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence;

use App\Application\Port\OrderRepositoryInterface;
use App\Domain\Order;
use App\Infrastructure\Persistence\Doctrine\OrderRecord;
use Doctrine\ORM\EntityManagerInterface;

final class DoctrineOrderRepository implements OrderRepositoryInterface
{
    public function __construct(private readonly EntityManagerInterface $em) {}

    public function save(Order $order): void
    {
        $record         = new OrderRecord();
        $record->status = $order->status()->value;
        $this->em->persist($record);
        $this->em->flush();
    }

    public function findById(int $id): ?Order
    {
        $record = $this->em->find(OrderRecord::class, $id);
        if ($record === null) {
            return null;
        }
        return Order::reconstitute($record->id, $record->status);
    }
}
```

- Domain `Order` has **no Doctrine annotation** — it's a plain PHP class.
- `OrderRecord` has **no domain behavior** — it's a data-mapping struct.
- The repository is the only place that knows both representations.

## Controllers — thin inbound adapters

Controllers parse HTTP input, call a use case, and serialize the response.
No business logic in controllers:

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Http;

use App\Application\Handler\PlaceOrderHandler;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Validator\Validator\ValidatorInterface;

final class OrderController extends AbstractController
{
    public function __construct(
        private readonly PlaceOrderHandler  $handler,
        private readonly ValidatorInterface $validator,
    ) {}

    #[Route('/api/orders', methods: ['POST'])]
    public function create(Request $request): JsonResponse
    {
        $dto = new PlaceOrderDto($request->toArray());

        $errors = $this->validator->validate($dto);
        if (count($errors) > 0) {
            return $this->json(['errors' => (string) $errors], 422);
        }

        $order = $this->handler->handle($dto->orderId);

        return $this->json(['id' => $order->id()], 201);
    }
}
```

- `AbstractController` is allowed — it provides Symfony helpers (`json()`, `redirect()`).
- Inject the use case handler, never the repository directly into the controller.
- Return a `JsonResponse` / `Response`; let the use case do the work.

## Symfony Messenger — async command/event bus

Use Symfony Messenger to dispatch commands or domain events asynchronously.
The message handler is an **infrastructure adapter** around the use case:

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Messenger;

use App\Application\Command\PlaceOrderCommand;
use App\Application\Handler\PlaceOrderHandler;
use Symfony\Component\Messenger\Attribute\AsMessageHandler;

#[AsMessageHandler]
final class PlaceOrderMessageHandler
{
    public function __construct(private readonly PlaceOrderHandler $handler) {}

    public function __invoke(PlaceOrderCommand $command): void
    {
        $this->handler->handle($command->orderId);
    }
}
```

- The domain `PlaceOrderCommand` is a plain PHP object — no Messenger import.
- The `#[AsMessageHandler]` attribute is infrastructure; keep it out of
  `Application/`.

## Success criteria (Symfony)

- `Domain/` and `Application/` import no Symfony class — verified by PHPStan with
  the `phpstan-symfony` extension.
- Doctrine entities (`OrderRecord`) and domain entities (`Order`) are separate
  classes; mapped explicitly in the repository adapter.
- `config/services.yaml` is the sole composition root; no service-locator pattern
  (`ContainerInterface` injection) in domain or application classes.
- Controllers are thin: parse → validate → call use case → serialize. Zero
  business logic.
- Messenger handlers delegate to use cases; domain Command objects carry no
  Symfony import.
