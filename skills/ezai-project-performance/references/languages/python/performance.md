# Performance & Concurrence — Python

## Sélection du modèle de concurrence

| Charge                            | Python 3.11–3.13       | Python 3.14+ (GIL-less) |
| :-------------------------------- | :--------------------- | :---------------------- |
| I/O intensif (HTTP, DB, fichiers) | `asyncio` + `uvloop`   | `asyncio` + `uvloop`    |
| CPU-bound                         | `multiprocessing.Pool` | `threading.Thread` ✅    |
| Mixte I/O + CPU                   | `asyncio` + executor   | `asyncio` + `threading` |

Python 3.14+ supprime le GIL — `threading` devient le bon outil pour le travail CPU-bound.

## Asyncio — I/O concurrent

```python
import asyncio

async def fetch(url: str) -> dict[str, str]:
    await asyncio.sleep(0.1)  # I/O simulé
    return {"url": url}

async def fetch_all(urls: list[str]) -> list[dict[str, str]]:
    return await asyncio.gather(*[fetch(u) for u in urls])
    # ← concurrent, pas un await séquentiel en boucle
```

`asyncio.gather` pour la concurrence. Un `await` séquentiel en boucle n'est pas concurrent.

## TaskGroup — Python 3.11+ (remplace gather)

`TaskGroup` propage les erreurs proprement : si une tâche échoue, les autres sont annulées.

```python
async def fetch_all(urls: list[str]) -> list[dict]:
    results = []
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch(u)) for u in urls]
    return [t.result() for t in tasks]
```

## Concurrence limitée — Semaphore

Éviter de spawner N tâches sans limite pour ne pas saturer les ressources (connexions DB, rate limits).

```python
async def fetch_limited(urls: list[str], max_concurrent: int = 10) -> list[dict]:
    sem = asyncio.Semaphore(max_concurrent)

    async def bounded_fetch(url: str) -> dict:
        async with sem:
            return await fetch(url)

    return await asyncio.gather(*[bounded_fetch(u) for u in urls])
```

## Annulation et timeout — Python 3.11+

```python
async def fetch_with_timeout(url: str, timeout: float = 5.0) -> dict | None:
    try:
        async with asyncio.timeout(timeout):
            return await fetch(url)
    except TimeoutError:
        return None

# Annulation manuelle d'une tâche
task = asyncio.create_task(long_operation())
task.cancel()
try:
    await task
except asyncio.CancelledError:
    pass  # cleanup si nécessaire
```

## Threading — CPU-bound (3.14+)

```python
from concurrent.futures import ThreadPoolExecutor

def cpu_task(data: list[int]) -> int:
    return sum(x * x for x in data)

with ThreadPoolExecutor(max_workers=4) as pool:
    results = list(pool.map(cpu_task, chunks))
```

## Générateurs — grands datasets

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

Ne jamais `pd.read_csv()` sur un fichier multi-Go — utiliser le chunked reading ou des générateurs.

## Profiling

| Outil         | Usage                                                               |
| :------------ | :------------------------------------------------------------------ |
| `cProfile`    | Profiling CPU (stdlib) — `python -m cProfile -s cumtime script.py`  |
| `py-spy`      | Profiling sampling sans modifier le code — `py-spy top --pid <PID>` |
| `tracemalloc` | Profiling mémoire (stdlib) — snapshots avant/après                  |
| `memray`      | Profiling mémoire avancé avec flamegraph — `memray run script.py`   |

```python
import tracemalloc

tracemalloc.start()
# ... code à profiler ...
snapshot = tracemalloc.take_snapshot()
top = snapshot.statistics("lineno")
for stat in top[:5]:
    print(stat)
```

## Techniques d'optimisation

| Technique             | Quand l'utiliser                                       |
| :-------------------- | :----------------------------------------------------- |
| `__slots__`           | Classe avec des millions d'instances                   |
| `functools.lru_cache` | Fonction pure coûteuse avec entrées répétées           |
| NumPy vectorisation   | Calcul numérique — remplace les boucles Python         |
| `uvloop`              | Drop-in pour l'event loop asyncio — 2–4× de throughput |
| `memoryview`          | Manipulation de données binaires sans copie            |
| `array` module        | Collections homogènes typées (plus compact que list)   |

## Critères de succès

- Modèle de concurrence adapté au type de charge.
- `asyncio.gather` / `TaskGroup` pour l'I/O concurrent (pas de `await` séquentiel).
- `asyncio.Semaphore` pour borner la concurrence.
- Générateurs pour le traitement de fichiers/streams volumineux.
- Pas d'optimisation prématurée — profiler d'abord.
- Python 3.14+ : `threading` préféré à `multiprocessing` pour le CPU-bound.
