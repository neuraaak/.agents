# Badge Registry — GitLab

GitLab-specific badge templates. Combine with the language badge registry (`python/badge-registry.md` or `javascript/badge-registry.md`) for the full badge block.

This file is **data, not a rule**. Emit only the badges whose conditions are met. Resolve all `{placeholders}` before emitting — never leave a literal `{...}` in output.

| Variable     | Source                                         |
| :----------- | :--------------------------------------------- |
| `{owner}`    | GitLab username or namespace                   |
| `{repo}`     | Repository slug                                |
| `{license}`  | License identifier (e.g. `MIT`, `Apache--2.0`) |
| `{docs_url}` | `https://{owner}.gitlab.io/{repo}`             |

---

## Core badges (always emit for public-oss GitLab projects)

```markdown
[![CI](https://img.shields.io/gitlab/pipeline-status/{owner}/{repo}?branch=main&style=flat&logo=gitlab&logoColor=white)](https://gitlab.com/{owner}/{repo}/-/pipelines)
[![Docs](https://img.shields.io/badge/docs-GitLab%20Pages-blue?style=flat&logo=gitlab&logoColor=white)]({docs_url}/)
[![License](https://img.shields.io/badge/license-{license}-green?style=flat&logo=gitlab&logoColor=white)](https://gitlab.com/{owner}/{repo}/-/blob/main/LICENSE)
```

**CI badge condition:** only emit when a `.gitlab-ci.yml` exists. If absent, omit.

---

## Internal profile — static badges only

Replace core badges with static variants:

```markdown
[![version](https://img.shields.io/badge/version-{version}-blue?style=flat)](#)
[![license](https://img.shields.io/badge/license-Proprietary-red?style=flat)](#)
[![status](https://img.shields.io/badge/status-internal-lightgrey?style=flat)](#)
```

Tool badges remain dynamic — they link to public tool homepages.
