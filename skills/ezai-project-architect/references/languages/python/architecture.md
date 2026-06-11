# Architecture & Design — Python

## Visibilité & surface d'API

| Préfixe  | Signification | Usage                                                           |
| :------- | :------------ | :-------------------------------------------------------------- |
| `name`   | Public        | Symboles externes ; lister dans `__all__`                       |
| `_name`  | Protégé       | Interne ; stable dans le module, pas un contrat externe         |
| `__name` | Privé         | Évitement de collision de noms dans les sous-classes uniquement |

Toujours définir `__all__` dans les modules qui exportent une API publique :

```python
__all__ = ["Processor", "Status"]
```

## Design patterns

```python
from enum import Enum
from typing import Protocol, TypedDict

# Préférer Enum aux constantes string nues
class Status(Enum):
    PENDING = "pending"
    ACTIVE = "active"

# Protocol pour les contrats structurels (duck typing) — pas abc.ABC
class OrderRepository(Protocol):
    def save(self, order: Order) -> None: ...
    def find_by_id(self, order_id: int) -> Order | None: ...

# Factory via classmethod — éviter @staticmethod
class Processor:
    def __init__(self, name: str) -> None:
        self._name = name

    @classmethod
    def from_config(cls, config: dict[str, str]) -> Processor:
        return cls(config["name"])
```

## Value Objects — `@dataclass(frozen=True)`

Un Value Object encapsule une primitive à sémantique forte. Immuable, comparable par valeur, sans identité propre.

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class Money:
    amount: int  # centimes — jamais de float pour les montants
    currency: str

    def __post_init__(self) -> None:
        if self.amount < 0:
            raise ValueError("Amount cannot be negative")

@dataclass(frozen=True)
class EmailAddress:
    value: str

    def __post_init__(self) -> None:
        if "@" not in self.value:
            raise ValueError(f"Invalid email: {self.value}")

# Usage : Money(1000, "EUR") != Money(1000, "USD")
# Les entités domain utilisent des Value Objects, pas des primitives nues
```

## `dataclass` vs `TypedDict` — guide de choix

| Critère                                   | `@dataclass`   | `TypedDict` |
| :---------------------------------------- | :------------- | :---------- |
| Comportement (méthodes, validation)       | ✅              | ❌           |
| Immuabilité (`frozen=True`)               | ✅              | ❌           |
| Données externes sans logique (JSON, API) | ❌              | ✅           |
| Zéro overhead runtime                     | ❌              | ✅           |
| Value Objects domain                      | ✅              | ❌           |
| Schéma de données structuré               | Selon contexte | ✅           |

```python
# TypedDict — données externes structurées sans logique
class UserData(TypedDict):
    id: int
    email: str

# dataclass — entité avec comportement ou immuabilité
@dataclass
class User:
    id: int
    email: EmailAddress

    def change_email(self, new_email: EmailAddress) -> "User":
        return User(id=self.id, email=new_email)
```

## Système de types

```python
from __future__ import annotations
from typing import Protocol, TypedDict, Literal, Annotated, Mapping

# Génériques natifs (pas typing.List / typing.Dict)
items: list[str]
counts: dict[str, int]

# Literal — ensemble de valeurs fixes
Status = Literal["pending", "active", "closed"]

# Config immuable — Mapping, ou frozendict en 3.14+
Config = Mapping[str, str]
```

Zéro `Any`. Utiliser `object` ou `Unknown` (ty) quand le type est vraiment inconnu.

## Structure hexagonale

```text
src/
├── domain/          ← Entités, Value Objects (zéro imports externes)
├── application/     ← Use Cases + Ports (interfaces Protocol)
└── infrastructure/  ← Adapters (DB, APIs) + Composition Root
```

Règle de dépendance : **toujours vers l'intérieur** — Infrastructure → Application → Domain.

```python
# application/ports.py — Port comme Protocol (couche Application)
class OrderRepository(Protocol):
    def save(self, order: Order) -> None: ...

# infrastructure/adapters/sql_orders.py — Adapter (couche Infrastructure)
class SQLOrderRepository:
    def save(self, order: Order) -> None:
        ...  # SQLAlchemy ici — le Domain ne voit jamais ceci
```

Les entités domain contiennent la business logic — pas de simple sacs de données (éviter l'Anemic Domain Model).

## Fakes pour les tests de Ports

Préférer les fakes (implémentations légères en mémoire) aux mocks complexes pour tester les Ports.

```python
# tests/fakes.py — Fake du Port OrderRepository
class InMemoryOrderRepository:
    def __init__(self) -> None:
        self._store: dict[int, Order] = {}

    def save(self, order: Order) -> None:
        self._store[order.id] = order

    def find_by_id(self, order_id: int) -> Order | None:
        return self._store.get(order_id)

# Dans le test — pas de mock.patch, pas de MagicMock
def test_process_order() -> None:
    repo = InMemoryOrderRepository()
    service = OrderService(repo)
    service.process(order_id=1)
    assert repo.find_by_id(1) is not None
```

## Critères de succès

- `__all__` définit la surface publique explicite.
- `Protocol` utilisé pour tous les contrats structurels, pas `abc.ABC`.
- Pas d'imports infrastructure dans Domain ou Application.
- Fakes (pas de mocks complexes) utilisés pour tester les Ports.
- `@dataclass(frozen=True)` pour les Value Objects immuables.
- `TypedDict` pour les données externes sans logique.
- `from __future__ import annotations` en tête de chaque fichier.
- Zéro `Any`, zéro `typing.List`/`typing.Dict`.
