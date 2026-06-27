# phpDocumentor / Doctum — Generation & Deployment

Load this file when running the API generator, wiring multi-version, or deploying the docs site. For the canonical configs themselves (`phpdoc.dist.xml`, `doctum.php`), load `toolchain.md`.

Stack: **phpDocumentor or Doctum (API) + VitePress (prose)**, deployed to GitHub Pages.

---

## Running the generators

PHP generators read PHPDoc via static reflection — the project must `composer install` cleanly first or parsing breaks.

| Tool          | Install                                                                      | Build command                          |
| :------------ | :--------------------------------------------------------------------------- | :------------------------------------- |
| phpDocumentor | `composer require --dev phpdocumentor/phpdocumentor`, or PHAR                | `vendor/bin/phpdoc -c phpdoc.dist.xml` |
| Doctum        | PHAR: `curl -O https://doctum.long-term.support/releases/latest/doctum.phar` | `php doctum.phar update doctum.php`    |

**Run order is mandatory** — the API generator must emit `docs/api/` *before* the prose site builds, so VitePress picks up the generated reference:

```bash
vendor/bin/phpdoc -c phpdoc.dist.xml   # or: php doctum.phar update doctum.php
pnpm vitepress build docs              # prose site consumes docs/api/
```

A pure API-only project (no prose site) skips the VitePress step and publishes `docs/api/` directly.

---

## API reference (PHPDoc → HTML)

The reference is generated from PHPDoc blocks — the PHP analogue of mkdocstrings/TypeDoc. Controlling knobs:

- **phpDocumentor** — `<visibility>` in `phpdoc.dist.xml` selects which member levels appear (`public`, `protected`, `private`). Emit public + protected; hide private unless the project documents it.
- **Doctum** — filters on `@internal`; symbols tagged `@internal` are excluded. Mark the public surface `@api` and internals `@internal` in source (see `standards.md`).

Never hand-author files under `docs/api/` — they are overwritten on every build. Edit the PHPDoc source instead.

---

## Versioning

| Tool            | Mechanism                                                                                                                           |
| :-------------- | :---------------------------------------------------------------------------------------------------------------------------------- |
| Doctum          | **Built-in.** `GitVersionCollection::create(__DIR__)->addFromTags('v*')` — generates one sub-site per tag/branch, no external tool. |
| phpDocumentor   | Per-release build: bump `<version number>` and publish each release into its own subpath.                                           |
| VitePress prose | `vitepress-versioning-plugin` — see `languages/javascript/plugins-deploy.md`.                                                       |

Alias rules mirror the other languages: a `latest` alias tracks the current **stable** release; pre-releases (`alpha|beta|rc|dev`) publish their version but must **not** move `latest`.

---

## CI deployment (GitHub Pages)

The docs deploy job runs on a tag/release (or via `workflow_call`), and must:

1. **`checkout` with `fetch-depth: 0`** — Doctum's `GitVersionCollection` and VitePress `lastUpdated` need full history.
2. Set up PHP pinned (`shivammathur/setup-php@v2` with the project's `php-version` + required extensions) and `composer install --no-interaction --prefer-dist` from the committed lockfile.
3. Generate the API **before** the prose build: `vendor/bin/phpdoc` (or `php doctum.phar update`), then `pnpm run docs:build` if a VitePress prose site exists.
4. Upload with `actions/upload-pages-artifact` and deploy via `actions/deploy-pages`.

Grant only `pages: write` + `id-token: write` on the deploy job (workflow default `permissions: {}`); pin the runner image (`ubuntu-24.04`) and every action. See the `ezai-cicd-expert` skill (`languages/php/`) for the full pipeline.

---

## Anti-patterns

| Anti-pattern                                     | Problem                                        | Fix                                                  |
| :----------------------------------------------- | :--------------------------------------------- | :--------------------------------------------------- |
| Building docs before `composer install`          | Static reflection fails on unresolved autoload | Install dependencies first                           |
| Disabling the cache dir                          | Slow rebuilds on every run                     | Keep `cache` / `cache_dir` set (Doctum's diff cache) |
| Hand-editing files under `docs/api/`             | Overwritten on next generation                 | Edit the PHPDoc source                               |
| Building prose before the API generator runs     | Stale or missing API reference                 | Run phpDocumentor/Doctum before `vitepress build`    |
| Pre-release moves the `latest` alias             | Users pulled onto an unstable build            | Publish the version only; leave `latest` in place    |
| Exposing private members in the public reference | Leaks internals into the contract              | Scope `<visibility>` / tag `@internal`               |
| `checkout` without `fetch-depth: 0`              | Doctum Git versions / `lastUpdated` break      | Fetch full history                                   |
