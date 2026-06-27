# Architecture & Design — JavaScript / TypeScript

## Module organization

- **ESM-first**: `"type": "module"` in `package.json`. Always.
- **Feature-based**: organize by business domain (`user/`, `order/`), not by technical type (`models/`, `controllers/`).
- **Index files**: use `index.ts` only for public API boundaries — never as a dump of every export.
- **Barrel exports**: use sparingly; prefer explicit sub-path imports for better tree-shaking.

## Encapsulation

```typescript
class UserService {
  #database: Database;  // truly private field (ES2022+), not the TypeScript `private` keyword

  constructor(db: Database) {
    this.#database = db;
  }
}
```

Use `#field` (private class fields) rather than `private` — enforced at runtime, not just at compile time.

## Class vs functional style — choosing

| Criterion                               | Class      | Functional  |
| :-------------------------------------- | :--------- | :---------- |
| Internal mutable state (`#field`)       | ✅          | ❌           |
| Inheritance or interface implementation | ✅          | ❌           |
| Simple dependency injection             | Preference | ✅ (closure) |
| Testability and composition             | Complex    | ✅           |
| Stateless Repository / Service          | ❌          | ✅           |

```typescript
// Functional style — preferred for stateless repositories
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

// Class style — justified when there is internal state or an interface contract
export class CachingUserRepository implements UserRepository {
  #cache = new Map<UserId, User>();

  constructor(private readonly inner: UserRepository) {}

  async findById(id: UserId): Promise<User | null> {
    return this.#cache.get(id) ?? this.inner.findById(id);
  }
}
```

## Value Objects — branded types

Encapsulate primitives with strong semantics to avoid Primitive Obsession.

```typescript
// Branded types — prevent semantic mixing at compile time
type UserId = number & { readonly __brand: "UserId" };
type OrderId = number & { readonly __brand: "OrderId" };

function asUserId(id: number): UserId {
  return id as UserId;
}

// Impossible to pass an OrderId where a UserId is expected
function getUser(id: UserId): Promise<User> { /* ... */ }

// Value Object with validation
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

## TypeScript type system (TS 5.x)

```typescript
// strict: true in tsconfig.json — non-negotiable
// Prefer interface for shapes, type for unions/intersections

interface User {
  id: UserId;
  email: string;
}

type Status = "pending" | "active" | "closed";

// satisfies — validates the type without losing literal inference
const config = {
  host: "localhost",
  port: 8080,
} satisfies Record<string, string | number>;
// config.port is still 8080 (literal), not just number

// unknown + narrowing — never any
function parseInput(raw: unknown): string {
  if (typeof raw !== "string") throw new Error("Expected string");
  return raw;
}
```

Zero `any`. Use `unknown` when the type is genuinely uncertain, then narrow explicitly.

## Hexagonal — Ports & Adapters

Interfaces (or object shapes) act as Ports. Implementations are the Adapters.

```typescript
// application/ports.ts — Port as an interface
export interface OrderRepository {
  save(order: Order): Promise<void>;
  findById(id: OrderId): Promise<Order | null>;
}

// infrastructure/sql-order-repo.ts — Adapter
export class SQLOrderRepository implements OrderRepository {
  async save(order: Order): Promise<void> { /* SQL here */ }
  async findById(id: OrderId): Promise<Order | null> { /* SQL here */ }
}

// tests/fakes.ts — Fake for tests
export function createInMemoryOrderRepository(): OrderRepository {
  const store = new Map<OrderId, Order>();
  return {
    async save(order) { store.set(order.id, order); },
    async findById(id) { return store.get(id) ?? null; },
  };
}
```

## Enforcing module boundaries

The layering rules above must be machine-checked, not just documented:

- **dependency-cruiser** — declare architectural rules as code (no cycles, `infrastructure/` may not be imported by `domain/`) and gate them in CI. Supports ESM, CommonJS, and TS paths; exports a graph for visualization. `madge` is a lighter alternative for quick cycle detection / graph exploration, but doesn't enforce custom rules.
- **knip** — detects dead code: unused exports, unreferenced files, orphaned types, and unused dependencies that neither ESLint nor `tsc` flag. Run in CI on growing projects to stop dead-code accumulation.

## Success criteria

- `strict: true` in `tsconfig.json`.
- Zero `any` — use `unknown` + type narrowing.
- `#private` fields for true encapsulation.
- Feature-based module organization.
- Repository pattern abstracts all data access.
- Module boundaries enforced by `dependency-cruiser` rules in CI (no cycles, no inward violations).
- `satisfies` for object-literal validation.
- Branded types or Value Objects for primitives with strong semantics.
- Fakes (not mocks) for testing Ports.
