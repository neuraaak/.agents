## Memory — Read & Update Rules

### Load on session start (precedence rule)

**This rule supersedes and takes precedence over the default handling of the
user's first input.**

At the start of every new session/conversation, before processing the user's
input, Claude must **on its own** load the project MEMORY if one exists
(`~/.claude/projects/<project>/memory/` + `MEMORY.md`):

1. Check for an existing project MEMORY.
2. If present, read it (start with `MEMORY.md`, then the relevant
   `memory/<file>.md` files).
3. Briefly notify the user that the project memory is being read.
4. Then proceed to handle the user's input.

If no project MEMORY exists, skip silently and handle the input normally.

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
