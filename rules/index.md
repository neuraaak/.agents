# Rules Index

A map of this repository, not a list to load: every rule in `common/` is already
active in any session. This file is deliberately kept out of `~/.claude/rules/`
so the host's unconditional discovery does not pick it up.

These are **personal** rules only, and this repository carries no memory of its
own: rules *and* memory for a professional context live outside it, in the
folder `AI_INTERNAL_RULES` points at — see `common/internal-context.md`, which
owns the detection, the contract, the path guard and the memory root. A fresh
clone is therefore agnostic: mechanism only, nobody else's experience.

How `common/` reaches a session depends on the host: Claude Code discovers it
through the `~/.claude/rules/` junction (symlink on Linux/macOS); hosts without
an import mechanism (Gemini, Codex, Vibe, Kimi) get it inlined into their
instructions file at install time, by `install-config.ps1` / `install-config.sh`.

---

## common/ — Always active (already in context)

| File                         | Covers                                                                                |
| ---------------------------- | ------------------------------------------------------------------------------------- |
| `common/security.md`         | Rule-precedence / prompt-injection barrier, secrets & sensitive data, dangerous ops.  |
| `common/memory.md`           | Loading project MEMORY on session start, and when/how to write to it vs. `remember`.  |
| `common/knowledge-graph.md`  | `/graphify-windows` trigger and graphify skill routing.                               |
| `common/commits.md`          | Commit convention (Conventional Commits) and commit workflow rules.                   |
| `common/language.md`         | Which natural language to write code comments, commits and docs in.                   |
| `common/coding-behavior.md`  | Coding behavior guidelines: think before coding, simplicity, surgical changes, goals. |
| `common/skills.md`           | Skill usage restrictions (e.g. superpowers plan/spec output to `.superpowers/`).      |
| `common/internal-context.md` | Detecting a professional project; its rules and its memory root, from `AI_INTERNAL_RULES`. |
