# Architecture & Design — Principes transversaux

Ces principes s'appliquent quelle que soit la langue. Charger avec le fichier langue correspondant.

## Règles fondamentales

- **Composition over inheritance** — préférer des unités petites et composables aux hiérarchies de classes profondes.
- **Surface publique explicite** — toujours définir ce qui est public et ce qui est interne.
- **Ports & Adapters** — appliquer quand une frontière de module croise un système externe (DB, API, message queue, filesystem) ; définir les contrats comme interfaces structurelles, pas des classes de base.
- **Repository pattern** — abstraire tout accès aux données derrière une interface repository ; la business logic n'importe jamais directement un driver DB.
- **Modules feature-based** — organiser par domaine métier (`user/`), pas par type technique (`models/` + `controllers/`).

## Watchguard — Hexagonal vs Simple Layered

Avant de proposer une architecture hexagonale, évaluer ces 4 critères. Si le score est ≤ 2, recommander **Simple Layered** à la place.

| Critère                                                                       | Score |
| :---------------------------------------------------------------------------- | :---: |
| Le projet a ≥ 2 systèmes externes distincts (DB + API + queue…)               |  +1   |
| La business logic doit être testable sans infrastructure                      |  +1   |
| Des adaptateurs alternatifs sont prévus (ex: SQLite en dev, Postgres en prod) |  +1   |
| Le projet dépasse ~1 000 lignes ou 3 développeurs                             |  +1   |

- **Score ≥ 3** → Hexagonal (Ports & Adapters)
- **Score ≤ 2** → Simple Layered (`models/` + `services/` + `repositories/` à plat)

Ne jamais sur-architecturer un script ou un prototype — l'overhead d'Hexagonal nuit à la lisibilité sur les petits projets.

## Simple Layered — structure

```text
src/
├── models/       ← Entités & Value Objects
├── repositories/ ← Accès données (une interface + une implémentation)
└── services/     ← Business logic
```

## Hexagonal — structure

```text
src/
├── domain/          ← Entités, Value Objects (zéro imports externes)
├── application/     ← Use Cases + Ports (interfaces)
└── infrastructure/  ← Adapters (DB, APIs) + Composition Root
```

Règle de dépendance : **toujours vers l'intérieur** — Infrastructure → Application → Domain.

## Anti-patterns à éviter

| Anti-pattern                | Symptôme                                                                  | Correction                                                 |
| :-------------------------- | :------------------------------------------------------------------------ | :--------------------------------------------------------- |
| **Anemic Domain Model**     | Les entités n'ont que des getters/setters, la logic est dans les services | Déplacer la logic métier dans les entités                  |
| **God Object**              | Une classe fait tout (15+ méthodes, responsabilités mixtes)               | Décomposer par Single Responsibility                       |
| **Dépendances circulaires** | Module A importe B qui importe A                                          | Extraire une interface partagée, ou inverser la dépendance |
| **Primitive Obsession**     | `user_id: int`, `order_id: int` — sémantique perdue                       | Branded/opaque types ou Value Objects                      |
| **Fuite d'infrastructure**  | Un driver SQL importé dans un Use Case                                    | Repository pattern — le Use Case ne connaît que le Port    |
