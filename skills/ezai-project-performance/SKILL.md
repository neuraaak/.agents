---
name: ezai-project-performance
description:
  "Concurrency, async patterns, and performance optimization for
  Python and JS/TS projects. Covers async/await model selection, threading vs
  multiprocessing (Python 3.14+ GIL-less), Web Workers (JS), generator patterns
  for large datasets, and profiling guidance. Load from ezai-persona-senior-dev, or
  invoke directly for performance tasks.

  Triggers on: 'this is slow', 'memory issue', 'concurrent requests', 'async
  model', 'threading vs asyncio', 'stream large data', 'optimize this loop',
  'Web Workers', 'AbortSignal'."
---

Concurrency and performance standards. Load the language file from the routing table below, then load `references/common/performance.md` for cross-language principles.

## Language routing

| Language                | File                                   |
| :---------------------- | :------------------------------------- |
| Python                  | `references/python/performance.md`     |
| JavaScript / TypeScript | `references/javascript/performance.md` |

For tasks spanning both languages, load both files and apply each to its respective layer. If a file cannot be accessed, notify the user and fall back to `references/common/performance.md`.
