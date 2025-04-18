# Blueprint BP-01-TRI : Initialisation du crate Rust TriFS-24

**Sprint** : 1  
**Date** : 2025-04-17  
**Objectif global** : Initialiser l’infrastructure Rust et définir l’architecture d’allocation ternaire.

## Cartographie des fichiers

| Chemin                                      | Statut   | Responsabilité                         | Artefact lié                |
|---------------------------------------------|:--------:|----------------------------------------|-----------------------------|
| `crates/trifs24_allocator/Cargo.toml`       | À créer  | Définir le crate Rust                  | Blueprint BP-01-TRI         |
| `crates/trifs24_allocator/src/lib.rs`       | À créer  | Module allocateur ternaire             | –                           |
| `specs/allocation_model.mmd`                | À créer  | Diagramme Mermaid du modèle d’allocation | allocation_model.mmd      |
| `ui/diag_wireframe.svg`                     | À créer  | Wireframe SVG interface diagnostic     | diag_wireframe.svg          |
| `tests/features/allocation.feature`         | À créer  | Scénarios BDD pour allocation (Rust)   | allocation.feature          |

## User Stories & Tâches

| US    | User Story                                                                 | Tâches à réaliser                                             |
|:-----:|-----------------------------------------------------------------------------|---------------------------------------------------------------|
| US1   | En tant qu’architecte, je veux un diagramme d’allocation ternaire.          | Rédiger `specs/allocation_model.mmd`                          |
| US2   | En tant que développeur, je veux initialiser le crate Rust `trifs24_allocator`. | Créer `crates/trifs24_allocator/Cargo.toml` et `src/lib.rs` |
| US3   | En tant que QA, je veux des scénarios BDD en Rust pour les états des triclusters. | Écrire `tests/features/allocation.feature`               |
| US4   | En tant que PO, je veux ce Blueprint documenté.                             | Ce fichier                                                   |
| US5   | En tant que UX, je veux un wireframe SVG pour le tableau de bord.          | Générer `ui/diag_wireframe.svg`                               |

## Diagrammes & Wireframes

- **specs/allocation_model.mmd** : Diagramme du modèle d’allocation (Mermaid)  
- **ui/diag_wireframe.svg** : Wireframe de l’interface diagnostic  

## Pipeline CI/CD AIDEX

Voir `sprints/sprint-1.md` pour le pipeline détaillé.
