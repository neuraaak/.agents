---
name: ezai-project-performance
description: >
  Performance optimization and concurrency models for Python and JS/TS.
  Covers: async/await vs threading vs multiprocessing selection, Web Workers,
  generators/async iterables for large datasets, profiling, caching, cancellation.

  Load from ezai-senior-dev-persona or directly for any performance task.

  Triggers on: "it's slow", "memory issue", "concurrent requests",
  "async model", "threading vs asyncio", "stream large data",
  "optimize this loop", "Web Workers", "AbortSignal", "profile", "GIL",
  "performance bottleneck", "out of memory", "speed this up".
---

Concurrency and performance optimization. Follows a 3-step workflow: identify the workload type, load the matching language file, then apply the model with complete code.

## Local rules precedence

Any rule declared in the user's `.claude/` (rules files, CLAUDE.md) takes
precedence over this skill. When a local rule covers the same domain, apply it
**in addition and in priority** over the defaults described here. This skill
ships only the general default; context-specific overrides live in the user's
rules.

## Capabilities

| Key                              | Description                                                                          |
| :------------------------------- | :----------------------------------------------------------------------------------- |
| `concurrency-model-selection`    | Choose between async/await, threading, and multiprocessing for I/O vs CPU-bound work |
| `async-profiling-guidance`       | Profile before optimizing — identify bottlenecks first                               |
| `streaming-large-datasets`       | Handle multi-GB files with generators or async iterables to prevent OOM              |
| `async-cancellation`             | Implement timeouts, cancellable requests, and proper async cleanup                   |
| `build-performance-js`           | Tree-shaking, lazy loading, and bundler optimization for JS/TS                       |
| `python-optimization-patterns`   | `__slots__`, `lru_cache`, NumPy, uvloop for Python performance                       |
| `semaphore-concurrency-limiting` | Limit concurrent operations with semaphores to prevent resource exhaustion           |

## Workflow

1. **Identify** — workload type (I/O / CPU / mixed) + detected language(s) in the project
2. **Load** — the language file below + `references/common/performance.md` (cross-cutting principles)
3. **Apply** — propose the matching model with complete code + success criteria

## Language routing

| Language                | File                                             |
| :---------------------- | :----------------------------------------------- |
| Python                  | `references/languages/python/performance.md`     |
| JavaScript / TypeScript | `references/languages/javascript/performance.md` |

For tasks spanning both languages, load both files and apply each to its respective layer. If a file is inaccessible, notify the user and fall back to `references/common/performance.md`.

## Output format

- **Model choice**: comparison table when several options are valid
- **Code**: complete example, annotated only on non-obvious points
- **Success criteria**: verifiable checklist at the end of the response
- **Profiling**: always indicate the tool to use before optimizing
