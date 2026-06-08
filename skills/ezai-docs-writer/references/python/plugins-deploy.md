# MkDocs — Plugins & Deployment

Load this file when configuring MkDocs (`mkdocs.yml`), wiring plugins, building the API reference, adding version switching, or deploying the docs site.

Stack: **MkDocs + Material + mkdocstrings + mike**, deployed to GitHub Pages via the `gh-pages` branch.

---

## Config file (`mkdocs.yml`)

Set these top-level keys per project — derive each value from the project, never hard-code another project's value:

| Key         | Value to set                                                          |
| :---------- | :-------------------------------------------------------------------- |
| `site_name` | `<Project> Documentation`                                             |
| `site_url`  | `https://<owner>.github.io/<project>/` (Pages URL — required by mike) |
| `repo_url`  | the GitHub/GitLab repository URL                                      |
| `repo_name` | `<owner>/<project>`                                                   |
| `edit_uri`  | `edit/main/docs/` (enables the "edit this page" link)                 |
| `strict`    | `true` — turns build warnings into errors so CI fails on doc rot      |

Under `strict: true`, add a `validation:` block (`omitted_files`, `absolute_links`, `unrecognized_links` set to `warn`) so broken links surface without hard-failing on every edit.

Theme is `material` with both palette schemes (light `default` + dark `slate`) and a toggle. Enable navigation features the site actually uses — at minimum `navigation.indexes` (required by `section-index`, see below), plus `navigation.tabs`, `navigation.sections`, `navigation.top`, `content.code.copy`. Don't enable features the layout doesn't exercise.

---

## Navigation (`nav`)

- Mirror the Diátaxis structure: Home → Getting Started → Guides → Concepts → API Reference → CLI Reference → Examples, then Architecture / Coverage / Changelog as leaf pages.
- **`section-index` rule:** any section that has an `index.md` must list it as the **first child entry** of that section, otherwise the section header isn't clickable.
- Auto-generated pages (`coverage.md`, `changelog.md`, `api/reference/*`) are produced by the build — list them in `nav` but never hand-author them.

---

## API reference (`mkdocstrings`)

`mkdocstrings` renders the API reference from in-source docstrings — the Python analogue of TypeDoc. Configure the `python` handler under `plugins:`:

| Option                                       | Set to                  | Why                                         |
| :------------------------------------------- | :---------------------- | :------------------------------------------ |
| `paths`                                      | `[src]`                 | point at the package root                   |
| `docstring_style`                            | `google`                | match the project's docstring convention    |
| `filters`                                    | `["!^_", "^__init__$"]` | hide privates, but keep `__init__`          |
| `show_root_heading`                          | `true`                  | render a heading for each documented object |
| `merge_init_into_class`                      | `true`                  | fold the constructor into the class entry   |
| `separate_signature` + `signature_crossrefs` | `true`                  | readable, cross-linked signatures           |

Rules:

- `filters` is the controlling knob for visibility — `"!^_"` excludes anything starting with `_`; add `"^__init__$"` back to re-expose constructors. Do not expose other dunders unless the project documents them.
- Set `docstring_style` to whatever the codebase actually uses (`google` / `numpy` / `sphinx`); a mismatch silently drops sections.

---

## Coverage page (`mkdocs-coverage`)

Generates the coverage page from a `coverage.xml` report at build time — never written by hand. Configure `coverage: { page_path: coverage, html_report_dir: htmlcov }` under `plugins:`.

**Run order is mandatory** — the report must exist before the build reads it:

```bash
pytest --cov=src/ --cov-report=html --cov-report=xml -q   # produces coverage.xml + htmlcov/
mkdocs build                                               # coverage plugin consumes them
```

---

## Markdown extensions — ordering rules

Material relies on `pymdownx.*`. The full list is project-stable, but two ordering/config rules are load-bearing:

- **`pymdownx.superfences` must be declared before `pymdownx.highlight`** — the reverse order breaks fenced code rendering.
- **`pymdownx.tabbed` requires `alternate_style: true`** — the legacy style is deprecated and hard-fails under `strict: true`.

`attr_list` + `md_in_html` are required for Material annotations; `pymdownx.details` powers `???` collapsible blocks; `pymdownx.magiclink` auto-links issue/PR refs (set its `user`/`repo`).

---

## Versioning (`mike`)

Use `mike`, not `mkdocs gh-deploy`, for every production deploy. Enable it in `mkdocs.yml` with `extra.version.provider: mike`.

| Command                                                | Effect                              |
| :----------------------------------------------------- | :---------------------------------- |
| `mike deploy --push <version>`                         | publish a version (alias unchanged) |
| `mike deploy --push --update-aliases <version> latest` | publish and move `latest` to it     |
| `mike set-default --push latest`                       | set the root redirect target        |
| `mike list` / `mike delete --push <version>`           | list / remove deployed versions     |

Alias rules:

- `latest` always points at the current **stable** release.
- **Pre-releases publish their version but must not move `latest`** — users tracking `latest` stay on the last stable. Detect pre-release from the version string (`alpha|beta|rc|dev|aN|bN`) and branch the deploy accordingly.
- Numeric tags follow semver; don't invent a `dev`/`main` alias unless pre-release builds are explicitly documented.

---

## CI deployment

The docs deploy job runs on a tag/release (or via `workflow_call` from a release orchestrator), and must:

1. **`checkout` with `fetch-depth: 0`** — mike needs full history to manage the `gh-pages` branch.
2. Install the toolchain pinned (`astral-sh/setup-uv` with the project's Python version) and `uv sync` the `docs` (and `test`, if coverage runs) extras.
3. Produce auto-generated inputs **before** building: run `pytest --cov` (coverage page) and generate the changelog (e.g. `git-cliff` → `docs/changelog.md`). Both must exist before mkdocs/mike reads them.
4. Configure a git identity for the bot, then `mike deploy`, branching on the pre-release flag (see Versioning).

Grant `permissions: contents: write` (mike pushes to `gh-pages`). Pin the runner image (`ubuntu-24.04`) and every action — see the `ezai-cicd-expert` skill for the full release-cascade orchestration (auto-tag → publish → docs).

---

## Anti-patterns

| Anti-pattern                                      | Problem                                 | Fix                                              |
| :------------------------------------------------ | :-------------------------------------- | :----------------------------------------------- |
| `mkdocs gh-deploy` for releases                   | No version switcher, overwrites history | Deploy with `mike`                               |
| Pre-release moves the `latest` alias              | Users pulled onto an unstable build     | Deploy the version only; leave `latest` in place |
| `highlight` declared before `superfences`         | Code blocks render broken               | Order `superfences` first                        |
| Section with `index.md` not first child in `nav`  | Section header isn't clickable          | List `index.md` as the first entry               |
| Hand-editing `coverage.md` / `changelog.md`       | Overwritten on next build               | Generate them in CI before the build step        |
| `docstring_style` mismatched to the codebase      | Docstring sections silently dropped     | Set it to the style the source actually uses     |
| `checkout` without `fetch-depth: 0` in deploy job | mike can't manage `gh-pages`            | Fetch full history                               |
