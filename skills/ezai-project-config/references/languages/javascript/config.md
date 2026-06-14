# Config & Toolchain — JavaScript / TypeScript

## Rules

- **VERSION**: ES2026 / Node.js 24+ minimum.
- **ESM**: always `"type": "module"` in `package.json`. Never CommonJS for new projects.
- **MANAGER**: `pnpm` as the package manager; commit `pnpm-lock.yaml`.
- **DETERMINISM**: `pnpm install --frozen-lockfile` in CI.

## Version pinning

```text
# .nvmrc
24
```

Or via Volta to pin without an extra config file:

```json
{
  "volta": {
    "node": "24.1.0",
    "pnpm": "9.0.0"
  }
}
```

## `package.json` — essentials

```json
{
  "type": "module",
  "engines": { "node": ">=24" },
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "lint": "eslint src/",
    "format": "prettier --write src/",
    "test": "node --test",
    "typecheck": "tsc --noEmit"
  }
}
```

## `tsconfig.json` (TS 5.x)

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

- `strict: true` non-negotiable
- `types: []` speeds up compilation by disabling automatic type inclusion
- `noUncheckedIndexedAccess` catches array-index bugs

## ESLint — config (flat config, ESLint 9+)

```javascript
// eslint.config.js
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.strict,
  {
    rules: {
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "@typescript-eslint/explicit-function-return-type": "error",
    },
  },
);
```

## Modern syntax (ES2026 / Node 24+)

```typescript
// Temporal API — replaces any use of Date
const now = Temporal.Now.plainDateTimeISO();

// Explicit Resource Management — automatic cleanup at end of scope
await using conn = await getConnection();  // [Symbol.asyncDispose]() called automatically

// Array by Copy — no mutation
const sorted = original.toSorted();
const reversed = original.toReversed();

// AbortController — standard for cancellable async ops
const controller = new AbortController();
const result = await fetch(url, { signal: controller.signal });
```

## Environment variables

```typescript
// Startup validation — fail fast if a required var is missing
function getEnv(key: string): string {
  const value = process.env[key];
  if (!value) throw new Error(`Required environment variable '${key}' is not set`);
  return value;
}

const DATABASE_URL = getEnv("DATABASE_URL");
const API_KEY = getEnv("API_KEY");
```

- `.env` local only — always in `.gitignore`.
- In CI: inject via the platform's secrets.
- For Next.js projects: `@t3-oss/env-nextjs` for typed env-var validation.

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
HEALTHCHECK --interval=30s --timeout=5s CMD node -e "fetch('http://localhost:3000/health').then(r => process.exit(r.ok ? 0 : 1))"
CMD ["node", "dist/index.js"]
```

## Node.js Permission Model (Node 24+)

```bash
node --permission --allow-fs-read="./data" --allow-fs-write="./output" app.js
```

## Success criteria

- `"type": "module"` in `package.json`.
- `strict: true` in `tsconfig.json`.
- `pnpm-lock.yaml` committed; `--frozen-lockfile` in CI.
- ESLint flat config with typescript-eslint strict.
- No `Date` — use the `Temporal` API.
- `using` / `await using` for resource management.
- Secrets via environment variables — validated at startup.
- Multi-stage Docker images, non-root, pinned tags.
