# Performance & Concurrence — JavaScript / TypeScript

JavaScript est mono-thread. La concurrence vient de l'event loop (async I/O) et des Worker Threads / Web Workers (parallélisme CPU).

## Sélection du modèle de concurrence

| Charge                            | Outil                                                |
| :-------------------------------- | :--------------------------------------------------- |
| I/O intensif (HTTP, DB, fichiers) | `async/await` + `Promise.allSettled`                 |
| CPU-bound                         | `Worker Threads` (Node.js) / `Web Workers` (browser) |
| Stream processing                 | `for await...of` sur async iterables                 |
| Opérations longues annulables     | `AbortController` + `AbortSignal`                    |
| Premier résultat disponible       | `Promise.any`                                        |
| Timeout / course                  | `Promise.race`                                       |

## I/O concurrent

```typescript
// Concurrent — Promise.allSettled pour opérations indépendantes
const results = await Promise.allSettled(
  urls.map((url) => fetch(url, { signal: controller.signal })),
);

// Array.fromAsync — tableau depuis un async iterable
const data = await Array.fromAsync(urls, async (url) => {
  const res = await fetch(url, { signal: controller.signal });
  return res.json();
});
```

Ne jamais `await` en boucle `for` pour des opérations indépendantes — c'est séquentiel, pas concurrent.

## Concurrence limitée

```typescript
async function fetchLimited<T>(
  items: string[],
  fn: (item: string) => Promise<T>,
  maxConcurrent = 10,
): Promise<T[]> {
  const results: T[] = [];
  for (let i = 0; i < items.length; i += maxConcurrent) {
    const batch = items.slice(i, i + maxConcurrent);
    const batchResults = await Promise.all(batch.map(fn));
    results.push(...batchResults);
  }
  return results;
}
```

## AbortController — annulation

```typescript
const controller = new AbortController();
setTimeout(() => controller.abort(), 5000); // timeout 5s

try {
  const result = await fetch(url, { signal: controller.signal });
} catch (err) {
  if (err instanceof DOMException && err.name === "AbortError") {
    // annulation propre
  }
}
```

Toujours implémenter `AbortSignal` pour les tâches async longues ou annulables par l'utilisateur.

## Promise.race / Promise.any

```typescript
// Timeout racing
const withTimeout = <T>(promise: Promise<T>, ms: number): Promise<T> =>
  Promise.race([
    promise,
    new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error("timeout")), ms),
    ),
  ]);

// Premier succès (ignore les échecs)
const fastest = await Promise.any(mirrors.map((url) => fetch(url)));
```

## CPU-bound — Worker Threads (Node.js)

```typescript
import { Worker, isMainThread, workerData, parentPort } from "node:worker_threads";

if (isMainThread) {
  const worker = new Worker(__filename, { workerData: { items: largeArray } });
  worker.on("message", (result) => console.log(result));
} else {
  const result = workerData.items.reduce(
    (acc: number, x: number) => acc + x * x,
    0,
  );
  parentPort?.postMessage(result);
}
```

## Streaming — async iterables (Node.js)

```typescript
import { createReadStream } from "node:fs";
import { createInterface } from "node:readline";

async function* streamLines(path: string): AsyncGenerator<string> {
  const rl = createInterface({
    input: createReadStream(path),
    crlfDelay: Infinity,
  });
  for await (const line of rl) {
    yield line;
  }
}

for await (const line of streamLines("large.csv")) {
  await processLine(line);
}
```

`createReadStream` + `readline` pour ne jamais charger le fichier entier en mémoire.

## Profiling

```typescript
// Mesure précise dans le code
performance.mark("start");
await heavyOperation();
performance.mark("end");
performance.measure("heavy", "start", "end");
console.log(performance.getEntriesByName("heavy")[0].duration);

// Rapide pour debugging
console.time("operation");
await heavyOperation();
console.timeEnd("operation");
```

**Browser** : Chrome DevTools → Performance tab pour flamegraph CPU, Memory tab pour heap snapshots.
**Node.js** : `node --prof script.js` puis `node --prof-process isolate-*.log`.

## APIs browser — performance UI

```typescript
// Différer le travail non-critique
requestIdleCallback((deadline) => {
  while (deadline.timeRemaining() > 0 && tasks.length > 0) {
    processTask(tasks.shift()!);
  }
});

// Lazy loading à l'entrée dans le viewport
const observer = new IntersectionObserver((entries) => {
  entries.filter((e) => e.isIntersecting).forEach(loadComponent);
});
observer.observe(target);
```

## Deep copy — performances

```typescript
// structuredClone — natif, supporte plus de types
const copy = structuredClone(obj); // ✅ Maps, Sets, Date, ArrayBuffer

// JSON.parse/stringify — limité mais plus rapide sur petits objets plats
const copy = JSON.parse(JSON.stringify(obj)); // ⚠️ perd undefined, Date→string
```

## Build performance

- **Tree-shaking** : ESM + modules sans effets de bord (`"sideEffects": false` dans `package.json`).
- **Lazy loading** : `import()` pour les dépendances optionnelles volumineuses.
- **Bundler** : Vite ou esbuild pour des builds rapides ; éviter webpack pour les nouveaux projets.
- **Memoization** : cacher les résultats de fonctions pures coûteuses avec une `Map`.

## Critères de succès

- `Promise.allSettled` / `Array.fromAsync` pour l'I/O concurrent (pas de `await` séquentiel).
- `AbortController` implémenté pour toutes les tâches async longues.
- Concurrence bornée via batching ou semaphore.
- Worker Threads utilisés pour le CPU-bound.
- `createReadStream` + `readline` pour le streaming de fichiers (jamais `readFile` sur un gros fichier).
- Sorties ESM pour le tree-shaking correct.
