# Review pipeline — ezai-senior-dev-persona

Loaded by the orchestrator **only** when the active capability is `code-review`.
For every other capability use `references/pipeline.md` (inline workflow) — this
file does not apply. Load `references/report-format.md` before this file: the
domain subagents reuse its `code-review` finding format.

The orchestrator owns no domain knowledge. All expertise lives in the project
sub-skills (`ezai-project-architect`, `ezai-project-quality`,
`ezai-project-performance`, `ezai-project-config`). The orchestrator dispatches,
consolidates, gates, and loops.

## Artifact contract

All artifacts live in `.senior-review/` at the root of the reviewed project.
Names are fixed — every stage knows where to read and write. Ensure
`.senior-review/` is gitignored in the reviewed repo (add it to `.gitignore` if
absent).

```text
.senior-review/
  00-context.md     written by DETECTION,   read by REVIEW + PLANNING + APPLY
  01-review.md      written by REVIEW,       read by PLANNING + VALIDATION
  02-plan.md        written by PLANNING,     read by APPLY
  03-changes.md     written by APPLY,        read by VALIDATION
  04-validation.md  written by VALIDATION,   presented to user
```

Finding IDs are stable across stages: `01-<DOMAIN>-NNN` where DOMAIN ∈
`ARCH | QUAL | PERF | CONF`. PLANNING and VALIDATION cross-reference by this ID.

---

## Stage 0 — DETECTION

**Who:** Dedicated subagent (read-only).
**Inputs:** Reviewed code scope (target files/modules), `pyproject.toml`,
`package.json`, file extensions.
**Output:** `.senior-review/00-context.md`

### Role

1. **Language** — Python or JavaScript/TypeScript, from `pyproject.toml` /
   `package.json` / extensions.
2. **Review scope** — the exact files/modules under review.
3. **Domain selection** — pick the relevant domains among `architect`,
   `quality`, `performance`, `config`. Do **not** launch all four by reflex: a
   domain that does not apply must be listed as `skipped` with a one-line
   reason (e.g. no async/concurrent code ⇒ skip `performance`).

If the artifact is empty or malformed (missing required fields), stop and tell
the user which fields are absent — do not proceed to REVIEW with incomplete
context.

### 00-context.md schema

```markdown
## DETECTION — YYYY-MM-DD
Inputs read: <files/scope read>
Artifact produced: .senior-review/00-context.md

- language: python | javascript | typescript
- review-scope: <files/modules under review>
- domains:
    - architect:   selected (reason: …) | skipped (reason: …)
    - quality:     selected (reason: …) | skipped (reason: …)
    - performance: selected (reason: …) | skipped (reason: …)
    - config:      selected (reason: …) | skipped (reason: …)
```

---

## Stage 1 — REVIEW *(load `report-format.md` before starting)*

**Who:** One dedicated subagent per selected domain (read-only), dispatched
**in series** (one at a time).
**Inputs:** `00-context.md` + the reviewed code + the domain's project
sub-skill (loaded by the subagent via the Skill tool).
**Output:** each subagent appends **its own section** to
`.senior-review/01-review.md`.

Domain → sub-skill mapping:

| Domain (ID) | Sub-skill to load          |
| :---------- | :------------------------- |
| ARCH        | `ezai-project-architect`   |
| QUAL        | `ezai-project-quality`     |
| PERF        | `ezai-project-performance` |
| CONF        | `ezai-project-config`      |

Each finding uses the `code-review` format from `report-format.md`, with a
stable ID:

```text
[01-<DOMAIN>-NNN] [SEVERITY] <short title>
  What:  <one sentence>
  Where: <file:line>
  Fix:   <one sentence>
```

Severity: `bloquant` (breaks contract) · `majeur` (degrades quality) ·
`mineur` (polish).

### 01-review.md schema

```markdown
## REVIEW — YYYY-MM-DD
Inputs read: 00-context.md, <reviewed code>
Artifact produced: .senior-review/01-review.md

### Architecture (ARCH)
[01-ARCH-001] [majeur] …
  What: …
  Where: …
  Fix: …

### Quality (QUAL)
[01-QUAL-001] [bloquant] …
  …

### Performance (PERF)
<section present only if domain selected>

### Config (CONF)
<section present only if domain selected>
```

---

## Stage 2 — PLANNING *(load `report-format.md` before starting)*

**Who:** Main orchestrator, entering plan mode.
**Inputs:** `00-context.md` + `01-review.md`.
**Output:** `.senior-review/02-plan.md`.

The orchestrator consolidates every domain finding into one prioritized fix plan
(bloquant → majeur → mineur), presents it to the user, and **waits for
approval**. This is the human gate — no patch runs before approval.

### 02-plan.md schema

```markdown
## PLANNING — YYYY-MM-DD
Inputs read: 00-context.md, 01-review.md
Artifact produced: .senior-review/02-plan.md

### TODOs — bloquant
- [ ] [01-<DOMAIN>-NNN] <short title> — <file> — <one-line action>
### TODOs — majeur
- [ ] [01-<DOMAIN>-NNN] <short title> — <file> — <one-line action>
### TODOs — mineur
- [ ] [01-<DOMAIN>-NNN] <short title> — <file> — <one-line action>
```

Each TODO carries the finding ID so VALIDATION can cross-reference.

---

## Stage 3 — APPLY

**Who:** A **single** dedicated subagent (write).
**Inputs:** `00-context.md` + `02-plan.md`.
**Output:** real file patches + `.senior-review/03-changes.md`.

The APPLY subagent executes the approved plan **in series, file by file**. It
loads inline whichever project sub-skills the fixes require, to respect the
standards. A single agent ⇒ no write collisions.

Degraded mode: if a fix fails or cannot be applied, mark it `SKIPPED` /
`FAILED` and add it to a top-level `## Blockers` section, then continue with the
remaining TODOs. This lets VALIDATION distinguish "not fixed because skipped"
from "fix failed".

### 03-changes.md schema

```markdown
## APPLY — YYYY-MM-DD
Inputs read: 00-context.md, 02-plan.md
Artifact produced: .senior-review/03-changes.md

- [01-<DOMAIN>-NNN] <short title> → DONE | SKIPPED | FAILED
  File: <path>
  Why: <one-line rationale if non-obvious>

## Blockers
- [01-<DOMAIN>-NNN] <short title> — <reason skipped/failed>
```

---

## Stage 4 — VALIDATION

**Who:** Dedicated subagent (read-only).
**Inputs:** `01-review.md` + `03-changes.md` + updated code.
**Output:** `.senior-review/04-validation.md`.

Re-reads the code and cross-references every finding from `01-review.md` (by ID)
against `03-changes.md`. Status: `FIXED` | `OPEN` | `REGRESSED`.

### 04-validation.md schema

```markdown
## VALIDATION — YYYY-MM-DD
Inputs read: 01-review.md, 03-changes.md, code
Artifact produced: .senior-review/04-validation.md

### Summary
- Fixed: N
- Open: N
- Regressed: N

### Per-finding status
- [01-<DOMAIN>-NNN] <short title> → FIXED | OPEN | REGRESSED
  Note: <optional one-line observation>
```

---

## Bounded re-loop

If `04-validation.md` contains `OPEN` or `REGRESSED` findings, the orchestrator
surfaces the summary to the user — count of OPEN/REGRESSED, the IDs and titles,
and a one-line diagnosis each — then offers **one** re-loop back to PLANNING.
Present it as: « Voulez-vous corriger ces N points restants, ou considérer la
revue terminée ? » The user decides — no automatic second loop.
