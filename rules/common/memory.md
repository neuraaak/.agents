## Memory — Read & Update Rules

Rules for the persistent, structural memory store shared by every agent that
loads these rules. The store lives at `.agents/memory/` in this repository and
is read/written directly with file tools — no external memory feature is assumed.

### Load on session start (precedence rule)

**This rule supersedes and takes precedence over the default handling of the
user's first input.**

At the start of every new session/conversation, before processing the user's
input, the agent must **on its own**:

1. Read `.agents/memory/global/MEMORY.md`, then the relevant
   `.agents/memory/global/<fact>.md` files it points to.
2. Compute the current project slug (see *Project slug* below) and read
   `.agents/memory/projects/<slug>/MEMORY.md`, then the relevant fact files.
3. Briefly notify the user that the memory is being read.
4. Then proceed to handle the user's input.

If neither layer exists yet, skip silently and handle the input normally.

### Project slug

The slug keys a project's memory folder. Compute it deterministically so every
agent and OS produces the same value:

> slug = absolute path of the project root -> lowercased -> every run of
> non-alphanumeric characters replaced by a single `-` -> trim leading and
> trailing `-`.
>
> Example: `C:\Users\Utilisateur\.agents` -> `c-users-utilisateur-agents`

### Store layout

    .agents/memory/
    |-- global/
    |   |-- MEMORY.md        index of the global layer
    |   +-- <fact>.md
    +-- projects/
        +-- <slug>/
            |-- MEMORY.md    index of the project layer
            +-- <fact>.md

### Fact file format

One fact per file, with frontmatter:

    ---
    name: <kebab-case-slug>
    description: <one-line summary — used to judge relevance at recall>
    metadata:
      type: user | feedback | project | reference
    ---

    <the fact. For feedback/project, follow with **Why:** and **How to apply:**
    lines. Link related facts with [[other-name]].>

**Types:** `user` (who the user is: role, expertise, preferences);
`feedback` (guidance on how to work, with the why); `project` (ongoing work,
goals, constraints not derivable from the code); `reference` (external pointers:
URLs, dashboards, tickets).

### MEMORY.md index

One index per layer (`global/` and each `projects/<slug>/`). One line per fact,
never any fact content inside it:

    - [Title](file.md) — hook

### Where each fact goes

| Info to retain                                          | Location                  |
| ------------------------------------------------------- | ------------------------- |
| `user`; transverse `feedback`; transverse `reference`   | `global/`                 |
| `project`; anything specific to the current repo        | `projects/<slug>/`        |
| Session log, one-off event, activity trace              | `remember` (if installed) |

### Write discipline

- Before saving, check for an existing file already covering the fact — update
  it rather than creating a duplicate. Delete a memory that turns out wrong.
- Write the fact file, then add its one-line pointer to the correct layer's
  `MEMORY.md`. Create the folder and index if they do not exist.
- Do not memorize what the repo or git already records (code structure, past
  fixes, history). Never store secrets (see `security.md`).

### Session-log companion

A session-log tool (`.remember/`), if installed and visible in the available
skills list, covers session logs, events, and activity traces — not structural
memory. Use it only when installed; do not invoke it systematically. Scope:
current project only.
