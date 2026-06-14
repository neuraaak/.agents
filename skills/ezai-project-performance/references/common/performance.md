# Performance & Concurrency — Cross-cutting principles

These principles apply regardless of language. Load alongside the matching language file.

## Core rules

- **Profile first**: never optimize without profiling data. Measure, then act.
- **Match the model to the workload**:
    - I/O-bound → async event loop (asyncio, JS async/await)
    - CPU-bound → threads (Python 3.14+ GIL-less, JS Worker Threads) or multiprocessing (Python <3.14 or isolation required)
    - Mixed → async + executor/worker
- **Stream, don't buffer**: process large datasets as generators/async iterables — never load everything into memory.
- **Cancellation**: always provide a cancellation mechanism for long-running async operations.
- **Bounded concurrency**: do not spawn unbounded tasks — use a semaphore or a pool to bound concurrency.

## Anti-patterns to avoid

| Anti-pattern                             | Problem                    | Fix                             |
| :--------------------------------------- | :------------------------- | :------------------------------ |
| `await` in a loop over independent tasks | Sequential, not concurrent | `gather` / `Promise.allSettled` |
| Loading a multi-GB file into memory      | OOM                        | Generators / streaming          |
| Optimizing without profiling             | Misdirected effort         | `cProfile`, `py-spy`, DevTools  |
| Spawning N tasks without a limit         | Resource saturation        | Semaphore / pool                |
| Ignoring errors in concurrent tasks      | Silenced failures          | `TaskGroup` / `allSettled`      |
