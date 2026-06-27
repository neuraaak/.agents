# Documentation References Index

Root router. Three reference groups, loaded on demand. All paths below are
written from this `references/` root.

| Need                                                           | Go to                | What lives there                                             |
| :------------------------------------------------------------- | :------------------- | :----------------------------------------------------------- |
| Language-specific docs (docstrings, toolchain, deploy, badges) | `languages/index.md` | per-language routing + "load when" for Python, JS/TS and PHP |
| A badge block (CI/Docs/License shields)                        | `forge/index.md`     | per-forge routing for GitHub and GitLab (badges only)        |
| Cross-cutting, language-agnostic                               | `common/`            | Diátaxis rules, page templates, README rules                 |

## How to route

1. **Detect the language** (`pyproject.toml` → Python, `package.json` → JS/TS, `composer.json` → PHP), then open `languages/index.md` and load the files it lists for the task.
2. **For a badge block**, also detect the forge (GitHub vs GitLab) and open `forge/index.md` — load the **pair**: `forge/<host>/badge-registry.md` + `languages/<lang>/badge-registry.md`.
3. **Always pair the language `standards.md` with `common/standards.md`.** Page templates (`common/quadrants-templates.md`) are language-agnostic.

---

## Common (`common/`)

- `common/standards.md` — language-agnostic doc standards: Diátaxis rules, emoji set, admonition semantics, anti-patterns (always pair with the language `standards.md`)
- `common/quadrants-templates.md` — Diátaxis quadrants & page templates (any language)
- `common/readme.md` — generating a `README.md`

For everything language- or forge-specific, defer to `languages/index.md` and
`forge/index.md`.
