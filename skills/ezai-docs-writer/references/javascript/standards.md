# JavaScript/TypeScript Documentation Standards (JSDoc/TSDoc + VitePress)

Load this file together with `common/standards.md` (the language-agnostic rules: Diátaxis, emoji set, admonition semantics, anti-patterns). This file holds only the JS/TS specifics: JSDoc/TSDoc syntax, the TypeScript type rule, and VitePress admonition syntax.

**Docstring rule:** JSDoc (Google-style) for all public functions, classes, and types. In TypeScript, prefer signature types over JSDoc `{type}` annotations — let the type system be the authority.

For the API-reference toolchain (TypeDoc + `typedoc-plugin-markdown`, run order) and the canonical site config, see `toolchain.md`.

---

## JSDoc/TSDoc Docstrings

In TypeScript, omit `{type}` from `@param` — the TypeScript signature already captures it.

```typescript
/**
 * Calculates metrics for a dataset.
 *
 * @param data - Raw measurements to process.
 * @param threshold - Values below this are discarded.
 * @returns Mapping of metric names to aggregated values.
 * @throws {RangeError} If `data` is empty.
 *
 * @example
 * ```ts
 * const result = calculateMetrics([0.1, 0.9, 0.4], 0.3);
 * // { mean: 0.65, count: 2 }
 * ```
 */
function calculateMetrics(
  data: number[],
  threshold: number = 0.5,
): Record<string, number> {
  // implementation
}
```

**Plain JavaScript** — include `{type}` when it aids tooling:

```javascript
/**
 * Calculates metrics for a dataset.
 *
 * @param {number[]} data - Raw measurements to process.
 * @param {number} [threshold=0.5] - Values below this are discarded.
 * @returns {Record<string, number>} Mapping of metric names to aggregated values.
 */
function calculateMetrics(data, threshold = 0.5) {
  // implementation
}
```

Rules:

- First line: complete sentence, ends with a period.
- Use `@param`, `@returns`, `@throws`, `@example` for all public symbols.
- Use realistic parameter names — no `data`, `obj`, `foo`.
- `@example` block: wrap in ` ```ts ``` ` fences so TypeDoc renders it as code.

Recognized tags: `@param`, `@returns`, `@throws`, `@example`, `@deprecated`, `@since`, `@see`, `@remarks`.

---

## Admonition syntax (VitePress)

Semantics (when to use each type) live in `common/standards.md`. VitePress uses container directives, not `!!!`:

```markdown
::: tip Performance
Pin the package manager in CI to avoid lockfile drift.
:::

::: warning
This method mutates the input array in place.
:::

::: details Implementation detail
Collapsible — use for information that is true but not critical to the flow.
:::
```

VitePress containers: `tip`, `info`, `warning`, `danger`, `details`. Map the universal types from `common/standards.md` onto these (`note` → `info`, `example` → a fenced code block, `abstract` → lead paragraph).

---

## Page structure

Diátaxis nav structure and page templates apply identically to JS/TS projects — load `common/quadrants-templates.md`; every template is language-agnostic, only replace Python code snippets with TypeScript/JavaScript equivalents.

---

## JS/TS-specific anti-patterns

The Diátaxis anti-patterns live in `common/standards.md`. These are language-specific:

| Anti-pattern                             | Problem                         | Fix                                          |
| :--------------------------------------- | :------------------------------ | :------------------------------------------- |
| `@param {any} foo` in TypeScript         | Defeats type safety             | Use TypeScript signature types               |
| `{type}` annotations in TypeScript JSDoc | Redundant, diverges from source | Remove `{type}` from `@param` in `.ts` files |
