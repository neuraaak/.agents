## Memory — Update Rules

### Two systems, two roles

**Project MEMORY** (`~/.claude/projects/<project>/memory/` + `MEMORY.md`)

- Purpose: durable structural information — architecture, conventions, technical decisions, what has been implemented, next steps / way-to-go.
- When to write: whenever structural info is worth keeping for future sessions.
- How: Write/Edit individual `memory/<file>.md` files, then add a pointer in `MEMORY.md`.

**`remember` skill** (`.remember/` via the skill)

- Purpose: session logs, events, activity traces, less structural notes.
- When to use: only if the `remember` skill is installed (visible in the available skills list). Do not invoke it systematically.
- Scope: current project only.

### Decision table

| Info to retain                       | System                    |
| ------------------------------------ | ------------------------- |
| Architecture, conventions, decisions | Project MEMORY            |
| What was implemented, next step      | Project MEMORY            |
| Session log, one-off event           | `remember` (if installed) |
| Cross-project user preference        | Global auto-memory        |
