# Architecture & Design — Cross-cutting principles

These principles apply regardless of language. Load alongside the matching language file.

## Core rules

- **Composition over inheritance** — prefer small, composable units to deep class hierarchies.
- **Explicit public surface** — always define what is public and what is internal.
- **Ports & Adapters** — apply when a module boundary crosses an external system (DB, API, message queue, filesystem); define contracts as structural interfaces, not base classes.
- **Repository pattern** — abstract all data access behind a repository interface; business logic never imports a DB driver directly.
- **Feature-based modules** — organize by business domain (`user/`), not by technical type (`models/` + `controllers/`).

## Watchguard — Hexagonal vs Simple Layered

Before proposing a hexagonal architecture, evaluate these 4 criteria. If the score is ≤ 2, recommend **Simple Layered** instead.

| Criterion                                                               | Score |
| :---------------------------------------------------------------------- | :---: |
| The project has ≥ 2 distinct external systems (DB + API + queue…)       |  +1   |
| Business logic must be testable without infrastructure                  |  +1   |
| Alternative adapters are planned (e.g. SQLite in dev, Postgres in prod) |  +1   |
| The project exceeds ~1,000 lines or 3 developers                        |  +1   |

- **Score ≥ 3** → Hexagonal (Ports & Adapters)
- **Score ≤ 2** → Simple Layered (`models/` + `services/` + `repositories/`, flat)

Never over-architect a script or a prototype — the overhead of Hexagonal hurts readability on small projects.

## Simple Layered — structure

```text
src/
├── models/       ← Entities & Value Objects
├── repositories/ ← Data access (one interface + one implementation)
└── services/     ← Business logic
```

## Hexagonal — structure

```text
src/
├── domain/          ← Entities, Value Objects (zero external imports)
├── application/     ← Use Cases + Ports (interfaces)
└── infrastructure/  ← Adapters (DB, APIs) + Composition Root
```

Dependency rule: **always inward** — Infrastructure → Application → Domain.

## Anti-patterns to avoid

| Anti-pattern              | Symptom                                                         | Fix                                                   |
| :------------------------ | :-------------------------------------------------------------- | :---------------------------------------------------- |
| **Anemic Domain Model**   | Entities have only getters/setters, the logic lives in services | Move business logic into the entities                 |
| **God Object**            | One class does everything (15+ methods, mixed responsibilities) | Decompose by Single Responsibility                    |
| **Circular dependencies** | Module A imports B which imports A                              | Extract a shared interface, or invert the dependency  |
| **Primitive Obsession**   | `user_id: int`, `order_id: int` — semantics lost                | Branded/opaque types or Value Objects                 |
| **Infrastructure leak**   | A SQL driver imported into a Use Case                           | Repository pattern — the Use Case only knows the Port |
