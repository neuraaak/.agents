# Config & Toolchain — React (delta)

> **Delta** on `references/languages/javascript/config.md`. Load the JS/TS base
> file first; this file only adds or overrides what changes when React is used.
> Build tool assumed: **Vite 5+** (SPA). For SSR/Next.js, the env-var note in the
> base file (`@t3-oss/env-nextjs`) already applies.

## Detection

`react` / `react-dom` in `dependencies`, or `vite` + `@vitejs/plugin-react` in
`devDependencies`.

## `package.json` — scripts delta

Replace the base `build` / `test` scripts (no `tsc` entry point — Vite drives the build):

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview",
    "lint": "eslint src/",
    "typecheck": "tsc --noEmit",
    "test": "vitest run"
  }
}
```

- `tsc -b` runs type-checking only (no emit); `vite build` produces the bundle.
- Test runner is **Vitest** (Vite-native), not `node --test`.

## `vite.config.ts`

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  build: { target: "ES2026", sourcemap: true },
});
```

## ESLint — React delta

Extend the base flat config with the React Hooks rules (append to the array):

```javascript
import reactHooks from "eslint-plugin-react-hooks";
import reactRefresh from "eslint-plugin-react-refresh";

// ...append to the existing tseslint.config(...) array:
{
  plugins: { "react-hooks": reactHooks, "react-refresh": reactRefresh },
  rules: {
    ...reactHooks.configs.recommended.rules,
    "react-refresh/only-export-components": "warn",
  },
}
```

## Environment variables — Vite delta

Vite exposes env vars via `import.meta.env`, **not** `process.env`. Only the
`VITE_` prefix is exposed to client code; everything else stays server-side.

```typescript
// src/env.ts — typed, validated at module load
const API_URL = import.meta.env.VITE_API_URL;
if (!API_URL) throw new Error("VITE_API_URL is not set");
export { API_URL };
```

- **Never** prefix a secret with `VITE_` — it ships in the client bundle.
- `.env`, `.env.local` in `.gitignore` (base rule still applies).

## Docker — static build + serve delta

The base Node runtime stage is replaced by a static server (no Node at runtime):

```dockerfile
# Build stage
FROM node:24-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm run build

# Runtime stage — static assets only
FROM nginx:1.27-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
HEALTHCHECK --interval=30s --timeout=5s CMD wget -qO- http://localhost/ || exit 1
```

## Success criteria (React)

- Vite drives the build; `tsc -b` for type-check only.
- Test runner is Vitest.
- ESLint extends `react-hooks` recommended rules over the base config.
- Client env vars via `import.meta.env`, `VITE_` prefix only — no secret exposed.
- Runtime image serves static assets (nginx), pinned tag, no Node at runtime.
