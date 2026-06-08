# JS/TS Docs Toolchain — Recommended Stack & Canonical `config.mts`

Load this file when **choosing the documentation tooling** for a JavaScript/TypeScript project, or when **scaffolding the VitePress config from scratch**. It defines the recommended tool stack and a copy-paste canonical config.

For the operational rules behind these choices — navigation wiring, `mike`-style versioning snapshots, CI deploy to GitHub Pages, anti-patterns — load `plugins-deploy.md`. This file is the *what to install and what the config looks like*; `plugins-deploy.md` is the *how to run and deploy it*.

---

## Recommended stack

For any JS/TS library, the canonical documentation stack is **VitePress + TypeDoc**. Pick this unless the project already standardized on Docusaurus.

| Tool                             | Role                                  | Why it is the default                                               |
| :------------------------------- | :------------------------------------ | :------------------------------------------------------------------ |
| `vitepress`                      | Static site generator + theme         | Vite-fast, Markdown-native, built-in dark mode and code copy        |
| `typedoc`                        | API reference from TSDoc comments     | Renders TS types as the authority — the JS analogue of mkdocstrings |
| `typedoc-plugin-markdown`        | Emit `.md` instead of standalone HTML | Lets VitePress own the rendering of the API pages                   |
| `vitepress-versioning-plugin`    | Versioned doc snapshots               | Version switcher in the navbar — the JS analogue of mike            |
| local search (`provider: local`) | Client-side full-text search          | No external service; the analogue of Material's search plugin       |

Declare these in `devDependencies` and drive them through `package.json` scripts (`docs:dev`, `docs:build`, `docs:preview`) so CI installs them with `pnpm install --frozen-lockfile`.

Reach for **Docusaurus** only when the project needs React-based MDX components, a built-in blog/versioned-docs UX, or a richer plugin ecosystem. For everything else, VitePress is lighter and the Diátaxis templates in `common/quadrants-templates.md` assume it.

---

## Config file location & extension — two rules that silently break the build

These two decisions are load-bearing. Getting them wrong produces a build that *appears* to work but ignores your config entirely.

1. **Location must match the build root argument.** The scripts run `vitepress build docs`, so `docs` is the *root* and VitePress resolves its config at `<root>/.vitepress/config.*` → **`docs/.vitepress/config.mts`**. A config placed at the repo root (`./.vitepress/`) is never loaded under `vitepress build docs`; the site builds with defaults (no `base`, no versioning) and links 404 on Pages.
2. **Extension must be `.mts` (or `.mjs`).** VitePress and `vitepress-versioning-plugin` are **ESM-only**. Most library repos are CommonJS (no `"type": "module"` in `package.json`, `require()` in source). A plain `config.js`/`config.ts` is then loaded as CJS and crashes with *"ESM file cannot be loaded by require"*. Force ESM with the `.mts`/`.mjs` extension instead of flipping the whole package to `"type": "module"`.

---

## Canonical `docs/.vitepress/config.mts`

Copy this as the baseline. Replace every `<project>` / `<owner>` token — derive each value from the project, never carry over another project's values. Drop theme options the site does not actually use rather than leaving them dormant.

```ts
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import defineVersionedConfig from 'vitepress-versioning-plugin';

const __dirname = dirname(fileURLToPath(import.meta.url));

// defineVersionedConfig wraps defineConfig; `versioning` is an INNER key, and the
// second argument is the .vitepress dir. The old `withVersioning(...)` API does not exist.
export default defineVersionedConfig(
  {
    title: '<project>',
    description: '<one-line description of the project>',
    lang: 'en-US',
    base: '/<project>/', // must match the GitHub Pages subpath exactly, with both slashes

    ignoreDeadLinks: false, // fail the build on broken internal links — the analogue of mkdocs `strict: true`
    cleanUrls: true, // drop the .html suffix from generated URLs
    lastUpdated: true, // git commit date per page — needs fetch-depth: 0 in CI checkout

    head: [
      ['link', { rel: 'icon', href: '/<project>/favicon.ico' }],
      ['meta', { name: 'theme-color', content: '#646cff' }],
    ],

    sitemap: {
      hostname: 'https://<owner>.github.io/<project>/',
    },

    versioning: {
      latestVersion: '<x.y.z>', // MUST equal package.json version; the switcher labels the current branch with it
    },

    themeConfig: {
      search: { provider: 'local' }, // client-side full-text search, no external service

      // Top navbar — one entry per Diátaxis section.
      nav: [
        { text: 'Getting Started', link: '/getting-started' },
        { text: 'Guides', link: '/guides/' },
        { text: 'API Reference', link: '/api/' },
      ],

      // Multi-sidebar OBJECT form (keyed by path) — required by the versioning plugin.
      // The array form silently disables version-scoped sidebars.
      sidebar: {
        '/': [
          {
            text: 'Introduction',
            items: [{ text: 'Getting Started', link: '/getting-started' }],
          },
          {
            text: 'Reference',
            items: [{ text: 'API Reference', link: '/api/' }],
          },
          {
            text: 'Guides',
            items: [{ text: 'Overview', link: '/guides/' }],
          },
        ],
      },

      outline: { level: [2, 3], label: 'On this page' },

      editLink: {
        pattern: 'https://github.com/<owner>/<project>/edit/main/docs/:path',
        text: 'Edit this page on GitHub',
      },

      lastUpdated: {
        text: 'Last updated',
        formatOptions: { dateStyle: 'medium', timeStyle: 'short' },
      },

      docFooter: { prev: 'Previous', next: 'Next' },

      socialLinks: [{ icon: 'github', link: 'https://github.com/<owner>/<project>' }],

      footer: {
        message: 'Released under the MIT License.',
        copyright: 'Copyright © <year>-present <owner>',
      },
    },

    markdown: {
      lineNumbers: true,
    },
  },
  __dirname,
);
```

A plain-JavaScript library uses the same file as `config.mjs`, dropping only the TS type annotations — the structure and every key are identical.

---

## Best practices encoded in this config

These are the load-bearing decisions — keep them when adapting the config.

- **Config lives at `docs/.vitepress/`, extension `.mts`/`.mjs`.** See the two-rules section above — both failures are silent and produce a wrong-but-green build.
- **`defineVersionedConfig(config, __dirname)`, `versioning` as an inner key.** This is the real plugin API; `withVersioning(defineConfig(...))` is not exported and throws *"does not provide an export named"*. `latestVersion` **must equal `package.json` version** — derive it with `node -p "require('./package.json').version"`.
- **Sidebar in the multi-sidebar object form `{ '/': [...] }`.** The array form makes the versioning plugin log *"sidebar cannot be an array"* and **disable versioning** — the switcher still renders but old versions get the wrong sidebar.
- **`base: '/<project>/'` matches the Pages subpath exactly.** A missing or mismatched `base` makes every asset and internal link 404 on GitHub Pages.
- **`ignoreDeadLinks: false`.** Broken internal links fail `vitepress build`, so CI catches doc rot — the analogue of `mkdocs build --strict`.
- **`lastUpdated: true` requires full git history.** The CI checkout must set `fetch-depth: 0`; with the default shallow clone every page shows the same date.
- **API nav mirrors the package's public surface.** Generate `docs/api/*.md` with TypeDoc + `typedoc-plugin-markdown` **before** `vitepress build` (see `plugins-deploy.md` for the run order). In TypeScript, omit `{type}` from JSDoc/TSDoc `@param` — the signature is the authority (see `standards.md`).
- **`search: { provider: 'local' }`** ships zero-config client-side search; switch to Algolia only when the corpus outgrows it.
- **Enable only theme options the layout uses.** `editLink`, `outline`, `docFooter`, and `lastUpdated` labels each map to a real on-page affordance — drop the ones the site does not surface rather than leaving them dormant.
- **Versioning snapshots are committed, never hand-edited.** `versioned_docs/` is the source of truth for old versions; re-snapshot from `docs/` instead. See `plugins-deploy.md` for the snapshot command and deploy cascade.
