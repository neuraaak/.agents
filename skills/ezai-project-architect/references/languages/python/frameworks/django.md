# Architecture & Design — Django (delta)

> **Delta** on `references/languages/python/architecture.md`. Load the Python
> base file first; this file only adds or overrides what changes when Django is
> used. The Hexagonal layering, `Protocol` ports, Value Objects, and fakes rules
> from the base still apply unchanged.

## Detection

`django` in `dependencies`, or a `manage.py` / `DJANGO_SETTINGS_MODULE` present
in the project.

## Where Django sits in the Hexagonal layers

Django's ORM, views, and URLs are **infrastructure** — they belong to the
outermost layer, never to Domain or Application.

```text
src/apps/{name}/
  domain/          ← Entities, Value Objects (no Django import — base rule)
  application/     ← Use cases + Ports (Protocol) — no Django import
  infrastructure/
    orm/           ← Django models + adapters implementing Ports
    views/         ← Django views / DRF ViewSets (inbound adapters)
    urls.py        ← URL routing
```

- Keep domain logic out of Django `Model` methods — push it into domain entities.
- A view is thin: parse request → call a use case → serialize response. No
  business logic in the view (avoid Anemic Domain — base rule).

## Django Model vs Domain Entity — keep them separate

Django `Model` is an ORM mapping (infrastructure), not a domain entity. Map
explicitly between the two at the adapter boundary.

```python
# infrastructure/orm/order_model.py
from django.db import models

class OrderModel(models.Model):
    status = models.CharField(max_length=20)
    customer_email = models.EmailField()

    class Meta:
        db_table = "orders"

# infrastructure/orm/django_order_repository.py
from domain.order import Order          # domain entity
from application.ports import OrderRepository  # Protocol port (base rule)

class DjangoOrderRepository(OrderRepository):
    def find_by_id(self, order_id: int) -> Order | None:
        try:
            m = OrderModel.objects.get(pk=order_id)
            return Order(id=m.pk, status=m.status, email=m.customer_email)
        except OrderModel.DoesNotExist:
            return None
```

- Domain `Order` is a plain dataclass/Value Object with behavior.
- `DjangoOrderRepository` implements the `OrderRepository` Protocol and maps
  `OrderModel` ↔ `Order` — neither layer knows the other's internals.

## Apps as bounded contexts

Each Django app should map to one bounded context. Resist the Django default of
one flat app with all models.

```text
apps/
  orders/      ← Order aggregate, fulfilment workflows
  catalogue/   ← Product, SKU, pricing
  accounts/    ← User, auth, profile
```

- Apps cross-communicate through **use case calls** or **domain events** — never
  via direct `ForeignKey` to another app's model.
- If two apps must share a model, they likely belong in the same context.

## Signals — avoid for business logic

Django signals (`post_save`, `pre_delete`, …) are implicit side-effects that
scatter business logic and make testing hard. Reserve them for infrastructure
concerns (cache invalidation, audit logging); put business rules in use cases.

```python
# ❌ business logic in a signal
@receiver(post_save, sender=Order)
def send_confirmation(sender, instance, created, **kwargs):
    if created:
        email_service.send_confirmation(instance)  # hidden coupling

# ✅ explicit use case
class PlaceOrderUseCase:
    def execute(self, command: PlaceOrderCommand) -> Order:
        order = self.repository.save(Order.new(command))
        self.email_service.send_confirmation(order)  # explicit, testable
        return order
```

## Views / ViewSets — thin adapters

```python
# infrastructure/views/order_views.py (DRF)
from rest_framework.views import APIView
from rest_framework.response import Response
from application.place_order import PlaceOrderUseCase, PlaceOrderCommand

class OrderView(APIView):
    def __init__(self, use_case: PlaceOrderUseCase, **kwargs):
        super().__init__(**kwargs)
        self.use_case = use_case  # injected from urls.py (composition root)

    def post(self, request):
        cmd = PlaceOrderCommand(**request.data)
        order = self.use_case.execute(cmd)
        return Response({"id": order.id}, status=201)
```

Wire the use case at the URL layer (composition root), not inside the view:

```python
# infrastructure/urls.py
from .views.order_views import OrderView
from .orm.django_order_repository import DjangoOrderRepository
from application.place_order import PlaceOrderUseCase

urlpatterns = [
    path("orders/", OrderView.as_view(
        use_case=PlaceOrderUseCase(repository=DjangoOrderRepository())
    )),
]
```

## Success criteria (Django)

- Django `Model` and domain entities are separate classes; mapped at the
  repository boundary — no business logic in `Model` methods.
- Apps correspond to bounded contexts; cross-app communication goes through use
  cases, not direct ORM `ForeignKey` across app boundaries.
- Signals used only for infrastructure concerns (cache, audit); business logic
  lives in use cases.
- Views/ViewSets are thin adapters; use cases injected at the URL layer
  (composition root), making them testable with fakes.
- Domain and Application layers import no Django module.
