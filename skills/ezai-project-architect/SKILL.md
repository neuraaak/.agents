---
name: ezai-project-architect
description:
  "Architecture and design standards for Python and JS/TS projects.
  Covers module structure, public API surface, design patterns (Repository,
  Factory, Composition), Hexagonal architecture (Ports & Adapters), and type
  system contracts. Load this sub-skill from ezai-persona-senior-dev, or invoke
  directly when the task is purely about design: defining a class hierarchy,
  structuring a new module, choosing between patterns, or designing a Port interface.

  Triggers on: 'how should I structure this', 'design a repository for', 'what
  pattern fits here', 'create an interface for', 'define the public API of'."
---

Architecture and design standards. Load the language file from the routing table below, then load `references/common/architecture.md` for cross-language principles.

## Language routing

| Language                | File                                    |
| :---------------------- | :-------------------------------------- |
| Python                  | `references/python/architecture.md`     |
| JavaScript / TypeScript | `references/javascript/architecture.md` |

For polyglot repos, load both language files. If the language is not listed, load `references/common/architecture.md` only and state: "No language-specific reference exists for [language]; applying cross-language principles only." If the target file cannot be loaded, notify the user.
