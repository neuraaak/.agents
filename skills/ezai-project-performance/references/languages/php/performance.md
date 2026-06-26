# Performance & Concurrency — PHP

## Concurrency model selection

| Workload                              | Recommended approach                                    |
| :------------------------------------ | :------------------------------------------------------ |
| Classic web (CRUD, stateless)         | PHP-FPM + Nginx — horizontal scaling, zero async needed |
| I/O intensive (HTTP calls, DB queues) | ReactPHP / Revolt + Fibers                              |
| CPU-bound (image processing, crypto)  | Separate CLI process or `parallel` extension            |
| High-throughput persistent server     | Swoole or FrankenPHP (keep-alive workers)               |

Default to **PHP-FPM + horizontal scaling** for most web workloads — it is simpler, battle-tested, and scales well. Add async only when measured latency requires it.

## Fibers — cooperative concurrency (PHP 8.1+)

Fibers are PHP's building block for async. Libraries like ReactPHP/Revolt use them internally; you rarely write raw Fibers in application code.

```php
<?php

declare(strict_types=1);

// Low-level illustration — use ReactPHP/Revolt in production
$fiber = new \Fiber(function (): string {
    echo "fiber: start\n";
    $received = \Fiber::suspend('first suspend');
    echo "fiber: resumed with {$received}\n";
    return 'done';
});

$value  = $fiber->start();          // "fiber: start" → $value = 'first suspend'
$result = $fiber->resume('hello');  // "fiber: resumed with hello" → $result = 'done'
```

## ReactPHP / Revolt — concurrent I/O

```php
<?php

declare(strict_types=1);

use React\EventLoop\Loop;
use React\Http\Browser;
use Psr\Http\Message\ResponseInterface;

// Concurrent HTTP requests — not sequential
$browser = new Browser();

$promises = [
    $browser->get('https://api.example.com/a'),
    $browser->get('https://api.example.com/b'),
    $browser->get('https://api.example.com/c'),
];

\React\Promise\all($promises)->then(function (array $responses): void {
    foreach ($responses as $response) {
        /** @var ResponseInterface $response */
        echo $response->getBody()->getContents() . "\n";
    }
});

Loop::run();
```

Use `\React\Promise\all()` for concurrent I/O — sequential `then()` chaining is not concurrent.

## Generators — large dataset streaming

```php
<?php

declare(strict_types=1);

// Generator — processes one line at a time, O(1) memory
function streamCsv(string $path): \Generator
{
    $handle = fopen($path, 'r');
    if ($handle === false) {
        throw new \RuntimeException("Cannot open {$path}");
    }

    try {
        while (($line = fgets($handle)) !== false) {
            yield str_getcsv(trim($line));
        }
    } finally {
        fclose($handle);
    }
}

foreach (streamCsv('/data/large.csv') as $row) {
    process($row);  // constant memory regardless of file size
}
```

Never `file()` or `file_get_contents()` on multi-MB files — use generators with `fgets()` / `SplFileObject`.

## OPcache — production tuning

OPcache compiles PHP to bytecode and caches it in shared memory — the single most impactful PHP performance setting.

```ini
; php.ini / conf.d/opcache.ini
opcache.enable=1
opcache.memory_consumption=256       ; MB — tune to your app size
opcache.max_accelerated_files=20000  ; raise if opcache.hit_rate drops below 99%
opcache.validate_timestamps=0        ; PRODUCTION only — disable file-change checks
opcache.jit=tracing                  ; PHP 8.0+ JIT — beneficial for CPU-bound code
opcache.jit_buffer_size=64M
```

```dockerfile
# Add to Dockerfile runtime stage
RUN echo "opcache.enable=1\nopcache.validate_timestamps=0\nopcache.jit=tracing\nopcache.jit_buffer_size=64M" \
    >> /usr/local/etc/php/conf.d/opcache.ini
```

**Never** set `opcache.validate_timestamps=0` in development — file changes won't be picked up.

## In-process caching — APCu

APCu provides a shared memory key-value store within the same FPM worker pool — zero network overhead.

```php
<?php

declare(strict_types=1);

// Cache an expensive result for 60 seconds
function getExpensiveData(int $id): array
{
    $cacheKey = "expensive_{$id}";
    $cached   = apcu_fetch($cacheKey, $success);

    if ($success) {
        return (array) $cached;
    }

    $data = computeExpensiveData($id);
    apcu_store($cacheKey, $data, ttl: 60);

    return $data;
}
```

For distributed caching (multi-node), use **Redis** via `predis/predis` or the `phpredis` extension.

## Profiling

| Tool          | Usage                                                           |
| :------------ | :-------------------------------------------------------------- |
| **Blackfire** | Production-grade profiler — timeline, call graph, CI assertions |
| **Xdebug**    | Dev profiler — `xdebug.mode=profile`, analyze with KCacheGrind  |
| **Tideways**  | SaaS APM — low-overhead continuous profiling in production      |
| **SPX**       | Lightweight self-hosted profiler — `SPX_ENABLED=1` env var      |

```bash
# Blackfire — profile a single CLI script
blackfire run php bin/console app:process-orders

# Xdebug — generate cachegrind file
XDEBUG_MODE=profile php -d xdebug.output_dir=/tmp script.php
# then open /tmp/cachegrind.out.* in KCacheGrind / Webgrind
```

Profile first, optimize second. Never optimize without a measurement baseline.

## Preloading (PHP 7.4+)

Preloading compiles and loads framework/library files into shared memory at FPM startup — eliminates per-request class loading overhead.

```ini
; php.ini
opcache.preload=/app/config/preload.php
opcache.preload_user=appuser           ; must match FPM process user
```

```php
<?php
// config/preload.php — list files to preload
$files = glob('/app/vendor/symfony/*/src/**/*.php') ?: [];
foreach ($files as $file) {
    opcache_compile_file($file);
}
```

Requires FPM restart on change. Measure with `opcache_get_status()` — `preload_statistics.memory_consumption` should not exceed 50% of `memory_consumption`.

## Optimization patterns

| Pattern                      | When to use                                                            |
| :--------------------------- | :--------------------------------------------------------------------- |
| Generator + `fgets()`        | Files or result sets too large to load into memory at once             |
| APCu / Redis cache           | Repeated reads of stable data (config, taxonomy, user roles)           |
| OPcache + JIT                | Always in production — baseline gain with zero code change             |
| `SplFixedArray`              | Large homogeneous integer/float arrays (2–3× less memory)              |
| Lazy objects (PHP 8.4+)      | Defer construction of heavy services until first method call           |
| `array_column` / `array_map` | Prefer built-in C functions over manual foreach when processing arrays |
| Connection pooling           | Use PgBouncer (Postgres) or ProxySQL (MySQL) — PHP has no native pool  |

## Success criteria

- Concurrency model matched to the actual workload — PHP-FPM default, async only when measured.
- OPcache enabled with `validate_timestamps=0` and JIT in production.
- Generators used for file/stream processing — no `file_get_contents()` on large inputs.
- APCu or Redis for repeated expensive reads — cache invalidation strategy defined.
- Profiling tool chosen (Blackfire or Xdebug) and baseline measured before any optimization.
- `declare(strict_types=1)` in every file — eliminates type-coercion overhead at the engine level.
