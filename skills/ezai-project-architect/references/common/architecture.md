# Architecture & Design — Cross-Language Principles

These apply regardless of language. Load alongside the language-specific architecture file.

- **Composition over inheritance** — prefer small, composable units over deep class hierarchies.
- **Explicit public surface** — always define what is public and what is internal.
- **Ports & Adapters** — apply when a module boundary crosses an external system (DB, API, message queue, filesystem); define contracts as structural interfaces, not base classes.
- **Repository pattern** — abstract all data access behind a repository interface; business logic never imports a DB driver directly.
- **Feature-based modules** — organize by business domain, not technical type (`user/`, not `models/`+`controllers/`).
