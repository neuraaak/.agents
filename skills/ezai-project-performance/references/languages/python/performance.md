# Performance & Concurrency — Python

## Concurrency model selection

| Workload                        | Python 3.11–3.13       | Python 3.14+ (GIL-less) |
| :------------------------------ | :--------------------- | :---------------------- |
| I/O intensive (HTTP, DB, files) | `asyncio` + `uvloop`   | `asyncio` + `uvloop`    |
| CPU-bound                       | `multiprocessing.Pool` | `threading.Thread` ✅    |
| Mixed I/O + CPU                 | `asyncio` + executor   | `asyncio` + `threading` |

Python 3.14+ removes the GIL — `threading` becomes the right tool for CPU-bound work.

## Asyncio — concurrent I/O

```python
import asyncio

async def fetch(url: str) -> dict[str, str]:
    await asyncio.sleep(0.1)  # simulated I/O
    return {"url": url}

async def fetch_all(urls: list[str]) -> list[dict[str, str]]:
    return await asyncio.gather(*[fetch(u) for u in urls])
    # ← concurrent, not a sequential await in a loop
```

`asyncio.gather` for concurrency. A sequential `await` in a loop is not concurrent.

## TaskGroup — Python 3.11+ (replaces gather)

`TaskGroup` propagates errors cleanly: if one task fails, the others are cancelled.

```python
async def fetch_all(urls: list[str]) -> list[dict]:
    results = []
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch(u)) for u in urls]
    return [t.result() for t in tasks]
```

## Bounded concurrency — Semaphore

Avoid spawning N tasks without a limit so you don't saturate resources (DB connections, rate limits).

```python
async def fetch_limited(urls: list[str], max_concurrent: int = 10) -> list[dict]:
    sem = asyncio.Semaphore(max_concurrent)

    async def bounded_fetch(url: str) -> dict:
        async with sem:
            return await fetch(url)

    return await asyncio.gather(*[bounded_fetch(u) for u in urls])
```

## Cancellation and timeout — Python 3.11+

```python
async def fetch_with_timeout(url: str, timeout: float = 5.0) -> dict | None:
    try:
        async with asyncio.timeout(timeout):
            return await fetch(url)
    except TimeoutError:
        return None

# Manual cancellation of a task
task = asyncio.create_task(long_operation())
task.cancel()
try:
    await task
except asyncio.CancelledError:
    pass  # cleanup if needed
```

## Threading — CPU-bound (3.14+)

```python
from concurrent.futures import ThreadPoolExecutor

def cpu_task(data: list[int]) -> int:
    return sum(x * x for x in data)

with ThreadPoolExecutor(max_workers=4) as pool:
    results = list(pool.map(cpu_task, chunks))
```

## Generators — large datasets

```python
from pathlib import Path
from collections.abc import Generator

def stream_lines(path: Path) -> Generator[str, None, None]:
    with path.open("r") as f:
        for line in f:
            yield line.strip()

for line in stream_lines(Path("large.csv")):
    process(line)
```

Never `pd.read_csv()` on a multi-GB file — use chunked reading or generators.

## Profiling

| Tool          | Usage                                                               |
| :------------ | :------------------------------------------------------------------ |
| `cProfile`    | CPU profiling (stdlib) — `python -m cProfile -s cumtime script.py`  |
| `py-spy`      | Sampling profiler without modifying code — `py-spy top --pid <PID>` |
| `tracemalloc` | Memory profiling (stdlib) — before/after snapshots                  |
| `memray`      | Advanced memory profiling with flamegraph — `memray run script.py`  |

```python
import tracemalloc

tracemalloc.start()
# ... code to profile ...
snapshot = tracemalloc.take_snapshot()
top = snapshot.statistics("lineno")
for stat in top[:5]:
    print(stat)
```

## Optimization techniques

| Technique             | When to use                                            |
| :-------------------- | :----------------------------------------------------- |
| `__slots__`           | Class with millions of instances                       |
| `functools.lru_cache` | Expensive pure function with repeated inputs           |
| NumPy vectorization   | Numeric computation — replaces Python loops            |
| `uvloop`              | Drop-in for the asyncio event loop — 2–4× throughput   |
| `memoryview`          | Binary data manipulation without copying               |
| `array` module        | Typed homogeneous collections (more compact than list) |

## Success criteria

- Concurrency model matched to the workload type.
- `asyncio.gather` / `TaskGroup` for concurrent I/O (no sequential `await`).
- `asyncio.Semaphore` to bound concurrency.
- Generators for processing large files/streams.
- No premature optimization — profile first.
- Python 3.14+: `threading` preferred over `multiprocessing` for CPU-bound work.
