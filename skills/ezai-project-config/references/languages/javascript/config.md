# Config & Toolchain — JavaScript / TypeScript

## Règles

- **VERSION** : ES2026 / Node.js 24+ minimum.
- **ESM** : toujours `"type": "module"` dans `package.json`. Jamais CommonJS pour les nouveaux projets.
- **MANAGER** : `pnpm` comme gestionnaire de packages ; committer `pnpm-lock.yaml`.
- **DETERMINISM** : `pnpm install --frozen-lockfile` en CI.

## Version pinning

```text
# .nvmrc
24
```

Ou via Volta pour épingler sans fichier de config supplémentaire :

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

- `strict: true` non négociable
- `types: []` accélère la compilation en désactivant l'inclusion automatique de types
- `noUncheckedIndexedAccess` détecte les bugs d'index de tableau

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

## Syntaxe moderne (ES2026 / Node 24+)

```typescript
// Temporal API — remplace tout usage de Date
const now = Temporal.Now.plainDateTimeISO();

// Explicit Resource Management — cleanup automatique à la fin du scope
await using conn = await getConnection();  // [Symbol.asyncDispose]() appelé automatiquement

// Array by Copy — pas de mutation
const sorted = original.toSorted();
const reversed = original.toReversed();

// AbortController — standard pour les ops async annulables
const controller = new AbortController();
const result = await fetch(url, { signal: controller.signal });
```

## Variables d'environnement

```typescript
// Validation au démarrage — fail fast si une var requise est absente
function getEnv(key: string): string {
  const value = process.env[key];
  if (!value) throw new Error(`Required environment variable '${key}' is not set`);
  return value;
}

const DATABASE_URL = getEnv("DATABASE_URL");
const API_KEY = getEnv("API_KEY");
```

- `.env` en local uniquement — toujours dans `.gitignore`.
- En CI : injecter via les secrets de la plateforme.
- Pour les projets Next.js : `@t3-oss/env-nextjs` pour la validation typée des env vars.

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

## Critères de succès

- `"type": "module"` dans `package.json`.
- `strict: true` dans `tsconfig.json`.
- `pnpm-lock.yaml` commité ; `--frozen-lockfile` en CI.
- ESLint flat config avec typescript-eslint strict.
- Pas de `Date` — utiliser l'API `Temporal`.
- `using` / `await using` pour la gestion des ressources.
- Secrets via variables d'environnement — validation au démarrage.
- Images Docker multi-stage, non-root, tags épinglés.
