# Performance & Concurrency — JavaScript / TypeScript

Source: `js-concurrency-perf.instructions.md`

## Concurrency model

JavaScript is single-threaded. Concurrency comes from the event loop (async I/O) and Web Workers / Worker Threads (CPU parallelism).

| Workload                          | Tool                                                 |
| :-------------------------------- | :--------------------------------------------------- |
| High-volume I/O (HTTP, DB, files) | `async/await` + `Promise.allSettled`                 |
| CPU-bound computation             | `Worker Threads` (Node.js) / `Web Workers` (browser) |
| Stream processing                 | `for await...of` on async iterables                  |
| Cancellable long-running ops      | `AbortController` + `AbortSignal`                    |

## Async I/O

```typescript
// Concurrent — use Promise.allSettled for independent operations
const results = await Promise.allSettled(
  urls.map((url) => fetch(url, { signal })),
);

// Array.fromAsync — creates an array from an async iterable
const data = await Array.fromAsync(urls, async (url) => {
  const res = await fetch(url, { signal: controller.signal });
  return res.json();
});
```

Never `await` in a `for` loop for independent operations — that's sequential, not concurrent.

## AbortController — cancellation

```typescript
const controller = new AbortController();

setTimeout(() => controller.abort(), 5000);  // 5s timeout

try {
  const result = await fetch(url, { signal: controller.signal });
} catch (err) {
  if (err instanceof DOMException && err.name === "AbortError") {
    // handle cancellation
  }
}
```

Always implement `AbortSignal` for long-running or user-cancellable async tasks.

## CPU-bound — Worker Threads (Node.js)

```typescript
import { Worker, isMainThread, workerData, parentPort } from "node:worker_threads";

if (isMainThread) {
  const worker = new Worker(__filename, { workerData: { items: largeArray } });
  worker.on("message", (result) => console.log(result));
} else {
  const result = workerData.items.reduce((acc: number, x: number) => acc + x * x, 0);
  parentPort?.postMessage(result);
}
```

## Streaming — async iterables

```typescript
async function* streamLines(path: string): AsyncGenerator<string> {
  const file = await import("node:fs/promises");
  const content = await file.readFile(path, "utf-8");
  for (const line of content.split("\n")) {
    yield line;
  }
}

for await (const line of streamLines("large.csv")) {
  await processLine(line);
}
```

## Build performance

- **Tree-shaking:** ESM + side-effect-free modules (`"sideEffects": false` in `package.json`).
- **Lazy loading:** `import()` for large optional dependencies.
- **Bundler:** Vite or esbuild for fast builds; avoid webpack for new projects.
- **Memoization:** Cache expensive pure-function results with a `Map`.

## Success criteria

- `Promise.allSettled` / `Array.fromAsync` for concurrent I/O (not sequential `await`).
- `AbortController` implemented for all long-running async tasks.
- Worker Threads used for CPU-bound computation.
- Async generators used for large stream processing.
- ESM outputs for proper tree-shaking.
