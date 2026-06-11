# Report format — ezai-docs-specialist-persona

Every `.docs-audit/NN-*.md` artifact follows this schema. Keep reports concise — they are working artifacts, not prose documents.

## Header (required)

```text
## [STAGE NAME] — YYYY-MM-DD
Inputs read: <comma-separated list of artifact files or project files>
Artifact produced: .docs-audit/NN-stage-name.md
```

## Severity levels

Used in `01-audit.md` and carried through `04-validation.md`.

| Level | When to use |
| :--- | :--- |
| **bloquant** | Breaks the docs contract: a Diátaxis quadrant entirely absent, `api/index.md` merged with auto-dump, placeholder text shipped in prose, wrong docs tooling detected. |
| **majeur** | Significant scope or coherence break that degrades quality without breaking the contract: a page mixing two Diátaxis quadrants, a stray corporate badge on a personal project, broken internal cross-references. |
| **mineur** | Polish: minor wording issues, a missing optional badge, a heading that could be clearer. |

## Findings section

Each finding uses this structure:

```text
- [SEVERITY] <short title>
  What: <one sentence describing the problem>
  Where: <file path or section>
  Fix: <one sentence describing the expected correction>
  ID: <NN-sequence> (e.g. 01-003 for third finding in audit)
```

The ID is stable across stages: VALIDATION uses the same IDs to report status.

## Status tracking (VALIDATION only — 04-validation.md)

```text
- [ID] <short title> → FIXED | OPEN | REGRESSED
  Note: <optional one-line observation>
```

- **FIXED**: the finding was addressed by GENERATION.
- **OPEN**: the finding was not addressed or the fix was incomplete.
- **REGRESSED**: a finding previously absent or fixed is now present in the current docs tree.
- New findings observed in VALIDATION (not in `01-audit.md`) are out of scope — note them in a separate "Observations" section below the per-finding table.
