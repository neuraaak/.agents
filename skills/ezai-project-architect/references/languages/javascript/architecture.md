# Architecture & Design — JavaScript / TypeScript

## Organisation des modules

- **ESM-first** : `"type": "module"` dans `package.json`. Toujours.
- **Feature-based** : organiser par domaine métier (`user/`, `order/`), pas par type technique (`models/`, `controllers/`).
- **Index files** : utiliser `index.ts` uniquement pour les frontières d'API publique — jamais comme dump de tous les exports.
- **Barrel exports** : utiliser avec parcimonie ; préférer les imports de sous-chemin explicites pour un meilleur tree-shaking.

## Encapsulation

```typescript
class UserService {
  #database: Database;  // champ vraiment privé (ES2022+), pas le keyword TypeScript private

  constructor(db: Database) {
    this.#database = db;
  }
}
```

Utiliser `#field` (private class fields) plutôt que `private` — appliqué au runtime, pas seulement à la compilation.

## Class vs style fonctionnel — guide de choix

| Critère                                | Classe           | Fonctionnel |
| :------------------------------------- | :--------------- | :---------- |
| État mutable interne (`#field`)        | ✅                | ❌           |
| Héritage ou implémentation d'interface | ✅                | ❌           |
| Injection de dépendances simple        | Selon préférence | ✅ (closure) |
| Testabilité et composition             | Complexe         | ✅           |
| Repository / Service sans état         | ❌                | ✅           |

```typescript
// Style fonctionnel — préféré pour les repositories sans état
export function createUserRepository(db: Database) {
  return {
    async findById(id: UserId): Promise<User | null> {
      return db.query("SELECT * FROM users WHERE id = ?", [id]);
    },
    async save(user: User): Promise<void> {
      return db.execute("INSERT INTO users ...", user);
    },
  };
}

// Style classe — justifié quand il y a de l'état interne ou un contrat d'interface
export class CachingUserRepository implements UserRepository {
  #cache = new Map<UserId, User>();

  constructor(private readonly inner: UserRepository) {}

  async findById(id: UserId): Promise<User | null> {
    return this.#cache.get(id) ?? this.inner.findById(id);
  }
}
```

## Value Objects — branded types

Encapsuler les primitives à sémantique forte pour éviter la Primitive Obsession.

```typescript
// Branded types — empêchent le mélange sémantique à la compilation
type UserId = number & { readonly __brand: "UserId" };
type OrderId = number & { readonly __brand: "OrderId" };

function asUserId(id: number): UserId {
  return id as UserId;
}

// Impossible de passer un OrderId là où un UserId est attendu
function getUser(id: UserId): Promise<User> { /* ... */ }

// Value Object avec validation
class Money {
  readonly #amount: number;
  readonly #currency: string;

  constructor(amount: number, currency: string) {
    if (amount < 0) throw new Error("Amount cannot be negative");
    this.#amount = amount;
    this.#currency = currency;
  }

  equals(other: Money): boolean {
    return this.#amount === other.#amount && this.#currency === other.#currency;
  }
}
```

## Système de types TypeScript (TS 5.x)

```typescript
// strict: true dans tsconfig.json — non négociable
// Préférer interface pour les shapes, type pour les unions/intersections

interface User {
  id: UserId;
  email: string;
}

type Status = "pending" | "active" | "closed";

// satisfies — valide le type sans perdre l'inférence littérale
const config = {
  host: "localhost",
  port: 8080,
} satisfies Record<string, string | number>;
// config.port est encore 8080 (littéral), pas juste number

// unknown + narrowing — jamais any
function parseInput(raw: unknown): string {
  if (typeof raw !== "string") throw new Error("Expected string");
  return raw;
}
```

Zéro `any`. Utiliser `unknown` quand le type est vraiment incertain, puis narrower explicitement.

## Hexagonal — Ports & Adapters

Les interfaces (ou object shapes) jouent le rôle de Ports. Les implémentations sont les Adapters.

```typescript
// application/ports.ts — Port comme interface
export interface OrderRepository {
  save(order: Order): Promise<void>;
  findById(id: OrderId): Promise<Order | null>;
}

// infrastructure/sql-order-repo.ts — Adapter
export class SQLOrderRepository implements OrderRepository {
  async save(order: Order): Promise<void> { /* SQL ici */ }
  async findById(id: OrderId): Promise<Order | null> { /* SQL ici */ }
}

// tests/fakes.ts — Fake pour les tests
export function createInMemoryOrderRepository(): OrderRepository {
  const store = new Map<OrderId, Order>();
  return {
    async save(order) { store.set(order.id, order); },
    async findById(id) { return store.get(id) ?? null; },
  };
}
```

## Critères de succès

- `strict: true` dans `tsconfig.json`.
- Zéro `any` — utiliser `unknown` + type narrowing.
- `#private` fields pour la vraie encapsulation.
- Organisation feature-based des modules.
- Repository pattern abstrait tout accès aux données.
- `satisfies` pour la validation des object literals.
- Branded types ou Value Objects pour les primitives à sémantique forte.
- Fakes (pas de mocks) pour tester les Ports.
