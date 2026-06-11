# JavaScript / TypeScript — Pipeline Blueprint

The role sequence and JS/TS-specific concerns for a CI pipeline. **Do not hard-code tools here** — detect the project's toolchain and resolve each role to a command via `javascript/tool-registry.md`. Wrap the resolved commands as steps/scripts using the platform file (`github/syntax.md` or `gitlab/syntax.md`).

## Role sequence

```text
install → lint → format-check → type-check → test → build → publish → docs
```

Lint / format-check / type-check are independent and gate the rest. `test` fans out across a Node version matrix. `build`, `publish`, `docs` run only on a release ref.

## JS/TS-specific concerns

- **Version matrix:** test the project's supported Node range (the `engines.node` floor up to current LTS, e.g. `["20", "22"]`).
- **Runner prefix:** prefer the project's own `package.json` scripts (`pnpm lint`, `pnpm build`) over raw tool calls — they encode the intended invocation. Use `pnpm exec <tool>` only when there's no script.
- **Frozen installs:** the install command must respect the lockfile — `pnpm install --frozen-lockfile`, `npm ci`, `yarn install --immutable`, `bun install --frozen-lockfile`.
- **Pin the package manager:** `corepack enable && corepack prepare pnpm@<version> --activate` pins the exact pnpm/yarn version without a separate install step.
- **Publish auth:** prefer OIDC + `npm publish --provenance` (signed attestation); fall back to `NPM_TOKEN`. Both resolutions are in the registry.

## Worked example (pnpm + eslint + tsc + vitest)

Detection: `pnpm-lock.yaml`, `eslint.config.*`, `tsconfig.json`, `vitest.config.*`, plus `lint`/`build` scripts → registry lookup yields `pnpm install --frozen-lockfile`, `pnpm lint`, `pnpm exec tsc --noEmit`, `vitest run`. Wrapped for **GitHub Actions**:

```yaml
jobs:
  quality:
    runs-on: ubuntu-24.04
    permissions: { contents: read }
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: 9 }
      - uses: actions/setup-node@v4
        with: { node-version: "22", cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm exec tsc --noEmit

  test:
    needs: [quality]
    runs-on: ubuntu-24.04
    strategy:
      fail-fast: false
      matrix: { node: ["20", "22"] }
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: 9 }
      - uses: actions/setup-node@v4
        with: { node-version: "${{ matrix.node }}", cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm test --run
```

For **GitLab CI**, wrap the same resolved commands as `script:` entries with a lockfile-keyed `cache:` on the package store (see `gitlab/syntax.md`). For **publish** and **docs deploy**, resolve those roles in the registry and place them in the orchestration file's release flow.

An npm / biome / jest project keeps this exact structure but every command differs — re-resolve from the registry, never copy the pnpm commands above.
