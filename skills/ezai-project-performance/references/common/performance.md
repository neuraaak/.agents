# Performance & Concurrence — Principes transversaux

Ces principes s'appliquent quelle que soit la langue. Charger avec le fichier langue correspondant.

## Règles fondamentales

- **Profiler d'abord** : ne jamais optimiser sans données de profiling. Mesurer, puis agir.
- **Adapter le modèle à la charge** :
    - I/O-bound → event loop async (asyncio, async/await JS)
    - CPU-bound → threads (Python 3.14+ GIL-less, Worker Threads JS) ou multiprocessing (Python <3.14 ou isolation requise)
    - Mixte → async + executor/worker
- **Streamer, ne pas bufferiser** : traiter les grands datasets comme des générateurs/async iterables — ne jamais tout charger en mémoire.
- **Annulation** : toujours fournir un mécanisme d'annulation pour les opérations async longues.
- **Concurrence limitée** : ne pas spawner des tâches illimitées — utiliser un semaphore ou un pool pour borner la concurrence.

## Anti-patterns à éviter

| Anti-pattern                                     | Problème                   | Correction                      |
| :----------------------------------------------- | :------------------------- | :------------------------------ |
| `await` en boucle sur tâches indépendantes       | Séquentiel, pas concurrent | `gather` / `Promise.allSettled` |
| Charger un fichier multi-Go en mémoire           | OOM                        | Générateurs / streaming         |
| Optimiser sans profiler                          | Effort mal dirigé          | `cProfile`, `py-spy`, DevTools  |
| Spawner N tâches sans limite                     | Saturation ressources      | Semaphore / pool                |
| Ignorer les erreurs dans les tâches concurrentes | Silencing failures         | `TaskGroup` / `allSettled`      |
