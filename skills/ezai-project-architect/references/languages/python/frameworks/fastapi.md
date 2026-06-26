# Architecture & Design — FastAPI (delta)

> **Delta** on `references/languages/python/architecture.md`. Load the Python
> base file first; this file only adds or overrides what changes when FastAPI is
> used. The Hexagonal layering, `Protocol` ports, Value Objects, and fakes rules
> from the base still apply unchanged.

## Detection

`fastapi` in `dependencies`, or an ASGI entrypoint (`uvicorn`/`hypercorn`) in the
project.

## Where FastAPI sits in the Hexagonal layers

FastAPI is an **inbound adapter** — it belongs to Infrastructure, never to
Domain or Application. The base dependency rule (always inward) means routers
call use cases; use cases never import `fastapi`.

```text
src/app/
├── domain/          ← Entities, Value Objects (no fastapi import — base rule)
├── application/     ← Use cases + Ports (Protocol) — no fastapi import
├── infrastructure/  ← SQL adapters, Composition Root
└── api/             ← FastAPI routers + Depends wiring (inbound adapter)
    ├── main.py      ← FastAPI() + include_router
    ├── deps.py      ← Depends providers (wire ports → adapters)
    └── routers/
```

- Keep `app = FastAPI()` and `include_router` in `api/`, not at project root.
- A route handler is thin: parse/validate → call a use case → map to response.
  No business logic in the handler (avoid the Anemic Domain — base rule).

## `Depends` = the Ports & Adapters seam

FastAPI's `Depends` is the framework-native injection point for the base
**Protocol ports**. Type the provider's return as the Protocol, return the
concrete adapter — handlers depend on the interface, tests override the provider.

```python
# api/deps.py — wire the Port to its Adapter
from typing import Annotated
from fastapi import Depends
from application.ports import OrderRepository      # Protocol (base rule)
from infrastructure.sql_orders import SQLOrderRepository

def get_order_repository() -> OrderRepository:     # return type = the Port
    return SQLOrderRepository()

RepoDep = Annotated[OrderRepository, Depends(get_order_repository)]

# api/routers/orders.py — handler depends on the Port, not the adapter
@router.get("/orders/{order_id}")
def read_order(order_id: int, repo: RepoDep) -> OrderRead:
    order = repo.find_by_id(order_id)
    if order is None:
        raise HTTPException(status_code=404)
    return OrderRead.model_validate(order)
```

- Tests swap the implementation via `app.dependency_overrides[get_order_repository]`
  with the in-memory fake (base rule: fakes over mocks). See the quality skill's
  FastAPI delta.
- Use `Annotated[..., Depends(...)]` aliases — not bare `= Depends(...)` defaults.

## Pydantic models vs domain — keep them separate

Pydantic request/response models are **DTOs at the boundary**, the typed
equivalent of the base `TypedDict` "external data without logic" rule. Do not let
them leak into the Domain — map to/from Value Objects and entities.

```python
class OrderCreate(BaseModel):     # inbound DTO — validation only
    customer_email: str

class OrderRead(BaseModel):       # outbound DTO
    id: int
    status: str
    model_config = {"from_attributes": True}  # map from a domain entity
```

- Domain entities keep behavior and Value Objects (`EmailAddress`, `Money` —
  base rule); the router converts DTO ↔ domain at the edge.
- Never expose a SQLAlchemy model directly as a response model.

## Success criteria (FastAPI)

- FastAPI lives in an inbound adapter layer (`api/`); Domain/Application never import `fastapi`.
- Route handlers are thin: validate → use case → response; no business logic.
- Ports wired via `Depends` typed to the Protocol; `Annotated[...]` aliases used.
- Tests override providers with in-memory fakes (`app.dependency_overrides`).
- Pydantic models are boundary DTOs, mapped to/from Value Objects — not the Domain itself.
- No SQLAlchemy model exposed directly as a response schema.
