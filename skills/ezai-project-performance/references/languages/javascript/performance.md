# Performance & Concurrency — JavaScript / TypeScript

JavaScript is single-threaded. Concurrency comes from the event loop (async I/O) and from Worker Threads / Web Workers (CPU parallelism).

## Concurrency model selection

| Workload                        | Tool                                                 |
| :------------------------------ | :--------------------------------------------------- |
| I/O intensive (HTTP, DB, files) | `async/await` + `Promise.allSettled`                 |
| CPU-bound                       | `Worker Threads` (Node.js) / `Web Workers` (browser) |
| Stream processing               | `for await...of` over async iterables                |
| Cancellable long operations     | `AbortController` + `AbortSignal`                    |
| First available result          | `Promise.any`                                        |
| Timeout / race                  | `Promise.race`                                       |

## Concurrent I/O

```typescript
// Concurrent — Promise.allSettled for independent operations
const results = await Promise.allSettled(
  urls.map((url) => fetch(url, { signal: controller.signal })),
);

// Array.fromAsync — array from an async iterable
const data = await Array.fromAsync(urls, async (url) => {
  const res = await fetch(url, { signal: controller.signal });
  return res.json();
});
```

Never `await` in a `for` loop for independent operations — it's sequential, not concurrent.

## Bounded concurrency

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

## AbortController — cancellation

```typescript
const controller = new AbortController();
setTimeout(() => controller.abort(), 5000); // 5s timeout

try {
  const result = await fetch(url, { signal: controller.signal });
} catch (err) {
  if (err instanceof DOMException && err.name === "AbortError") {
    // clean cancellation
  }
}
```

Always implement `AbortSignal` for long-running or user-cancellable async tasks.

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

// First success (ignores failures)
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

`createReadStream` + `readline` to never load the entire file into memory.

## Profiling

```typescript
// Precise in-code measurement
performance.mark("start");
await heavyOperation();
performance.mark("end");
performance.measure("heavy", "start", "end");
console.log(performance.getEntriesByName("heavy")[0].duration);

// Quick for debugging
console.time("operation");
await heavyOperation();
console.timeEnd("operation");
```

**Browser**: Chrome DevTools → Performance tab for a CPU flamegraph, Memory tab for heap snapshots.
**Node.js**: `node --prof script.js` then `node --prof-process isolate-*.log`.

## Browser APIs — UI performance

```typescript
// Defer non-critical work
requestIdleCallback((deadline) => {
  while (deadline.timeRemaining() > 0 && tasks.length > 0) {
    processTask(tasks.shift()!);
  }
});

// Lazy loading on viewport entry
const observer = new IntersectionObserver((entries) => {
  entries.filter((e) => e.isIntersecting).forEach(loadComponent);
});
observer.observe(target);
```

## Deep copy — performance

```typescript
// structuredClone — native, supports more types
const copy = structuredClone(obj); // ✅ Maps, Sets, Date, ArrayBuffer

// JSON.parse/stringify — limited but faster on small flat objects
const copy = JSON.parse(JSON.stringify(obj)); // ⚠️ loses undefined, Date→string
```

## Build performance

- **Tree-shaking**: ESM + side-effect-free modules (`"sideEffects": false` in `package.json`).
- **Lazy loading**: `import()` for large optional dependencies.
- **Bundler**: Vite or esbuild for fast builds; avoid webpack for new projects.
- **Memoization**: cache the results of expensive pure functions with a `Map`.

## Success criteria

- `Promise.allSettled` / `Array.fromAsync` for concurrent I/O (no sequential `await`).
- `AbortController` implemented for all long-running async tasks.
- Concurrency bounded via batching or semaphore.
- Worker Threads used for CPU-bound work.
- `createReadStream` + `readline` for file streaming (never `readFile` on a large file).
- ESM outputs for correct tree-shaking.
