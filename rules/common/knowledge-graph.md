## Knowledge Graph — graphify

- **graphify-windows** — any input (code, docs, papers, images, videos) to
  knowledge graph. Trigger: `/graphify-windows`

The skill lives in a `graphify/` folder but registers under the name declared in
its frontmatter, `graphify-windows` — that name is the one to invoke. On Claude
Code it sits at `~/.claude/skills/graphify/SKILL.md`; other hosts install it in
their own skills directory, and a host without a skill mechanism simply has no
graphify.

When the user types `/graphify-windows` (or asks for graphify), load that skill
before doing anything else.
