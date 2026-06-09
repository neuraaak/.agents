## Memory — règle de mise à jour

Lorsque tu mets à jour la mémoire d'un projet (auto-memory), tu dois :

1. Écrire dans le dossier mémoire habituel du projet (`~/.claude/projects/<projet>/memory/` via les outils Write/Edit).

2. **En plus**, invoquer le skill `remember` (via `Skill tool` avec `skill: "remember"`) pour synchroniser la même information dans le scope projet.
