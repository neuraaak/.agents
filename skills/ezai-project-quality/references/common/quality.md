# Quality — Cross-Language Principles

These apply regardless of language. Load alongside the language-specific quality file.

- **Validate at every boundary:** Treat all external input (HTTP, files, DB reads, LLM output) as untrusted. Fail fast with clear schema errors.
- **Secrets never in source:** Use env variables in dev, vaults in production. Never log them.
- **Fakes over mocks:** For testing Ports/Repositories, prefer a simple in-memory fake over a complex mock setup.
- **Coverage target:** 80–90% for business logic. Don't chase 100% on trivial getters.
- **Property-based testing:** Use for invariants — sorting, serialization round-trips, mathematical properties.
