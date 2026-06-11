---
name: ezai-project-performance
description: >
  Optimisation des performances et modèles de concurrence pour Python et JS/TS.
  Couvre : sélection async/await vs threading vs multiprocessing, Web Workers,
  generators/async iterables pour grands datasets, profiling, caching, annulation.

  Charge depuis ezai-senior-dev-persona ou en direct pour toute tâche perf.

  Déclenche sur : "c'est lent", "problème mémoire", "requêtes concurrentes",
  "modèle async", "threading vs asyncio", "streamer de grandes données",
  "optimiser cette boucle", "Web Workers", "AbortSignal", "profiler", "GIL",
  "concurrent requests", "memory issue", "async model", "stream large data".
---

Concurrence et optimisation des performances. Suit le workflow en 3 étapes : identifier le type de charge, charger le fichier langue adapté, puis appliquer le modèle avec code complet.

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

1. **Identifier** — type de charge (I/O / CPU / mixte) + langue(s) détectées dans le projet
2. **Charger** — fichier langue ci-dessous + `references/common/performance.md` (principes transversaux)
3. **Appliquer** — proposer le modèle adapté avec code complet + critères de succès

## Language routing

| Langue                  | Fichier                                          |
| :---------------------- | :----------------------------------------------- |
| Python                  | `references/languages/python/performance.md`     |
| JavaScript / TypeScript | `references/languages/javascript/performance.md` |

Pour des tâches couvrant les deux langues, charger les deux fichiers et appliquer chacun à sa couche respective. Si un fichier est inaccessible, notifier l'utilisateur et se rabattre sur `references/common/performance.md`.

## Output format

- **Choix de modèle** : tableau comparatif si plusieurs options sont valides
- **Code** : exemple complet, annoté sur les points non-évidents uniquement
- **Critères de succès** : liste vérifiable en fin de réponse
- **Profiling** : toujours indiquer l'outil à utiliser avant d'optimiser
