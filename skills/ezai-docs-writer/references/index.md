# Documentation References Index

Route to the correct files based on the project language **and** platform.

## Language routing

| Language              | Subdirectory  |
| :-------------------- | :------------ |
| Python                | `python/`     |
| JavaScript/TypeScript | `javascript/` |

## Platform routing (badges only)

| Platform | Detect via                             | Badge registry             |
| :------- | :------------------------------------- | :------------------------- |
| GitHub   | `github.com` remote / `.github/`       | `github/badge-registry.md` |
| GitLab   | `gitlab.com` remote / `.gitlab-ci.yml` | `gitlab/badge-registry.md` |

When emitting a badge block, load the **pair**: platform registry + language registry. For page templates (any language), load `common/quadrants-templates.md` — templates are language-agnostic.

---

## Python (`python/`)

Stack: MkDocs + Material + mkdocstrings + Diátaxis framework.

- `python/standards.md` — Python/MkDocs specifics: Google-style docstrings, admonition/annotation syntax (pair with `common/standards.md`)
- `python/toolchain.md` — choosing the docs tool stack, scaffolding `mkdocs.yml` from scratch (canonical config + best practices)
- `python/plugins-deploy.md` — configuring MkDocs plugins, deploying with mike, release cascade (auto-tag → publish-pypi → docs), git-cliff changelog
- `python/badge-registry.md` — emitting a badge block (PyPI version + tool badges)

---

## JavaScript/TypeScript (`javascript/`)

Stack: VitePress or Docusaurus + TypeDoc + JSDoc/TSDoc + Diátaxis framework.

- `javascript/standards.md` — JS/TS specifics: JSDoc/TSDoc syntax, VitePress admonition syntax (pair with `common/standards.md`)
- `javascript/toolchain.md` — choosing the docs tool stack, scaffolding `docs/.vitepress/config.mts` from scratch (canonical config + best practices)
- `javascript/plugins-deploy.md` — wiring VitePress nav/sidebar, API reference, versioning, deploying to GitHub Pages
- `javascript/badge-registry.md` — emitting a badge block (npm version + tool badges)

For page templates, use `common/quadrants-templates.md` — replace Python snippets with TypeScript/JavaScript equivalents.

---

## Common (`common/`)

- `common/standards.md` — language-agnostic doc standards: Diátaxis rules, emoji set, admonition semantics, anti-patterns (always pair with the language `standards.md`)
- `common/quadrants-templates.md` — Diátaxis quadrants & page templates (any language)
- `common/readme.md` — generating or auditing a `README.md`

---

## Platform (`github/` · `gitlab/`)

- `github/badge-registry.md` — core badges for GitHub projects (CI, Docs, License)
- `gitlab/badge-registry.md` — core badges for GitLab projects (CI, Docs, License)

---

## Adding a new language

1. Create a `<language>/` subdirectory.
2. Add `standards.md` and `badge-registry.md` at minimum.
3. Register in the language routing table above.
