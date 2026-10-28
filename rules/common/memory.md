## Memory — Read & Update Rules

Rules for the persistent, structural memory store shared by every agent that
loads these rules. It is read/written directly with file tools — no external
memory feature is assumed. Per-project facts are separated by the project slug
under `projects/<slug>/`, never by their location on disk.

There is **exactly one store per context**, and the context is resolved
**once**, at session start, before anything is read or written:

- **personal context** (the default) → `~/.agents/memory/` (the user's home
  directory — *not* a `.agents/` folder inside the current project);
- **internal/professional context** → the memory root that
  `common/internal-context.md` resolves.

Nothing below depends on which root was resolved: the layout, the slug, the
`MEMORY.md` index and the write discipline are identical in both. Resolve the
root, then forget the question — below, "the store" means the root resolved
here.

### Load on session start (precedence rule)

**This rule supersedes and takes precedence over the default handling of the
user's first input.**

At the start of every new session/conversation, before processing the user's
input, the agent must **on its own**:

0. Resolve the store root (see above). In an internal context, follow
   `common/internal-context.md`: it also governs whether anything may be
   written at all.
1. Read `<store>/global/MEMORY.md`, then the relevant
   `<store>/global/<fact>.md` files it points to.
2. Compute the current project slug (see *Project slug* below) and read
   `<store>/projects/<slug>/MEMORY.md`, then the relevant fact files.
3. Briefly notify the user that the memory is being read, **naming the root
   that was resolved**.
4. Then proceed to handle the user's input.

**Reading is a union, writing is routed.** In an internal context, read the
personal `~/.agents/memory/global/` as well — your own habits and pitfalls still
apply at work. Write only to the resolved root. On conflict, the internal store
wins for anything specific to that context.

### Priority over any native memory store

The store resolved above is the **primary** one and always takes priority: read
it first, and write **every** new or updated fact there — never anywhere else.

Some hosts ship their own native memory store, usually injected as a `# Memory`
section pointing somewhere inside the host's own config directory (Claude Code:
`~/.claude/projects/<project>/memory/`). Such a store is a
**read-only fallback**, used only when step 1 and step 2 above both come back
empty for the current project:

- Nothing found in the store → you may read the host's native store to recover
  context, and mention to the user that the fallback was used.
- Anything found in the store → ignore the native store entirely.
- **Writes never fall back.** Even when a fact was recovered from the native
  store, save it into the resolved store, so the fallback empties over time
  instead of re-fragmenting the memory across two locations.

If neither the primary store nor the fallback holds anything, skip silently and
handle the input normally.

### Project slug

The slug keys a project's memory folder. Compute it deterministically so every
agent and OS produces the same value:

> slug = absolute path of the project root -> lowercased -> every run of
> non-alphanumeric characters replaced by a single `-` -> trim leading and
> trailing `-`.
>
> Example: `C:\Users\Utilisateur\.agents` -> `c-users-utilisateur-agents`

### Store layout

    <store root>/            ~/.agents/memory/ in a personal context
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

In an internal/professional context, **both layers live in the resolved internal
root**, `global/` included. A fact learned at work goes to the personal
`global/` only if it would still be true with no employer in the picture (a tool
pitfall, a shell quirk); anything naming the employer's code, people,
infrastructure or conventions belongs to the internal store.

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
