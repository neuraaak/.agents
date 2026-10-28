# .agents

One set of personal instructions for every AI coding agent. The rules are
written once in `rules/common/`, and an installer distributes them to each
provider's own instructions file.

Two distribution mechanisms, because providers differ:

| Provider     | Target file                                           | How rules get there                                                                 |
| ------------ | ----------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Claude Code  | `~/.claude/CLAUDE.md`                                 | `~/.claude/rules/` links to `rules/common/`, which Claude Code discovers on its own |
| Gemini CLI   | `~/.gemini/GEMINI.md`                                 | inlined at install time                                                             |
| Codex        | `~/.codex/AGENTS.md`                                  | inlined at install time                                                             |
| Mistral Vibe | `~/.vibe/AGENTS.md`                                   | inlined at install time                                                             |
| Kimi Code    | `$KIMI_CODE_HOME/AGENTS.md` (default `~/.kimi-code/`) | inlined at install time                                                             |

Only Claude Code has a usable import mechanism. For the others the rule text
is copied into the generated file, so **editing a rule means re-running the
installer**. For Claude Code an edit is live, no regeneration needed.

## Install

Windows:

    install-config.cmd --claude --gemini --codex --vibe --kimi

Linux, macOS, WSL:

    ./install-config.sh --claude --gemini --codex --vibe --kimi

Pick only the providers you use; with no option at all, `--claude` is assumed.
Both scripts take the same options and are idempotent — run them again after
editing a rule or a template.

## Check an installation

    install-config.cmd --verify      # Windows
    ./install-config.sh --verify     # elsewhere

It writes nothing. It re-renders what the templates produce today, compares it
with what is actually installed, checks the link and reports a non-zero exit
code if anything is off.

## Tests

    bash tests/test-install-config.sh

Covers the rendering mechanics and the installer's guards against a rule file
outside `rules/`. It uses its own fixtures and a temporary `HOME`; it never
touches a real installation.

## Layout

    rules/common/     the rules themselves, the single source of truth
    rules/index.md    a map of the repository, deliberately NOT loaded as a rule
    templates/        one template per provider, with {{AGENTS_DIR}} and {{INCLUDE:}}
    memory/           the agents' memory store, local to the machine (gitignored)
    tests/            the installer's test suite

Rules for a professional context are not in this repository: set
`AI_INTERNAL_RULES` to an absolute path outside it, holding at least an
`index.md`. See `rules/common/internal-context.md`.
