# .agents

Source de vérité versionnée pour les **rules** partagées avec Claude Code.

## Contenu

- `rules/` — rules chargées par Claude Code (voir `rules/index.md` pour le routage).
- `skills/` — conservé à titre de référence historique. **Géré indépendamment**
  par ezai / le plugin marketplace : aucun script de ce repo ne le manipule.
- `install-config.cmd` / `install-config.ps1` — injecte (ou met à jour) un
  bloc balisé dans `~/.claude/CLAUDE.md` pointant vers `rules/index.md` de ce
  repo, sans jamais toucher au reste du fichier.

## Installation

1. Cloner ce repo à l'emplacement de son choix (ex: `~/.agents/`).
2. Lancer `install-config.cmd`.
3. Relancer `install-config.cmd` après chaque déplacement du clone (le chemin
   absolu injecté est recalculé à chaque exécution).

## Mise à jour

Un simple `git pull` sur le clone suffit — les rules sont lues dynamiquement
via l'`@import` généré, pas de duplication de fichiers.
