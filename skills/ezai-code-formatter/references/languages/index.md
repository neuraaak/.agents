# Code Formatter — Languages Index

Route to the correct language subdirectory based on the file extension.

## Supported languages

| Language                | Extensions                       | File                                                |
| :---------------------- | :------------------------------- | :-------------------------------------------------- |
| Python                  | `.py`                            | `languages/python/style-layout.instructions.md`     |
| JavaScript / TypeScript | `.js` `.ts` `.jsx` `.tsx` `.mjs` | `languages/javascript/style-layout.instructions.md` |

## What each file owns

- **`python/style-layout.instructions.md`** — section markers (`# ///...` main, `# ---...` sub), import grouping, class structure, Google-style docstrings.
- **`javascript/style-layout.instructions.md`** — section markers (`// ///...` main, `// ---...` sub), import grouping (node:, 3rd-party, local), JSDoc format.

## Adding a new language

1. Create `<language>/` here.
2. Add `style-layout.instructions.md` covering: section separators, import grouping, docstring/comment style.
3. Register in the table above and in `references/index.md`.
