## Knowledge Graph — graphify

- **graphify-windows** (`~/.claude/skills/graphify/SKILL.md`) - any input to
  knowledge graph. Trigger: `/graphify-windows`

The skill lives in a `graphify/` folder but registers under the name declared in
its frontmatter, `graphify-windows` — that name is what the Skill tool expects.

When the user types `/graphify-windows` (or asks for graphify), invoke the Skill
tool with `skill: "graphify-windows"` before doing anything else.
