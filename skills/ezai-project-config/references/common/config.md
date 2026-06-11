# Config & Infrastructure — Principes transversaux

Ces principes s'appliquent quelle que soit la langue. Charger avec le fichier langue correspondant.

## Règles fondamentales

- **Lockfiles** : toujours committer les lockfiles (`uv.lock`, `pnpm-lock.yaml`) pour des builds reproductibles.
- **Docker** : builds multi-stage — séparer les dépendances build-time de l'image runtime. Utilisateur non-root en production.
- **Observabilité** : OpenTelemetry pour le tracing, les métriques et les logs structurés. Sortie JSON.
- **Health checks** : définir `HEALTHCHECK` dans Docker pour la conscience d'orchestration.
- **Jamais `latest`** dans Docker — épingler les tags exacts.

## Gestion des secrets & variables d'environnement

- **Jamais de secrets dans le repo** : pas de clés API, tokens ou mots de passe en clair dans le code ou les fichiers de config.
- `.env` en local uniquement — toujours dans `.gitignore`.
- En CI/CD : injecter via les secrets de la plateforme (GitHub Actions secrets, Vault, etc.).
- Valider les env vars au démarrage — fail fast si une variable requise est absente.

```bash
# Pattern de validation au démarrage (shell)
: "${DATABASE_URL:?DATABASE_URL is required}"
: "${API_KEY:?API_KEY is required}"
```

## Monorepo tooling

| Outil  | Commande workspace                                    |
| :----- | :---------------------------------------------------- |
| `pnpm` | `pnpm -r run build` / `pnpm --filter <pkg> add <dep>` |
| `uv`   | `uv sync --all-packages` / `uv run -p <pkg> pytest`   |

- Définir les packages workspace dans `pnpm-workspace.yaml` (JS) ou `[tool.uv.workspace]` (Python).
- Partager les configs linter à la racine ; les packages héritent via `extends`.

## Anti-patterns à éviter

| Anti-pattern                                  | Problème                       | Correction                                              |
| :-------------------------------------------- | :----------------------------- | :------------------------------------------------------ |
| Secret en dur dans le code                    | Exposition dans le repo / logs | Variable d'environnement + vault                        |
| `latest` tag Docker                           | Build non reproductible        | Tag exact (`node:24.1.0-alpine`)                        |
| Config outil dans plusieurs fichiers          | Source de vérité fragmentée    | Tout centraliser dans `pyproject.toml` / `package.json` |
| `pnpm install` sans `--frozen-lockfile` en CI | Lockfile silently mis à jour   | Toujours `--frozen-lockfile` en CI                      |
| Dépendances dev dans l'image runtime          | Image gonflée                  | Multi-stage, copier uniquement l'artefact               |
