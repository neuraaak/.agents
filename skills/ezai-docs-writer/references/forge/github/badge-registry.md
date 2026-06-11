# Badge Registry — GitHub

GitHub-specific badge templates. Combine with the language badge registry (`languages/python/badge-registry.md` or `languages/javascript/badge-registry.md`) for the full badge block.

This file is **data, not a rule**. Emit only the badges whose conditions are met. Resolve all `{placeholders}` before emitting — never leave a literal `{...}` in output.

| Variable     | Source                                         |
| :----------- | :--------------------------------------------- |
| `{owner}`    | GitHub username or org                         |
| `{repo}`     | Repository slug                                |
| `{workflow}` | CI workflow filename without `.yml`            |
| `{license}`  | License identifier (e.g. `MIT`, `Apache--2.0`) |
| `{docs_url}` | `https://{owner}.github.io/{repo}`             |

---

## Core badges (always emit for public-oss GitHub projects)

```markdown
[![CI](https://img.shields.io/github/actions/workflow/status/{owner}/{repo}/{workflow}.yml?style=flat&label=ci&logo=githubactions&logoColor=white)](https://github.com/{owner}/{repo}/actions/workflows/{workflow}.yml)
[![Docs](https://img.shields.io/badge/docs-GitHub%20Pages-blue?style=flat&logo=materialformkdocs&logoColor=white)]({docs_url}/)
[![License](https://img.shields.io/badge/license-{license}-green?style=flat&logo=github&logoColor=white)](https://github.com/{owner}/{repo}/blob/main/LICENSE)
```

**CI badge condition:** only emit when a CI workflow file exists at `.github/workflows/{workflow}.yml`. If no workflow exists, omit the badge rather than render it broken.

---

## Internal profile — static badges only

Replace core badges with static variants that don't query any live endpoint:

```markdown
[![version](https://img.shields.io/badge/version-{version}-blue?style=flat)](#)
[![license](https://img.shields.io/badge/license-Proprietary-red?style=flat)](#)
[![status](https://img.shields.io/badge/status-internal-lightgrey?style=flat)](#)
```

Tool badges (linter, type checker, etc.) remain dynamic — they link to public tool homepages, not the private registry.
