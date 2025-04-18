# Blueprint BP-02-TRI : Module allocation & tests BDD

**Sprint** : 2  
**Date** : 2025-04-17  
**Objectif global** : Implémenter `free` et `status`, et valider via BDD.

## Cartographie des fichiers

| Chemin                                                      | Statut   | Responsabilité                                    | Artefact lié                        |
|-------------------------------------------------------------|:--------:|---------------------------------------------------|-------------------------------------|
| `crates/trifs24_allocator/src/lib.rs`                       | Modifier | Ajouter `free` et `status`                        | specs/allocation_model.mmd          |
| `specs/allocation_model.mmd`                                | Modifier | Diagramme mis à jour pour `free`/`status`         | specs/allocation_model.mmd          |
| `crates/trifs24_allocator/tests/features/allocation.feature`| Créer    | Scénarios BDD pour `free` et `status`             | allocation.feature                   |
| `docs/blueprints/BP-02-TRI.md`                              | Créer    | Blueprint du Sprint 2                             | BP-02-TRI                            |

## User Stories & Tâches

| US   | User Story                                                                 | Tâches à réaliser                                                |
|:----:|----------------------------------------------------------------------------|------------------------------------------------------------------|
| US1  | Je veux libérer un tricluster via `Allocator::free(idx)`                   | Implémenter `free` dans `lib.rs`                                 |
| US2  | Je veux connaître les états libres/occupés/réservés via `status()`         | Implémenter `Status` et `status()` dans `lib.rs`                |
| US3  | Je veux des scénarios BDD couvrant `free` et `status`                     | Créer `tests/features/allocation.feature`                        |
| US4  | Je veux un diagramme Mermaid mis à jour                                     | Modifier `specs/allocation_model.mmd`                            |
| US5  | Je veux le Blueprint du Sprint 2                                           | Ce fichier                                                       |

## Diagrammes & BDD

- **specs/allocation_model.mmd** : Diagramme mis à jour  
- **crates/trifs24_allocator/tests/features/allocation.feature** : Scénarios BDD

## Pipeline CI/CD AIDEX

Voir `sprints/sprint-2.md` pour le pipeline détaillé.
