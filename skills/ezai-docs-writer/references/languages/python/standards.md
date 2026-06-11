# Python Documentation Standards (Google-style + MkDocs)

Load this file together with `common/standards.md` (the language-agnostic rules: Diátaxis, emoji set, admonition semantics, anti-patterns). This file holds only the Python/MkDocs specifics: Google-style docstring syntax, MkDocs admonition and annotation syntax, and mkdocstrings behaviour.

**Docstring rule:** Google-style exclusively; omit types in the docstring body — mkdocstrings pulls them from the signature.

---

## Google-Style Docstrings

```python
def process(data: list[float], threshold: float = 0.5) -> dict[str, float]:
    """Filters and aggregates measurement data.

    Args:
        data: Raw measurements to process.
        threshold: Values below this are discarded.

    Returns:
        Mapping of metric names to aggregated values.

    Raises:
        ValueError: If `data` is empty.

    Example:
        >>> process([0.1, 0.9, 0.4], threshold=0.3)
        {'mean': 0.65, 'count': 2}
    """
```

Rules:

- First line: complete sentence, ends with period, one line.
- Use `Args`, `Returns`, `Raises`, and `Example` sections for all public symbols.
- Omit types in docstring body — mkdocstrings pulls them from the signature.
- Use realistic domain names for variables (no `data`, `obj`, `foo`).

Recognized section headers (case-insensitive): `Args`, `Returns`, `Raises`, `Example`, `Note`, `Warning`, `Tip`, `See also`.
`Note:` / `Warning:` / `Tip:` sections render as MkDocs Material admonitions automatically.

---

## Admonition syntax (MkDocs Material)

Semantics (when to use each type) live in `common/standards.md`. MkDocs Material syntax:

```markdown
!!! tip "Performance"
    Use `uv sync --frozen` in CI to avoid re-solving the lockfile.

!!! warning
    This method mutates the input list in place.

??? note "Implementation detail"
    Collapsible — use for information that is true but not critical to the flow.
```

---

## Material Annotations

Annotations render numbered markers `(1)` as inline popovers. Distinct from admonitions. MkDocs-only — no VitePress equivalent.

**Required extensions** (in `mkdocs.yml`):

```yaml
markdown_extensions:
  - attr_list
  - md_in_html
```

**Syntax — inline text:**

```markdown
This is a paragraph with an annotation. (1)
{ .annotate }

1. This is the annotation content — rendered as a popover.
```

**Syntax — code block:**

````markdown
```python { .annotate }
def process(data):
    return sorted(data)  # (1)!
```

1. `sorted()` returns a new list — it does not mutate `data`.
````

The `!` suffix on `(1)!` strips the comment from the rendered output.

When to use: Reference pages (annotate specific lines) and How-To pages (explain a step inline).
Never inside docstrings — mkdocstrings does not interpret Material annotations.

---

## Python-specific success criteria

- Reference pages are generated from Google-style docstrings via mkdocstrings.
- `api/index.md` is a human-curated navigation index; `api/reference/index.md` is the full mkdocstrings dump.
