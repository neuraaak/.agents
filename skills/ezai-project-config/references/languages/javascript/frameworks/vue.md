# Config & Toolchain — Vue (delta)

> **Delta** on `references/languages/javascript/config.md`. Load the JS/TS base
> file first; this file only adds or overrides what changes when Vue is used.
> Build tool assumed: **Vite 5+** (SPA). For SSR/Nuxt, adapt env-var handling to
> `useRuntimeConfig()`.

## Detection

`vue` in `dependencies`, or `vite` + `@vitejs/plugin-vue` in `devDependencies`.

## `package.json` — scripts delta

Replace the base `build` / `test` scripts (Vite drives the build):

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc -b && vite build",
    "preview": "vite preview",
    "lint": "eslint src/",
    "typecheck": "vue-tsc --noEmit",
    "test": "vitest run"
  }
}
```

- `vue-tsc -b` for type-checking `.vue` files; `vite build` produces the bundle.
- Test runner is **Vitest** (Vite-native), not `node --test`.

## `vite.config.ts`

```typescript
import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

export default defineConfig({
  plugins: [vue()],
  build: { target: "ES2026", sourcemap: true },
});
```

## `tsconfig.json` — Vue delta

`vue-tsc` requires `"moduleResolution": "bundler"` and the Vue types include:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "jsx": "preserve",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "types": ["vite/client"]
  },
  "include": ["src/**/*.ts", "src/**/*.d.ts", "src/**/*.tsx", "src/**/*.vue"]
}
```

## ESLint — Vue delta

Extend the base flat config with `eslint-plugin-vue` rules (append to the array):

```javascript
import pluginVue from "eslint-plugin-vue";
import vueParser from "vue-eslint-parser";

// ...append to the existing tseslint.config(...) array:
{
  files: ["**/*.vue"],
  languageOptions: { parser: vueParser, parserOptions: { parser: tseslint.parser } },
  plugins: { vue: pluginVue },
  rules: {
    ...pluginVue.configs["flat/recommended"].rules,
  },
}
```

## Environment variables — Vite delta

Vite exposes env vars via `import.meta.env`, **not** `process.env`. Only the
`VITE_` prefix is exposed to client code.

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

## Success criteria (Vue)

- Vite drives the build; `vue-tsc -b` for type-check only.
- Test runner is Vitest.
- ESLint extends `eslint-plugin-vue` flat/recommended rules over the base config.
- Client env vars via `import.meta.env`, `VITE_` prefix only — no secret exposed.
- Runtime image serves static assets (nginx), pinned tag, no Node at runtime.
