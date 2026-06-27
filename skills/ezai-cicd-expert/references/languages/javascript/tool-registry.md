# CI Tool Registry — JavaScript / TypeScript

This file is **data, not a rule**. Detect → look up → substitute:

1. **Detect** which tool fills each role (config files, lockfiles — see the detection signal).
2. **Look up** the CI command below.
3. **Substitute** into the pipeline skeleton (role sequence in `javascript/pipelines.md`, step syntax in the platform file).

Never hard-code a fixed stack. An npm + biome + jest project must yield a different pipeline than a pnpm + eslint + vitest one.

**Prefer the project's own scripts.** If `package.json` defines `"lint"`, `"test"`, `"build"`, call `pnpm lint`, `pnpm test`, `pnpm build` — they encode the intended invocation and stay correct as the project evolves. Use `pnpm exec <tool>` only when no script wraps it.

**Pin the package manager version** with `corepack enable && corepack prepare pnpm@<version> --activate` (or equivalent for yarn) — avoids version drift across runner images.

**If multiple candidates match,** the one with a config file/lockfile present wins. If still ambiguous, ask.

---

## Package install (reproducible)

- pnpm — `pnpm-lock.yaml` · `pnpm install --frozen-lockfile`
- npm — `package-lock.json` · `npm ci`
- yarn — `yarn.lock` · `yarn install --immutable`
- bun — `bun.lockb` · `bun install --frozen-lockfile`

## Lint

- eslint — `eslint.config.*` or `.eslintrc*` · `eslint .`
- biome — `biome.json` · `biome ci .` (covers lint + format in one pass)
- oxlint — `.oxlintrc.json` · `oxlint`

## Format check

- prettier — `.prettierrc*` or `prettier` key in `package.json` · `prettier --check .`
- biome — `biome.json` · covered by `biome ci` above, no separate step needed

## Type check

- tsc — `tsconfig.json` · `tsc --noEmit`

## Test (+ coverage)

- vitest — `vitest.config.*` · `vitest run` (coverage: `vitest run --coverage`)
- jest — `jest.config.*` or `jest` key in `package.json` · `jest --ci`
- mocha — `.mocharc*` · `mocha`

## Security scan (SAST + dependencies)

- eslint-plugin-security (SAST) — plugin in `eslint.config.*` · covered by the `eslint .` lint step (no separate command)
- semgrep (SAST, custom rules) — `.semgrep.yml` or `semgrep` in deps · `semgrep --config=p/javascript --error`
- codeql (SAST, GitHub-native) — GitHub repo · `github/codeql-action/analyze` with `languages: javascript`
- pnpm/npm audit (dependencies) — lockfile present · `pnpm audit --omit=dev` (npm: `npm audit --omit=dev`)
- socket (supply chain, pre-install) — `@socketsecurity/cli` · `socket scan create` (behavioral, complements audit)

## Build (package artifact)

- build script (preferred) — `"build"` in `package.json` scripts · call via package manager (e.g. `pnpm build`)
- tsc — `tsconfig.json`, library without bundler · `tsc`
- vite — `vite.config.*` · `vite build`

## Publish (to npm)

- OIDC + provenance (preferred) — `id-token: write` (GitHub) · `npm publish --provenance --access public`, no stored token
- API token (fallback) — `NPM_TOKEN` secret · `npm publish --access public` (env `NODE_AUTH_TOKEN=$NPM_TOKEN`)

## Docs build / deploy

- vitepress — `.vitepress/config.*` · `vitepress build docs`, deploy the generated `docs/.vitepress/dist`
- docusaurus — `docusaurus.config.*` · `docusaurus build`, deploy `build/`
- typedoc — `typedoc.json` or `typedoc` in deps · `typedoc` (API reference, output to `docs/api`)

---

## Example resolution

`package.json` with pnpm lockfile, `eslint.config.js`, `tsconfig.json`, `vitest.config.ts`, `"build"` + `"lint"` scripts, `.vitepress/config.ts`, npm OIDC publish:

| Role         | Resolved command                  |
| :----------- | :-------------------------------- |
| install      | `pnpm install --frozen-lockfile`  |
| lint         | `pnpm lint`                       |
| format check | `prettier --check .`              |
| type check   | `pnpm exec tsc --noEmit`          |
| test         | `pnpm test --run`                 |
| build        | `pnpm build`                      |
| publish      | `npm publish --provenance` (OIDC) |
| docs         | `vitepress build docs`            |
