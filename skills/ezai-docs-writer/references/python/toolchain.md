# Python Docs Toolchain — Recommended Stack & Canonical `mkdocs.yml`

Load this file when **choosing the documentation tooling** for a Python project, or when **scaffolding `mkdocs.yml` from scratch**. It defines the recommended tool stack and a copy-paste canonical config.

For the operational rules behind these choices — plugin knobs, `mike` versioning, CI deploy, anti-patterns — load `plugins-deploy.md`. This file is the *what to install and what the config looks like*; `plugins-deploy.md` is the *how to run and deploy it*.

---

## Recommended stack

For any Python library, the canonical documentation stack is **MkDocs + Material**. Pick this unless the project already standardized on Sphinx.

| Tool                   | Role                                | Why it is the default                                            |
| :--------------------- | :---------------------------------- | :--------------------------------------------------------------- |
| `mkdocs`               | Static site generator               | Markdown-native, simple `nav`, fast builds                       |
| `mkdocs-material`      | Theme                               | Content tabs, admonitions, annotations, dark mode, search        |
| `mkdocstrings[python]` | API reference from docstrings       | Renders Google-style docstrings — the Python analogue of TypeDoc |
| `mike`                 | Versioned deploys to `gh-pages`     | Version switcher; never overwrite published docs                 |
| `mkdocs-coverage`      | Coverage page from `coverage.xml`   | Surfaces test coverage inside the docs site                      |
| `mkdocs-section-index` | Clickable section landing pages     | Makes section headers route to their `index.md`                  |
| `git-cliff`            | Changelog from Conventional Commits | `docs/changelog.md` is generated, never hand-written             |

Declare these as a `docs` extra (or dependency group) in `pyproject.toml` so CI installs them with `uv sync --extra docs`.

Reach for **Sphinx** only when the project needs reStructuredText, the full `autodoc`/`intersphinx` ecosystem, or PDF/LaTeX output. For everything else, MkDocs + Material is lighter and the Diátaxis templates in `common/quadrants-templates.md` assume it.

---

## Canonical `mkdocs.yml`

Copy this as the baseline. Replace every `<project>` / `<owner>` token — derive each value from the project, never carry over another project's values. Drop theme features and extensions the site does not actually use rather than leaving them dormant.

```yaml
site_name: <Project> Documentation
site_description: <one-line description of the project>
site_author: <owner>
site_url: https://<owner>.github.io/<project>/
repo_url: https://github.com/<owner>/<project>
repo_name: <owner>/<project>
edit_uri: edit/main/docs/

strict: true

validation:
  omitted_files: warn
  absolute_links: warn
  unrecognized_links: warn

theme:
  name: material
  language: en
  palette:
    - scheme: default
      primary: indigo
      accent: indigo
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    - scheme: slate
      primary: indigo
      accent: indigo
      toggle:
        icon: material/brightness-4
        name: Switch to light mode
  features:
    - navigation.tabs
    - navigation.tabs.sticky
    - navigation.sections
    - navigation.path
    - navigation.top
    - navigation.footer
    - navigation.indexes      # required by section-index
    - search.suggest
    - search.highlight
    - search.share
    - content.code.copy
    - content.code.annotate
    - content.tabs.link
    - content.tooltips
    - toc.follow
  icon:
    repo: fontawesome/brands/github
    edit: material/pencil
    view: material/eye
  # logo: assets/logo.png         # Uncomment when docs/assets/logo.png exists
  # favicon: assets/favicon.ico   # Uncomment when docs/assets/favicon.ico exists

nav:
  - Home: index.md
  - Getting Started: getting-started.md
  - User Guides:
      - guides/index.md           # section-index: index.md MUST be first child
      - Configuration: guides/configuration.md
      - Development: guides/development.md
  - API Reference:
      - api/index.md
      - Interfaces: api/interfaces.md   # one page per architecture layer
      - Services: api/services.md
      - Adapters: api/adapters.md
      - Shared: api/shared.md
      - Types: api/types.md
      - Utils: api/utils.md
      - Auto-reference: api/reference/index.md
  - CLI Reference:
      - cli/index.md
  - Examples:
      - examples/index.md
  - Architecture: architecture.md
  - Coverage: coverage.md
  - Changelog: changelog.md

plugins:
  - search
  - section-index
  - coverage:
      page_path: coverage
      html_report_dir: htmlcov
  - mkdocstrings:
      default_handler: python
      handlers:
        python:
          paths: [src]
          options:
            docstring_style: google
            docstring_section_style: table
            show_source: false
            show_root_heading: true
            show_root_full_path: false
            show_symbol_type_heading: true
            show_symbol_type_toc: true
            show_signature_annotations: true
            separate_signature: true
            signature_crossrefs: true
            members_order: source
            group_by_category: true
            merge_init_into_class: true
            filters:
              - "!^_"
              - "^__init__$"

markdown_extensions:
  - admonition
  - pymdownx.details
  - pymdownx.caret
  - pymdownx.tilde
  - pymdownx.critic
  - pymdownx.betterem
  - pymdownx.superfences:        # MUST precede pymdownx.highlight
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:pymdownx.superfences.fence_code_format
  - pymdownx.highlight:
      anchor_linenums: true
      line_spans: __span
      pygments_lang_class: true
  - pymdownx.inlinehilite
  - pymdownx.tabbed:
      alternate_style: true      # required, legacy style hard-fails under strict
  - pymdownx.snippets:
      check_paths: true
      base_path: ['.', 'docs']
  - pymdownx.emoji:
      emoji_index: !!python/name:material.extensions.emoji.twemoji
      emoji_generator: !!python/name:material.extensions.emoji.to_svg
  - pymdownx.magiclink:
      repo_url_shorthand: true
      user: <owner>
      repo: <project>
  - pymdownx.keys
  - pymdownx.mark
  - pymdownx.smartsymbols
  - pymdownx.tasklist:
      custom_checkbox: true
  - abbr
  - attr_list
  - md_in_html
  - def_list
  - footnotes
  - tables
  - toc:
      permalink: true
      permalink_title: Anchor link to this section
      toc_depth: 3

extra:
  version:
    provider: mike
  social:
    - icon: fontawesome/brands/github
      link: https://github.com/<owner>/<project>
      name: GitHub Repository
    - icon: fontawesome/brands/python
      link: https://pypi.org/project/<project>/
      name: PyPI Package

extra_css:
  - stylesheets/extra.css

copyright: >
  Copyright &copy; <year> <owner> -
  <a href="https://github.com/<owner>/<project>/blob/main/LICENSE">MIT License</a>
```

---

## Best practices encoded in this config

These are the load-bearing decisions — keep them when adapting the config.

- **`strict: true` + `validation:` block.** Broken links and orphaned files fail the build (`mkdocs build --strict`), so CI catches doc rot. The `validation` keys downgrade link issues to `warn` so day-to-day edits aren't blocked by a single dead anchor.
- **Both palette schemes with a toggle.** Ship light (`default`) and dark (`slate`) — never a single hard-coded scheme.
- **Enable only features the layout uses.** `navigation.indexes` is mandatory when `section-index` is installed; `content.code.annotate` is mandatory for Material annotations (`(1)!`); `content.tabs.link` syncs content tabs across the page. Don't enable features the pages never exercise.
- **API nav mirrors the architecture layers.** List one `api/<layer>.md` page per architecture layer (interfaces / services / adapters / shared / types / utils), then `api/reference/index.md` as the exhaustive auto-dump. Derive the layers from the project's actual module structure — see `ezai-project-architect` for the layer vocabulary.
- **`section-index` ordering rule.** Any section with an `index.md` must list it as the **first** child, or the section header isn't clickable.
- **Extension ordering is load-bearing.** `pymdownx.superfences` must be declared **before** `pymdownx.highlight`, and `pymdownx.tabbed` needs `alternate_style: true` — both hard-fail under `strict`.
- **`mkdocstrings` reads `src`, Google style, hides privates.** `paths: [src]`, `docstring_style: google`, `filters: ["!^_", "^__init__$"]` (hide privates but keep constructors). A `docstring_style` mismatch silently drops docstring sections.
- **`pymdownx.tasklist` with `custom_checkbox: true`** powers the `- [ ]` quality-gate checklists used in How-To pages.
- **`pymdownx.snippets` with `check_paths: true`** lets pages embed shared files and fails the build if a snippet path is wrong.
- **Mermaid via `superfences` custom fence**, not a separate plugin — diagrams render from ```` ```mermaid ```` blocks.
- **`mike` for versioning** (`extra.version.provider: mike`); never `mkdocs gh-deploy` for releases. See `plugins-deploy.md` for the deploy cascade and alias rules.
- **Auto-generated leaf pages.** `coverage.md`, `changelog.md`, and `api/reference/*` are produced by the build (mkdocs-coverage, git-cliff, mkdocstrings) — list them in `nav` but never hand-author them.
