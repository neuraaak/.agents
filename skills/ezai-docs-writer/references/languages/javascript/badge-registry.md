# Badge Registry — JavaScript / TypeScript

JS/TS-specific badges: npm version + tool badges. Combine with the forge badge registry (`forge/github/badge-registry.md` or `forge/gitlab/badge-registry.md`) for the full badge block.

This file is **data, not a rule**. Detect → look up → emit:

1. **Detect** which tools the project actually uses (signals below).
2. **Look up** the badge template.
3. **Emit** only for confirmed tools. Never emit a badge for a tool not present.

Replace `{pkg}` with the package name from `package.json`.

**Logo and color** follow [simple-icons](https://simpleicons.org). Never guess — a wrong slug renders a blank icon.

---

## Registry version badges (public-oss only)

Always emit both for public npm packages:

```markdown
[![npm version](https://img.shields.io/npm/v/{pkg}?style=flat&logo=npm&logoColor=white)](https://www.npmjs.com/package/{pkg})
[![node versions](https://img.shields.io/node/v/{pkg}?style=flat&logo=nodedotjs&logoColor=white)](https://www.npmjs.com/package/{pkg})
```

Omit for `internal` profile.

---

## Tool badges

Each entry: **tool** — detect via · logo slug · brand hex

### Package manager

- pnpm — `pnpm-lock.yaml` · `pnpm` · `F69220`
- npm — `package-lock.json` · `npm` · `CB3837`
- yarn — `yarn.lock` · `yarn` · `2C8EBB`
- bun — `bun.lockb` · `bun` · `FBF0DF`

### Linter

- eslint — `eslint.config.*` or `.eslintrc*` · `eslint` · `4B32C3`
- biome — `biome.json` · `biome` · `60A5FA`
- oxlint — `.oxlintrc.json` · `oxc` · `lightgrey`

### Formatter

- prettier — `.prettierrc*` or `prettier` key in `package.json` · `prettier` · `F7B93E`
- biome — `biome.json` · covered by biome linter badge, no separate badge needed

### Type checker

- typescript — `tsconfig.json` · `typescript` · `3178C6`

### Test runner

- vitest — `vitest.config.*` · `vitest` · `6E9F18`
- jest — `jest.config.*` or `jest` key in `package.json` · `jest` · `C21325`
- mocha — `.mocharc*` · `mocha` · `8D6748`

### Build / bundler

- vite — `vite.config.*` · `vite` · `646CFF`
- webpack — `webpack.config.*` · `webpack` · `8DD6F9`
- rollup — `rollup.config.*` · `rollupdotjs` · `EC4A3F`
- esbuild — `esbuild` in scripts/deps · `esbuild` · `FFCF00`

---

## Badge template

```markdown
[![{role}](https://img.shields.io/badge/{role}-{tool}-{color}?style=flat&logo={logo}&logoColor=white)]({link})
```

Omit `&logo={logo}&logoColor=white` when the tool has no logo slug. Use the tool's homepage as `{link}`.

---

## Example

Project with `pnpm-lock.yaml`, `eslint.config.js`, `tsconfig.json`, `vitest.config.ts`, `vite.config.ts` on GitHub → emit: npm version + node versions, then pnpm, eslint, typescript, vitest, vite tool badges.
