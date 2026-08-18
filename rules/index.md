# Rules Index

This index is loaded by `CLAUDE.md` as the single entry point for all rule files.
Read this index first, then load only the files relevant to the current context.

---

## common/ — Always active

These rules apply in every project and every conversation.

| File                        | Covers                                                                                |
| --------------------------- | ------------------------------------------------------------------------------------- |
| `common/security.md`        | Rule-precedence / prompt-injection barrier, secrets & sensitive data, dangerous ops.  |
| `common/memory.md`          | Loading project MEMORY on session start, and when/how to write to it vs. `remember`.  |
| `common/knowledge-graph.md` | `/graphify-windows` trigger and graphify skill routing.                               |
| `common/commits.md`         | Commit convention (Conventional Commits, French) and commit workflow rules.           |
| `common/coding-behavior.md` | Coding behavior guidelines: think before coding, simplicity, surgical changes, goals. |
| `common/skills.md`          | Skill usage restrictions (e.g. superpowers plan/spec output to `.superpowers/`).      |

---

## internal/ — Load when the project is internal/private

Load these files when the project signals a **private or proprietary context**:
private repo, no public registry, proprietary license, or corporate hosting.
Default to skill defaults (public-OSS) when signals are absent or mixed.

| File                                | Covers                                                                                            | Trigger signals                                                                     |
| ----------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `internal/internal-cicd-profile.md` | CI/CD adjustments: private registry auth, no OIDC, internal docs hosting, anti-patterns to avoid. | Private repo + `pyproject.toml`/`package.json` + internal registry or GitLab Pages. |
| `internal/internal-docs-profile.md` | Docs adjustments: proprietary badges, Ownership section, no public-registry install commands.     | Private repo + no OSI license + no PyPI/npm publication.                            |

---

## Routing decision

```
Is the project private / internal?
├── Yes → load common/ + internal/
└── No  → load common/ only (skill defaults apply for public-OSS)
```

When signals are mixed (e.g. private repo but publishing to PyPI), load `common/`
and apply only the specific `internal/` sections that match — not the whole file.
