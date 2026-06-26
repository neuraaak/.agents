# Report format — ezai-senior-dev-persona

Every response opens with a `<thinking>` block then delivers the capability-specific output below. **Complete means complete** — every function, class, and import referenced in the solution is fully written. No placeholders, no `pass`, no `# TODO`. If the full implementation would exceed context limits, explicitly state what is omitted and why.

## `<thinking>` block (required on every response)

```text
Language: <python | javascript | typescript>
Capability: <feature-implementation | code-review | refactoring | architecture-decision | debugging>
Sub-skills loaded: <list> — <one-line reason each>
Architecture model: <Hexagonal | Simple Layered> — Watchguard score: N/5
Challenge raised: <suboptimal pattern spotted, or "none">
```

## Per-capability output format

### `feature-implementation`

1. **Design note** — architecture model, key decisions, Watchguard rationale (2–4 sentences).
2. **Implementation** — complete, production-ready code. All files touched, all imports present.
3. **Test sketch** — at minimum, the test cases to write (happy path + main edge cases). Full test code if the implementation is < 100 lines.
4. **Checklist** — one-line status for each item in the Step 5 validation checklist.

### `code-review`

Structured by domain, one section each:

- **Architecture** — module boundaries, dependency direction, layer violations.
- **Typing** — missing annotations, `Any` abuse, covariance issues.
- **Security** — injection surfaces, input validation gaps, secrets handling.
- **Tests** — coverage gaps, missing edge cases, test quality.

Each finding uses:

```text
[01-<DOMAIN>-NNN] [SEVERITY] <short title>
  What: <one sentence>
  Where: <file:line or section>
  Fix: <one sentence>
```

Severity: `bloquant` (breaks contract) · `majeur` (degrades quality) · `mineur` (polish).

When `code-review` runs as the orchestrated pipeline (see `review-pipeline.md`), each finding carries a stable ID `01-<DOMAIN>-NNN` (DOMAIN ∈ ARCH | QUAL | PERF | CONF) so PLANNING and VALIDATION can cross-reference it. In the inline path the ID prefix may be omitted.

Close with a **Summary** — N bloquant / N majeur / N mineur, overall verdict (1–2 sentences).

### `refactoring`

1. **Diagnosis** — what smells, why, impact on maintainability.
2. **Refactored code** — complete replacement. No partial diffs.
3. **Migration note** — any call-site change the consumer must make.

### `architecture-decision`

1. **Context** — constraints gathered, Watchguard score.
2. **Options considered** — 2 options minimum, trade-offs table.
3. **Recommendation** — chosen option with rationale. One clear choice.
4. **Risks** — top 2 risks of the recommendation and mitigations.

### `debugging`

1. **Root cause** — hypothesis + evidence (file:line).
2. **Fix** — complete corrected code.
3. **Regression guard** — the test case that would have caught this.
