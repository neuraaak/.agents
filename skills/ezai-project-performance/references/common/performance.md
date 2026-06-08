# Performance & Concurrency — Cross-Language Principles

These apply regardless of language. Load alongside the language-specific performance file.

- **Profile first:** Never optimize without profiling data. Measure, then act.
- **Match model to workload:** I/O-bound → async/event-loop. CPU-bound → threads (Python 3.14+ GIL-less or JS Workers) or multiprocessing (Python <3.14 or when process isolation is required).
- **Stream don't buffer:** Process large datasets as generators/async iterables — never load everything into memory.
- **Cancellation:** Always provide a cancellation mechanism for long-running async ops.
