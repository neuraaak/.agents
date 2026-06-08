# Performance & Concurrency — Python

Source: `python-concurrency-performance.instructions.md`

## Concurrency model selection

| Workload                          | Python 3.11–3.13       | Python 3.14+ (GIL-less) |
| :-------------------------------- | :--------------------- | :---------------------- |
| High-volume I/O (HTTP, DB, files) | `asyncio` + `uvloop`   | `asyncio` + `uvloop`    |
| CPU-bound computation             | `multiprocessing.Pool` | `threading.Thread` ✅   |
| Mixed I/O + CPU                   | `asyncio` + executor   | `asyncio` + `threading` |

Python 3.14+ removes the GIL — `threading` becomes the right tool for CPU-bound work.

## Asyncio — I/O-bound

```python
import asyncio

async def fetch(url: str) -> dict[str, str]:
    await asyncio.sleep(0.1)  # simulated I/O
    return {"url": url}

async def fetch_all(urls: list[str]) -> list[dict[str, str]]:
    return await asyncio.gather(*[fetch(u) for u in urls])
    # ← concurrent, not sequential await in a loop
```

Use `asyncio.gather` for concurrency. Sequential `await` in a loop is not concurrent.

## Threading — CPU-bound (3.14+)

```python
import threading
from concurrent.futures import ThreadPoolExecutor

def cpu_task(data: list[int]) -> int:
    return sum(x * x for x in data)

with ThreadPoolExecutor(max_workers=4) as pool:
    results = list(pool.map(cpu_task, chunks))
```

## Generator pattern — large datasets

```python
from pathlib import Path
from collections.abc import Generator

def stream_lines(path: Path) -> Generator[str, None, None]:
    with path.open("r") as f:
        for line in f:
            yield line.strip()

# Process without loading the whole file into memory
for line in stream_lines(Path("large.csv")):
    process(line)
```

Never `pd.read_csv()` on a multi-GB file — use chunked reading or generators.

## Performance techniques

| Technique             | Use when                                               |
| :-------------------- | :----------------------------------------------------- |
| `__slots__`           | Data class with millions of instances                  |
| `functools.lru_cache` | Expensive pure function with repeated identical inputs |
| NumPy vectorization   | Numerical computation — replaces Python loops          |
| `uvloop`              | Drop-in for `asyncio` event loop — 2–4× throughput     |
| `cProfile` / `py-spy` | Profile before optimizing — always                     |

## Success criteria

- Concurrency model matches workload type.
- `asyncio.gather` used for concurrent I/O (not sequential `await`).
- Generators used for large file/stream processing.
- No premature optimization — profile first.
- Python 3.14+: `threading` preferred over `multiprocessing` for CPU work.
