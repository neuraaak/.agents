# Architecture & Design — Vue (delta)

> **Delta** on `references/languages/javascript/architecture.md`. Load the JS/TS
> base file first; this file only adds or overrides what changes when Vue is
> used. The Repository / Ports & Adapters and branded-type rules from the base
> still apply unchanged.

## Detection

`vue` in `dependencies`, or `vite` + `@vitejs/plugin-vue` in `devDependencies`.

## Feature-based structure delta

The base "organize by domain, not by technical type" rule holds — apply it to
Vue too. Co-locate component, composable, and types per feature; do **not**
create top-level `components/` / `composables/` dumps.

```text
src/
├── features/
│   └── order/
│       ├── OrderList.vue       # presentation only
│       ├── useOrders.ts        # logic + data access (the "port" consumer)
│       └── order.types.ts
├── shared/                     # cross-feature UI primitives, composables
└── app/                        # providers, router, composition root
```

## Composables = the logic boundary

A composable is Vue's unit of reusable logic — it is the seam where the base
**Repository / Port** rule lands. Keep components presentational; push data
access and side effects into composables that depend on an injected client, never
on a hard-coded `fetch`.

```typescript
// features/order/useOrders.ts — logic boundary, depends on a port
import { useQuery } from "@tanstack/vue-query";
import type { OrderRepository } from "../../app/ports";

export function useOrders(repo: OrderRepository) {
  return useQuery({ queryKey: ["orders"], queryFn: () => repo.findAll() });
}
```

- The component renders `useOrders(...)` output — it knows nothing about HTTP/SQL.
- Server state (fetching, caching) → a query library (TanStack Query); local UI
  state → `ref`/`reactive`. Do not hand-roll cache in `watchEffect`.

## Dependency injection — `provide`/`inject` as the composition root

Inject ports (repositories, API clients) via `provide` at the app root — Vue's
equivalent of the base Composition Root. Components consume an injected interface,
not a concrete implementation, so tests swap in the in-memory fake.

```typescript
// app/ports.ts — Port (base file's interface rule)
export interface OrderRepository {
  findAll(): Promise<Order[]>;
}

// app/main.ts — composition root
import { createApp } from "vue";
import App from "./App.vue";
import { SqlOrderRepository } from "./infra/SqlOrderRepository";

const app = createApp(App);
app.provide("orderRepository", new SqlOrderRepository());
app.mount("#app");
```

```typescript
// features/order/useOrders.ts — inject the port
import { inject } from "vue";
import type { OrderRepository } from "../../app/ports";

export function useOrders() {
  const repo = inject<OrderRepository>("orderRepository");
  if (!repo) throw new Error("orderRepository not provided");
  // ...
}
```

- Use `InjectionKey<T>` (typed symbol) rather than a plain string key to get
  compile-time type safety on `inject()`.
- `provide` carries **dependencies**, not high-frequency reactive state.
- Branded types (`UserId`, `OrderId` from the base) flow through props/composables
  unchanged — keep primitives out of the component API.

## Success criteria (Vue)

- Feature-based folders; component, composable, and types co-located — no technical-type dumps.
- Logic and data access live in composables; components stay presentational.
- Composables depend on an injected port, not a hard-coded `fetch`/client.
- Ports injected via `provide`/`inject` (composition root); tests swap the in-memory fake.
- Server state via a query library; `InjectionKey<T>` for type-safe injection.
- Branded types preserved across the props/composables boundary.
