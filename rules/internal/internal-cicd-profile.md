## Internal CI/CD Profile — Personal Override

This is a **personal preference** that overrides the default behavior of the
`ezai-cicd-expert` skill. The skill ships only the general default; this rule
adds the context-specific layer for my own projects without imposing it on
other users of the marketplace.

**Precedence:** when this rule applies, treat it as authoritative over the
skill's defaults — apply it _in addition and in priority_.

---

### When to apply (detect "internal pipeline" context)

Treat a project as requiring this profile when:

- Private or internal repo (no public GitHub/GitLab visibility).
- Library/package project: `pyproject.toml` or `package.json` present with a
  version field and a build backend.
- Publishing target is a **private registry** (Artifactory, GitLab Package
  Registry, internal PyPI/npm) — not PyPI or the public npm registry.
- Versioned docs hosted internally (GitLab Pages, internal S3/CDN) — not
  GitHub Pages or ReadTheDocs.

Default to the skill's public-OSS behavior when signals are mixed or absent
(e.g. public repo, PyPI in `[tool.hatch.publish]`, etc.).

---

### Context adjustments (apply on top of the skill's defaults)

**Publishing — skipped**

Publishing to a registry is **not yet operational**. Omit the publish stage
entirely. The pipeline stops at: install → CI gate → tag-sync → docs.

**Docs deploy**

- Replace GitHub Pages (`gh-pages` branch) or ReadTheDocs with the internal
  hosting target: GitLab Pages (`public/` artifact) or a dedicated S3/CDN
  upload step.
- `mike` aliases (`latest`, `vX-latest`) still apply; the push target changes.

**Secrets**

- Use repo-level or group-level CI secrets (GitHub Secrets / GitLab CI
  Variables) for registry tokens, deploy keys, and internal URLs.
- Never hardcode internal registry URLs or credentials in YAML — reference
  `${{ secrets.REGISTRY_URL }}` / `$REGISTRY_URL`.

---

### What to avoid (anti-patterns for internal context)

- **No public-registry publish steps**: do not generate `twine upload` to
  PyPI or `npm publish` without a `--registry` flag pointing internally.
- **No OIDC trusted publishing** (PyPI `id-token: write` / npm provenance):
  OIDC tokens are tied to public registries; they don't apply here.
- **No `gh-pages` branch deploy** for docs: the internal hosting flow
  (GitLab Pages or custom CDN) must be used instead.
- **No pinned public runner images** when the org mandates self-hosted
  runners: confirm runner availability before proposing `ubuntu-latest`.
- **No external action pinning from GitHub Marketplace** if the org policy
  blocks third-party actions: prefer internal mirror actions or shell steps.
- **No `GITHUB_TOKEN` for publishing**: it can't authenticate against a
  private registry — always use an explicit secret.

---

### Audit checklist additions

- [ ] No `twine upload` to PyPI or `npm publish` to public registry.
- [ ] No OIDC trusted-publishing permissions (`id-token: write`).
- [ ] Registry URL and credentials sourced from CI secrets, not hardcoded.
- [ ] Docs deploy targets internal hosting, not GitHub Pages / ReadTheDocs.
- [ ] Runner type (hosted vs self-hosted) matches org policy.
