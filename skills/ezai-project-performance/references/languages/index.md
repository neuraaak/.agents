# Project Performance — Languages Index

Route to the correct language subdirectory. For tasks spanning both languages, load both files.

## Supported languages

| Language              | Detect via       | File                                  |
| :-------------------- | :--------------- | :------------------------------------ |
| Python                | `pyproject.toml` | `languages/python/performance.md`     |
| JavaScript/TypeScript | `package.json`   | `languages/javascript/performance.md` |

## What each file owns

- **`python/performance.md`** — asyncio, uvloop, threading (3.14+ GIL-less), multiprocessing, generators, model selection table.
- **`javascript/performance.md`** — async/await, AbortController, Worker Threads, Promise.allSettled, async iterables, build perf (Vite/esbuild).

## Adding a new language

1. Create `<language>/` here with `performance.md`.
2. Register in the table above and in `references/index.md`.
