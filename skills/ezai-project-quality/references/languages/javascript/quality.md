# Quality — JavaScript / TypeScript

## Test framework

Prefer `node:test` (native, zero dependencies). Use `Vitest` for Vite-based projects.

```typescript
import test from "node:test";
import assert from "node:assert/strict";

test("OrderService", async (t) => {
  await t.test("calculates total with tax", () => {
    const total = calculateTotal([{ price: 10 }, { price: 20 }], 0.2);
    assert.strictEqual(total, 36);
  });

  await t.test("throws on empty items", () => {
    assert.throws(() => calculateTotal([], 0.2), /empty/i);
  });
});
```

## Schema validation at boundaries

```typescript
import { z } from "zod";

const UserSchema = z.object({
  id: z.number().positive(),
  email: z.string().email(),
  role: z.enum(["admin", "user"]),
});

type User = z.infer<typeof UserSchema>;

// Validate at the boundary — fail fast
const user = UserSchema.parse(rawRequestBody);
```

Use Zod (or TypeBox) at every I/O boundary: HTTP handlers, file parsers, LLM response processors.

## Property-based testing

```typescript
import fc from "fast-check";
import test from "node:test";
import assert from "node:assert/strict";

test("sort preserves length", () => {
  fc.assert(
    fc.property(fc.array(fc.integer()), (arr) => {
      assert.strictEqual([...arr].sort().length, arr.length);
    }),
  );
});
```

## Secret management

```typescript
import "dotenv/config";  // loads .env automatically

const API_KEY = process.env.API_KEY ?? "";
```

- **Dev:** `.env` (git-ignored) + `dotenv`
- **Prod:** AWS Secrets Manager, Vault, or platform env vars
- **Never:** commit secrets, log secrets, or embed them in client bundles

## Security rules

- `node:crypto` or Web Crypto API — never legacy `crypto-js`.
- Strict Zod validation on all external and LLM-generated data before processing.
- Node.js `--permission` flag (Node 24+) for sandboxing scripts.
- `helmet` (Express) or equivalent for HTTP security headers (CSP, HSTS, etc.).
- `pnpm audit` in CI for dependency vulnerability scanning.

## Structured logging

```typescript
import { randomUUID } from "node:crypto";

const requestId = randomUUID();

function log(level: "info" | "warn" | "error", message: string, meta?: object) {
  console.log(JSON.stringify({ level, message, requestId, ...meta }));
}
```

Propagate correlation IDs across service boundaries for distributed tracing.

## Success criteria

- `node:test` or Vitest used; no Jest unless already in the project.
- Zod validation at every I/O boundary.
- Property-based tests for complex invariants via `fast-check`.
- No secrets in source, logs, or client bundles.
- Coverage 80–90% on business logic.
