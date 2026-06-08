---
name: ezai-project-quality
description:
  "Testing, security, and input validation standards for Python and
  JS/TS projects. Covers test architecture (pytest / node:test / Vitest),
  property-based testing (hypothesis / fast-check), input validation at I/O
  boundaries (Pydantic / Zod), secret management, and production hardening.
  Load from ezai-persona-senior-dev, or invoke directly for quality-specific tasks.

  Triggers on: 'write tests for', 'add validation for', 'security review',
  'harden this', 'how should I test', 'is this input sanitized'."
---

Testing, security, and quality standards. Load the language file from the routing table below, then load `references/common/quality.md` for cross-language principles.

## Language routing

| Language                | File                               |
| :---------------------- | :--------------------------------- |
| Python                  | `references/python/quality.md`     |
| JavaScript / TypeScript | `references/javascript/quality.md` |

For mixed repos, load both language files and apply each to its respective files. If a file cannot be read, notify the user and fall back to `references/common/quality.md`.
