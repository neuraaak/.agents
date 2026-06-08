# Project Performance — References Index

Route to the correct language subdirectory. Always load `common/performance.md` for cross-language principles.

## Common (`common/`)

| File                    | Load when…             | Contents                                                      |
| :---------------------- | :--------------------- | :------------------------------------------------------------ |
| `common/performance.md` | Every performance task | Profile first, workload model, stream vs buffer, cancellation |

## Supported languages

| Language              | Subdirectory  | Available files  |
| :-------------------- | :------------ | :--------------- |
| Python                | `python/`     | `performance.md` |
| JavaScript/TypeScript | `javascript/` | `performance.md` |

---

## Python (`python/`)

Stack: asyncio, uvloop, threading (3.14+ GIL-less), multiprocessing, generators.

| File                    | Load when…                                  | Contents                                                                                     |
| :---------------------- | :------------------------------------------ | :------------------------------------------------------------------------------------------- |
| `python/performance.md` | Any async, concurrency, or performance task | Model selection table, asyncio patterns, threading 3.14+, generators, performance techniques |

---

## JavaScript/TypeScript (`javascript/`)

Stack: async/await, AbortController, Worker Threads, Array.fromAsync, Vite/esbuild.

| File                        | Load when…                                  | Contents                                                                                            |
| :-------------------------- | :------------------------------------------ | :-------------------------------------------------------------------------------------------------- |
| `javascript/performance.md` | Any async, concurrency, or performance task | Concurrency model, Promise.allSettled, AbortController, Worker Threads, async iterables, build perf |
