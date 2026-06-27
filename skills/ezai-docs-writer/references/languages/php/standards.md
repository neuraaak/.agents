# PHP Documentation Standards (PHPDoc + phpDocumentor/Doctum)

Load this file together with `common/standards.md` (the language-agnostic rules: Diátaxis, emoji set, admonition semantics, anti-patterns). This file holds only the PHP specifics: PHPDoc tag syntax, the PHP 8 attribute rule, and where prose admonitions come from.

**Docstring rule:** PHPDoc blocks (`/** … */`) on every public class, method, function, and property. Omit `@param`/`@return` types only when the native PHP type declaration already states them and the doc adds nothing — otherwise PHPDoc is the carrier of the documentation prose, not just the type.

For the API-reference toolchain (phpDocumentor / Doctum) and the canonical site config, see `toolchain.md`.

---

## PHPDoc Blocks

In modern PHP (8.1+) the signature carries the types; the PHPDoc block carries the *description* and any types the language can't express (generics, array shapes).

```php
/**
 * Filters and aggregates measurement data.
 *
 * @param list<float> $data      Raw measurements to process.
 * @param float       $threshold Values below this are discarded.
 *
 * @return array<string, float> Mapping of metric names to aggregated values.
 *
 * @throws \InvalidArgumentException If `$data` is empty.
 */
public function process(array $data, float $threshold = 0.5): array
{
    // implementation
}
```

Rules:

- First line: complete sentence, ends with a period, on its own line.
- Use `@param`, `@return`, `@throws` for all public symbols; add `@deprecated`, `@since`, `@see` where relevant.
- **Add types to `@param`/`@return` only when they refine the native type** — generics (`list<float>`), array shapes (`array{id: int, name: string}`), or union narrowing. Redundant `@param int $x` on an already-`int`-typed parameter is noise; drop it.
- Use realistic domain names for variables — no `$data`, `$obj`, `$foo`.
- PHP 8 **attributes** (`#[Route(...)]`) are not PHPDoc and are not rendered as documentation — keep behavioural metadata in attributes, human documentation in the PHPDoc block.

Recognized tags (phpDocumentor + Doctum): `@param`, `@return`, `@throws`, `@var`, `@deprecated`, `@since`, `@see`, `@link`, `@internal`, `@api`. Mark the supported public surface with `@api` and hide internals with `@internal` so the generated reference reflects the real contract.

---

## Admonition syntax (prose layer)

phpDocumentor and Doctum render the **API reference only** (HTML from PHPDoc) — they have no prose/admonition system. Guides, tutorials, and explanations live in the **prose tool** (VitePress or MkDocs Material — see `toolchain.md`), so admonition syntax follows that tool:

- **VitePress prose** → container directives (`::: tip`, `::: warning`, `::: details`). See `languages/javascript/standards.md` for the full syntax.
- **MkDocs Material prose** → `!!! tip` / `??? note` blocks. See `languages/python/standards.md` for the full syntax.

Inside PHPDoc blocks themselves, use plain prose and `@see`/`@link` cross-references — neither generator interprets Markdown admonitions in docblocks.

---

## PHP-specific success criteria

- The API reference is generated from PHPDoc blocks via phpDocumentor or Doctum — never hand-authored.
- `@api` / `@internal` tags are present so the generated reference exposes the public surface and hides internals.
- Prose pages (guides, tutorials) live in the prose tool, cross-linked to the generated API pages.
