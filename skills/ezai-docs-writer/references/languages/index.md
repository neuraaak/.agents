# Languages Index

Routing for language-specific references. All paths are written from the
`references/` root.

| Language              | Subdirectory            | Detect via                     |
| :-------------------- | :---------------------- | :----------------------------- |
| Python                | `languages/python/`     | `pyproject.toml`, `*.py`       |
| JavaScript/TypeScript | `languages/javascript/` | `package.json`, `*.ts`, `*.js` |

Each language pairs with `common/` for the language-agnostic layer. Load only
what the task needs.

---

## Python (`languages/python/`)

Stack: MkDocs + Material + mkdocstrings + Diátaxis framework.

- `languages/python/standards.md` — Python/MkDocs specifics: Google-style docstrings, admonition/annotation syntax (**pair with** `common/standards.md`)
- `languages/python/toolchain.md` — choosing the docs tool stack, scaffolding `mkdocs.yml` from scratch (canonical config + best practices)
- `languages/python/plugins-deploy.md` — configuring MkDocs plugins, deploying with mike, release cascade (auto-tag → publish-pypi → docs), git-cliff changelog
- `languages/python/badge-registry.md` — emitting a badge block (PyPI version + tool badges); pair with the forge registry in `forge/`

---

## JavaScript/TypeScript (`languages/javascript/`)

Stack: VitePress or Docusaurus + TypeDoc + JSDoc/TSDoc + Diátaxis framework.

- `languages/javascript/standards.md` — JS/TS specifics: JSDoc/TSDoc syntax, VitePress admonition syntax (**pair with** `common/standards.md`)
- `languages/javascript/toolchain.md` — choosing the docs tool stack, scaffolding `docs/.vitepress/config.mts` from scratch (canonical config + best practices)
- `languages/javascript/plugins-deploy.md` — wiring VitePress nav/sidebar, API reference, versioning, deploying to GitHub Pages
- `languages/javascript/badge-registry.md` — emitting a badge block (npm version + tool badges); pair with the forge registry in `forge/`

For page templates, use `common/quadrants-templates.md` — replace Python snippets with TypeScript/JavaScript equivalents.

---

## Adding a new language

1. Create a `languages/<language>/` subdirectory.
2. Add `standards.md` and `badge-registry.md` at minimum.
3. Register in the routing table above.
