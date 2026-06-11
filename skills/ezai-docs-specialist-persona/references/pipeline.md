# Pipeline — ezai-docs-specialist-persona

This file is loaded by the orchestrator when the pipeline starts. It defines the role, inputs, outputs, and artifact contract for each stage. Load `references/report-format.md` before reading this file.

## Artifact contract

All artifacts live in `.docs-audit/` at the root of the audited project. Names are fixed — every stage knows exactly where to read and write.

```text
.docs-audit/
  00-context.md     written by DETECTION, read by AUDIT + PLANNING + GENERATION
  01-audit.md       written by AUDIT, read by PLANNING + VALIDATION
  02-plan.md        written by PLANNING (main agent), read by GENERATION
  03-changes.md     written by GENERATION, read by VALIDATION
  04-validation.md  written by VALIDATION, presented to user
```

---

## Stage 0 — DETECTION

**Who:** Dedicated subagent (read-only).
**Inputs:** Project root — file extensions, `pyproject.toml`, `package.json`, `mkdocs.yml`, `docs/.vitepress/config.*`, `.github/`, `.gitlab-ci.yml`.
**Output:** `.docs-audit/00-context.md`

### Questions to answer

1. **Language** — Python or JavaScript/TypeScript? Detected from `pyproject.toml` / `package.json`.
2. **Docs tooling** — MkDocs / VitePress / Sphinx / none? Detected from config file presence.
3. **Versioning platform** — GitHub or GitLab? Detected from `.github/` or `.gitlab-ci.yml`.
4. **Profile** — `public-oss` or `internal`? Inferred from repo signals: public OSS license (`LICENSE` with MIT/Apache/etc.), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` → `public-oss`; private repo, no public registry, proprietary/absent license, corporate badge patterns → `internal`. Default to `public-oss` if ambiguous.
5. **ezai-docs-writer reference files to load** — the exact list of files from `ezai-docs-writer/references/` that AUDIT and GENERATION must load for this project. Start at `ezai-docs-writer/references/index.md`, then follow it into `languages/index.md` (per-language files) and `forge/index.md` (badge registries).

### 00-context.md schema

```markdown
## DETECTION — YYYY-MM-DD
Inputs read: pyproject.toml, package.json, mkdocs.yml, docs/.vitepress/config.*, .github/, .gitlab-ci.yml
Artifact produced: .docs-audit/00-context.md

- language: python | javascript
- docs-tooling: mkdocs | vitepress | sphinx | none
- platform: github | gitlab
- profile: public-oss | internal
- docs-writer-refs:
    - references/common/standards.md
    - references/languages/<lang>/standards.md
    - references/forge/<platform>/badge-registry.md
    - references/languages/<lang>/badge-registry.md
    - <add others if audit or generation needs them>
```

---

## Stage 1 — AUDIT *(load `report-format.md` before starting)*

**Who:** Dedicated subagent (read-only).
**Inputs:** `.docs-audit/00-context.md` + the `ezai-docs-writer` reference files listed in `docs-writer-refs` + full `docs/` tree.
**Output:** `.docs-audit/01-audit.md`

The AUDIT stage merges what would otherwise be two separate passes (Diátaxis structure + contextual coherence) into one single read of the docs tree. Two sections, one subagent, one cold-start.

### Section A — Diátaxis structure

Load `ezai-docs-writer/references/common/quadrants-templates.md`.

- List the actual `docs/` tree.
- Diff against the canonical Diátaxis layout (Tutorial, How-To, Reference, Explanation, Examples, Changelog).
- Flag: absent quadrant sections, pages that mix two quadrants, `api/index.md` merged with auto-dump.
- Classify each finding with a severity level (see `report-format.md`).

### Section B — Contextual coherence

Use `00-context.md` (language, platform, profile) as the control.

- Load the platform + language `badge-registry.md` pair.
- Check: badges present and correct for this platform/language/environment, no placeholder text (`<your-project>`, `TODO`, `FIXME`, `TBD`), no stray mentions from a different project or template.
- For `public-oss` profile: corporate-only badges (org logo, enterprise shields) are **bloquant**; their absence is not a finding.
- Classify each finding with a severity level.

---

## Stage 2 — PLANNING *(load `report-format.md` before starting)*

**Who:** Main orchestrator agent, entering plan mode.
**Inputs:** `.docs-audit/00-context.md` + `.docs-audit/01-audit.md`
**Output:** `.docs-audit/02-plan.md`

The main agent reads both artifacts, drafts a prioritized upgrade plan (bloquant first, then majeur, then mineur), and presents it to the user. **This is the human gate — no patch runs until the user approves.**

### 02-plan.md schema

```markdown
## PLANNING — YYYY-MM-DD
Inputs read: 00-context.md, 01-audit.md
Artifact produced: .docs-audit/02-plan.md

### TODOs — bloquant
# [01-ID] = finding ID from 01-audit.md (e.g. 01-003)
- [ ] [01-ID] <short title> — <file to create or modify> — <one-line action>

### TODOs — majeur
- [ ] [01-ID] <short title> — <file to create or modify> — <one-line action>

### TODOs — mineur
- [ ] [01-ID] <short title> — <file to create or modify> — <one-line action>
```

Each TODO carries the finding ID from `01-audit.md` so VALIDATION can cross-reference.

---

## Stage 3 — GENERATION

**Who:** Dedicated subagent (write).
**Inputs:** `.docs-audit/00-context.md` + `.docs-audit/02-plan.md`
**Output:** Real file patches + `.docs-audit/03-changes.md`

The GENERATION subagent reads the approved plan and executes it file by file. For each TODO it **invokes `ezai-docs-writer`** via the Skill tool to produce or correct the target file. It does not write documentation content itself.

If `ezai-docs-writer` is unavailable, GENERATION must:

1. Mark the TODO as `SKIPPED (ezai-docs-writer unavailable)` in `03-changes.md`.
2. Add a top-level `## Blockers` section in `03-changes.md` listing each skipped TODO with its finding ID.
3. Continue with the remaining TODOs that don't require docs-writer.

This ensures VALIDATION can distinguish "not fixed because skipped" from "not fixed because the fix failed".

### 03-changes.md schema

```markdown
## GENERATION — YYYY-MM-DD
Inputs read: 00-context.md, 02-plan.md
Artifact produced: .docs-audit/03-changes.md

- [01-ID] <short title> → DONE | SKIPPED
  File: <path modified or created>
  Why: <one-line rationale if non-obvious>
```

---

## Stage 4 — VALIDATION

**Who:** Dedicated subagent (read-only).
**Inputs:** `.docs-audit/01-audit.md` + `.docs-audit/03-changes.md` + updated `docs/` tree.
**Output:** `.docs-audit/04-validation.md`

The VALIDATION subagent re-reads the docs tree and cross-references every finding from `01-audit.md` against the changes recorded in `03-changes.md`. It reports the status of each finding by its stable ID.

### 04-validation.md schema

```markdown
## VALIDATION — YYYY-MM-DD
Inputs read: 01-audit.md, 03-changes.md, docs/ tree
Artifact produced: .docs-audit/04-validation.md

### Summary
- Fixed: N
- Open: N
- Regressed: N

### Per-finding status
- [01-ID] <short title> → FIXED | OPEN | REGRESSED
  Note: <optional one-line observation>
```

---

## Bounded re-loop

If `04-validation.md` contains findings with status OPEN or REGRESSED, the orchestrator surfaces the summary to the user and offers **one** re-loop back to PLANNING (stage 2). The user decides: re-patch or close. No automatic second loop.
