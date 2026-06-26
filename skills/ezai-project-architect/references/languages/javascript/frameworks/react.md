# Architecture & Design — React (delta)

> **Delta** on `references/languages/javascript/architecture.md`. Load the JS/TS
> base file first; this file only adds or overrides what changes when React is
> used. The Repository / Ports & Adapters and branded-type rules from the base
> still apply unchanged.

## Detection

`react` / `react-dom` in `dependencies`, or `vite` + `@vitejs/plugin-react` in
`devDependencies`.

## Feature-based structure delta

The base "organize by domain, not by technical type" rule holds — apply it to
React too. Co-locate component, hook, and types per feature; do **not** create
top-level `components/` / `hooks/` dumps.

```text
src/
├── features/
│   └── order/
│       ├── OrderList.tsx       # presentation only
│       ├── useOrders.ts        # logic + data access (the "port" consumer)
│       └── order.types.ts
├── shared/                     # cross-feature UI primitives, hooks
└── app/                        # providers, router, composition root
```

## Custom hooks = the logic boundary

A custom hook is React's unit of reusable logic — it is the seam where the base
**Repository / Port** rule lands. Keep components presentational; push data
access and side effects into hooks that depend on an injected client, never on a
hard-coded `fetch`.

```typescript
// features/order/useOrders.ts — logic boundary, depends on a port
import { useQuery } from "@tanstack/react-query";
import type { OrderRepository } from "../../app/ports";

export function useOrders(repo: OrderRepository) {
  return useQuery({ queryKey: ["orders"], queryFn: () => repo.findAll() });
}
```

- The component renders `useOrders(...)` output — it knows nothing about HTTP/SQL.
- Server state (fetching, caching) → a query library (TanStack Query); local UI
  state → `useState`/`useReducer`. Do not hand-roll cache in `useEffect`.
- Rules of Hooks: call hooks unconditionally at the top level (enforced by the
  `react-hooks` ESLint rule from the config delta).

## Dependency injection — Context as the composition root

Inject ports (repositories, API clients) through Context at the app root — the
React equivalent of the base Composition Root. Components consume an interface,
not a concrete implementation, so tests swap in the in-memory fake (base rule).

```typescript
// app/ports.ts — Port (base file's interface rule)
export interface OrderRepository {
  findAll(): Promise<Order[]>;
}

// app/RepositoryProvider.tsx — composition root
const RepoContext = createContext<OrderRepository | null>(null);

export function useRepository(): OrderRepository {
  const repo = useContext(RepoContext);
  if (!repo) throw new Error("RepositoryProvider missing");
  return repo;
}
// <RepoContext.Provider value={sqlRepo}> at the root; fake in tests.
```

- Context carries **dependencies and rarely-changing app state**, not
  high-frequency state (that re-renders all consumers).
- Branded types (`UserId`, `OrderId` from the base) flow through props/hooks
  unchanged — keep primitives out of the component API.

## Success criteria (React)

- Feature-based folders; component, hook, and types co-located — no technical-type dumps.
- Logic and data access live in custom hooks; components stay presentational.
- Hooks depend on an injected port, not a hard-coded `fetch`/client.
- Ports injected via Context (composition root); tests swap the in-memory fake.
- Server state via a query library; Rules of Hooks satisfied.
- Branded types preserved across the props/hooks boundary.
