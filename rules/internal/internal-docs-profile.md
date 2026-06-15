## Internal Documentation Profile — Personal Override

This is a **personal preference** that overrides the default (public-OSS) behavior of
the `ezai-docs-writer` / `ezai-docs-specialist-persona` skills. The skills themselves
ship only the public-OSS default; this rule re-adds the "internal/proprietary" handling
for my own projects without imposing it on other users of the marketplace.

**Precedence:** when this rule applies, treat it as authoritative over the skill's
default badge policy, README sections, and link targets — apply it _in addition and in
priority_.

---

### When to apply (detect "internal" context)

Treat a project as **internal** when repo signals point to a private/proprietary context:

- Private repo, no public registry (PyPI/npm) publication.
- Proprietary or absent license (no OSI license file).
- Corporate badge / template patterns already present.

Default to the skill's public-OSS behavior when signals are mixed or absent.

---

### README section deltas (apply on top of the skill's default README)

- **`📦 Installation`** — install from source/git only (`pip install git+{repo_url}` or
  `pip install -e .`, npm equivalent from the repo). No public-registry command.
- **`👥 Ownership`** — **add** after `📝 License`: owning team, contacts, link to
  `CODEOWNERS`. Template:

  ```markdown
  ## 👥 Ownership

  Maintained by **{owning_team}**.

  - **Code owners**: see [CODEOWNERS](.github/CODEOWNERS)
  - **Contact**: {team_channel_or_email}
  ```

- **`📝 License`** — `Proprietary` / `Internal use only` unless an OSI license is
  explicitly present.
- **`🤝 Contributing`** — internal contribution flow (branch policy, mandatory review
  via CODEOWNERS). No "fork the project".
- **`🔗 Links`** — replace PyPI/npm and public Issues with the internal repo, docs, and
  tracker URLs.

Extra README variables available in this context: `{version}` (hard-coded release
string), `{repo_url}` (clone URL), `{owning_team}`, `{team_channel_or_email}`,
`{tracker_url}`.

---

### Badge deltas

- **Omit** dynamic registry/version badges (PyPI `pypi/v`, `pypi/pyversions`,
  `pypi/status`; npm `npm/v`, `node/v`) — shields.io cannot reach private registries.
- **Replace** core badges with static variants that hit no live endpoint:

  ```markdown
  [![version](https://img.shields.io/badge/version-{version}-blue?style=flat)](#)
  [![license](https://img.shields.io/badge/license-Proprietary-red?style=flat)](#)
  [![status](https://img.shields.io/badge/status-internal-lightgrey?style=flat)](#)
  ```

- **Tool badges** (linter, formatter, type checker, test runner, etc.) remain dynamic —
  they link to public tool homepages, not the private registry.

---

### Audit checklist additions (for site audits)

- [ ] No dynamic registry/version badges.
- [ ] `👥 Ownership` section present.
- [ ] No public-registry install command.
- [ ] License is `Proprietary` / `Internal use only` unless an OSI license is present.
