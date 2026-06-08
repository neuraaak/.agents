# Config & Toolchain — JavaScript / TypeScript

## Rules

- **VERSION:** Target ES2026 / Node.js 24+ minimum.
- **ESM:** Always `"type": "module"` in `package.json`. Never CommonJS for new projects.
- **MANAGER:** `pnpm` as package manager; commit `pnpm-lock.yaml`.
- **DETERMINISM:** `pnpm install --frozen-lockfile` in CI.

## `package.json` essentials

```json
{
  "type": "module",
  "engines": { "node": ">=24" },
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "lint": "eslint src/",
    "test": "node --test",
    "typecheck": "tsc --noEmit"
  }
}
```

## `tsconfig.json` (TS 6.0+)

```json
{
  "compilerOptions": {
    "target": "ES2026",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "types": [],
    "outDir": "dist",
    "rootDir": "src"
  }
}
```

- `strict: true` is non-negotiable
- `types: []` speeds up compilation by disabling auto-type inclusion
- `noUncheckedIndexedAccess` catches array index bugs

## Modern syntax highlights (ES2026 / Node 24+)

```typescript
// Temporal API — replace all legacy Date usage
const now = Temporal.Now.plainDateTimeISO();

// Explicit Resource Management — auto-cleanup at scope end
await using conn = await getConnection();  // [Symbol.asyncDispose]() called automatically

// Array by Copy — no mutation
const sorted = original.toSorted();
const reversed = original.toReversed();

// AbortController — standard for cancellable async ops
const controller = new AbortController();
const result = await fetch(url, { signal: controller.signal });
```

## Docker multi-stage (Node.js)

```dockerfile
# Build stage
FROM node:24-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install --frozen-lockfile
COPY src/ src/ tsconfig.json ./
RUN pnpm run build

# Runtime stage
FROM node:24-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
WORKDIR /app
COPY --from=builder /app/dist dist/
COPY --from=builder /app/node_modules node_modules/
CMD ["node", "dist/index.js"]
```

## Node.js Permission Model (Node 24+)

Use `--permission` flag for scripts that should have limited filesystem access:

```bash
node --permission --allow-fs-read="./data" --allow-fs-write="./output" app.js
```

## Success criteria

- `"type": "module"` in `package.json`.
- `strict: true` in `tsconfig.json`.
- `pnpm-lock.yaml` committed; `--frozen-lockfile` in CI.
- No `Date` — use `Temporal` API.
- `using` / `await using` for resource management.
- Docker images multi-stage, non-root, pinned tags.
