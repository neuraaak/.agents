---
name: ezai-project-architect
description: >
  Architecture and design standards for Python and JS/TS projects.
  Covers: modular structure, public API surface, design patterns
  (Repository, Factory, Composition), Hexagonal architecture (Ports & Adapters),
  Value Objects, and type-system contracts.

  Load from ezai-senior-dev-persona or directly for any design task.

  Triggers on: "how should I structure this", "design a repository for",
  "what pattern fits here", "create an interface for", "define the public API of",
  "hexagonal architecture", "ports and adapters", "should I use hexagonal",
  "structure this module", "which pattern", "design a class", "architecture".
---

Architecture and design standards. Follows a 3-step workflow: identify the project language and complexity, load the matching language file, then apply the patterns with complete code.

## Local rules precedence

Any rule declared in the user's `.claude/` (rules files, CLAUDE.md) takes
precedence over this skill. When a local rule covers the same domain, apply it
**in addition and in priority** over the defaults described here. This skill
ships only the general default; context-specific overrides live in the user's
rules.

## Capabilities

| Key                                   | Description                                                           |
| :------------------------------------ | :-------------------------------------------------------------------- |
| `feature-based-module-structure`      | Organize or refactor a project into feature-based modules             |
| `public-api-surface`                  | Define what is public vs internal in a module                         |
| `repository-pattern`                  | Abstract all data access behind a repository interface                |
| `hexagonal-architecture`              | Apply Ports & Adapters for projects with multiple external boundaries |
| `value-objects`                       | Encapsulate primitives with strong domain semantics                   |
| `architecture-decision-watchguard`    | Evaluate Hexagonal vs Simple Layered before choosing an architecture  |
| `type-system-contracts`               | Protocols (Python), interfaces (TS), branded types                    |
| `design-patterns-factory-composition` | Apply Factory and Composition patterns with full code output          |

## Workflow

1. **Identify** — language(s) + project complexity (apply the Watchguard — see `references/common/architecture.md`)
2. **Load** — the language file below + `references/common/architecture.md` (cross-cutting principles)
3. **Apply** — propose the design with complete code + success criteria

## Language routing

| Language                | File                                              |
| :---------------------- | :------------------------------------------------ |
| Python                  | `references/languages/python/architecture.md`     |
| JavaScript / TypeScript | `references/languages/javascript/architecture.md` |

For polyglot repos, load both files. If the language is not listed, load `references/common/architecture.md` only and tell the user.

## Output format

- **Architecture choice**: apply the Watchguard before proposing Hexagonal
- **Code**: complete example per layer (Domain / Application / Infrastructure)
- **File structure**: annotated `src/` tree
- **Success criteria**: verifiable checklist at the end of the response
