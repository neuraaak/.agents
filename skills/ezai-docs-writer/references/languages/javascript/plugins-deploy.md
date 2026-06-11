# VitePress — Plugins & Deployment

Load this file when wiring the sidebar/navbar, building the API reference, adding version switching, or deploying the docs site. For the canonical `docs/.vitepress/config.mts` itself, load `toolchain.md`.

Stack: **VitePress + TypeDoc + vitepress-versioning-plugin**, deployed to GitHub Pages.

For the canonical config file (`docs/.vitepress/config.mts`), the recommended stack table, and the config-location/extension rules, load `toolchain.md`. This file covers only the operational wiring and deployment.

---

## Navigation (`nav` + `sidebar`)

VitePress has two navigation surfaces, both under `themeConfig`:

- **`nav`** — the top navbar; one entry per top-level section, mirroring Diátaxis (Getting Started → CLI Reference → Skills → Guides).
- **`sidebar`** — the left tree. Use the **array form** for a single global sidebar, or the **object form** (keyed by path prefix, e.g. `/guides/`) for per-section sidebars.

Rules:

- A folder link ending in `/` (e.g. `/cli/`) resolves to that folder's `index.md` automatically — let sections be clickable this way rather than linking the index file explicitly.
- Keep `nav` and `sidebar` section names consistent so the two surfaces don't drift.

---

## API reference (`TypeDoc`)

`TypeDoc` renders the API reference from JSDoc/TSDoc comments — the JS analogue of mkdocstrings. Use `typedoc-plugin-markdown` so it emits `.md` files VitePress can consume:

| `typedoc.json` key | Set to                        | Why                                |
| :----------------- | :---------------------------- | :--------------------------------- |
| `entryPoints`      | `["src/index.ts"]`            | the package's public entry         |
| `out`              | `docs/api`                    | output into the docs tree          |
| `plugin`           | `["typedoc-plugin-markdown"]` | emit Markdown, not standalone HTML |

**Run order is mandatory** — TypeDoc must regenerate the API pages before VitePress builds:

```bash
typedoc          # src → docs/api/*.md
vitepress build docs
```

In TypeScript, omit `{type}` from JSDoc `@param` tags — the TypeScript signature is the authority (see `languages/javascript/standards.md`).

---

## Versioning (`vitepress-versioning-plugin`)

Adds a version-switcher dropdown to the navbar and serves versioned snapshots — the JS analogue of mike. Install with `pnpm add -D vitepress-versioning-plugin`, then wire it via `defineVersionedConfig` with `versioning` as an inner key — see `toolchain.md` for the canonical config (the old `withVersioning(...)` wrapper does not exist in this plugin).

Snapshot the current docs at release time, then commit the result:

```bash
pnpm vitepress-versioning snapshot <version>   # docs/ → versioned_docs/v<version>/
```

Rules:

- `latestVersion` **must equal the `package.json` version** — the switcher uses it to label the current branch. Automate it: `node -p "require('./package.json').version"`.
- `versioned_docs/` is the source of truth for old versions — **commit it** so CI can build every version, and **never hand-edit** its files; re-snapshot from `docs/` instead.

---

## CI deployment (GitHub Pages)

The build output is `docs/.vitepress/dist`; upload it with `actions/upload-pages-artifact` and deploy via `actions/deploy-pages`. The deploy job must:

1. Set up the pinned package manager (`pnpm/action-setup`) and Node, with dependency caching keyed on `pnpm-lock.yaml`.
2. Install frozen, then rebuild native binaries skipped by `--ignore-scripts`:

   ```bash
   pnpm install --frozen-lockfile --ignore-scripts
   pnpm rebuild esbuild es5-ext vue-demi
   ```

   `esbuild` is VitePress's bundler; `es5-ext` + `vue-demi` are required by `vitepress-versioning-plugin`. Add any binary `pnpm rebuild` warns is missing.
3. `pnpm run docs:build`, upload the artifact, deploy.

Grant only `pages: write` + `id-token: write` on the deploy job (workflow default `permissions: {}`); pin the runner image (`ubuntu-24.04`) and every action. See the `ezai-cicd-expert` skill for the full workflow.

---

## Anti-patterns

| Anti-pattern                                         | Problem                                        | Fix                                                   |
| :--------------------------------------------------- | :--------------------------------------------- | :---------------------------------------------------- |
| Config at repo-root `.vitepress/` under `build docs` | Config never loaded; site builds with defaults | Place it at `docs/.vitepress/config.mts`              |
| `config.js`/`config.ts` in a CommonJS package        | *"ESM file cannot be loaded by require"* crash | Use the `.mts`/`.mjs` extension                       |
| `withVersioning(defineConfig(…))`                    | Export does not exist; config load throws      | Use `defineVersionedConfig(config, __dirname)`        |
| Sidebar as an array with versioning enabled          | Plugin disables versioning silently            | Use the object form `{ '/': [...] }`                  |
| `latestVersion` out of sync with `package.json`      | Switcher mislabels the current version         | Derive it from `package.json` at config time          |
| Hand-editing files in `versioned_docs/`              | Snapshot diverges from source                  | Edit `docs/`, then re-run the snapshot command        |
| Committing `docs/` but not `versioned_docs/`         | CI build is missing old versions               | Commit `versioned_docs/`                              |
| `base` missing or mismatched to the Pages subpath    | All assets and links 404                       | Set `base: "/<project>/"` exactly                     |
| `lastUpdated: true` with a shallow CI checkout       | Every page shows the same date                 | Set `fetch-depth: 0` in the checkout step             |
| Building before TypeDoc regenerates `docs/api`       | Stale or missing API reference                 | Run `typedoc` before `vitepress build`                |
| `pnpm install` without rebuilding native binaries    | Build fails on missing `esbuild`               | `pnpm rebuild esbuild es5-ext vue-demi` after install |
