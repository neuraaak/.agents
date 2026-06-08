# Architecture & Design — JavaScript / TypeScript

## Module organization

- **ESM-first:** `"type": "module"` in `package.json`. Always.
- **Feature-based:** Organize by business domain (`user/`, `order/`), not technical type (`models/`, `controllers/`).
- **Index files:** Use `index.ts` only for public API boundaries — never as a dump of all exports.
- **Barrel exports:** Use sparingly; prefer explicit subpath imports for better tree-shaking.

## Encapsulation

```typescript
class UserService {
  #database: Database;  // true private field (ES2022+), not TypeScript private

  constructor(db: Database) {
    this.#database = db;
  }
}
```

Use `#field` (private class fields) over `private` keyword — enforced at runtime, not just compile time.

## Design patterns

```typescript
// Repository pattern — functional style
export function createUserRepository(db: Database) {
  return {
    async findById(id: number) {
      return db.query("SELECT * FROM users WHERE id = ?", [id]);
    },
    async save(user: User) {
      return db.execute("INSERT INTO users ...", user);
    },
  };
}

// Dependency injection — pass dependencies explicitly
export function createOrderService(
  repo: ReturnType<typeof createUserRepository>,
) {
  return {
    async processOrder(orderId: number) {
      const user = await repo.findById(orderId);
      // business logic here
    },
  };
}
```

## TypeScript type system (TS 6.0+)

```typescript
// Always strict: true in tsconfig.json
// Prefer interface for shapes, type for unions/intersections

interface User {
  id: number;
  email: string;
}

type Status = "pending" | "active" | "closed";

// satisfies — validates type without losing literal inference
const config = {
  host: "localhost",
  port: 8080,
} satisfies Record<string, string | number>;
// config.port is still 8080 (literal), not just number

// Opaque / branded types — prevent semantic mixing
type UserId = number & { readonly __brand: "UserId" };
type OrderId = number & { readonly __brand: "OrderId" };
```

Zero `any`. Use `unknown` when type is truly uncertain, then narrow explicitly.

## Hexagonal equivalent

Interfaces (or object shapes) act as Ports. Implementations are the Adapters.

```typescript
// application/ports.ts — Port as interface
export interface OrderRepository {
  save(order: Order): Promise<void>;
  findById(id: OrderId): Promise<Order | null>;
}

// infrastructure/sql-order-repo.ts — Adapter
export class SQLOrderRepository implements OrderRepository {
  async save(order: Order): Promise<void> { /* SQL here */ }
  async findById(id: OrderId): Promise<Order | null> { /* SQL here */ }
}
```

## Success criteria

- `strict: true` in `tsconfig.json`.
- Zero `any` — use `unknown` + type narrowing.
- `#private` fields used for true encapsulation.
- Feature-based module organization.
- Repository pattern abstracts all data access.
- `satisfies` used for object literal validation.
