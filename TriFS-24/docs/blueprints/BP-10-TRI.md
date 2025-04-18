**Sprint** : 10  
**Date** : 2025-04-24  
**Objectif global** : Implémenter le module Metadata, l’Indexation Vectorielle, le Journal ternaire et le Snapshot/versionning.

## Cartographie des fichiers

| Chemin                                                         | Statut    | Responsabilité                           | Artefact lié               |
|----------------------------------------------------------------|:---------:|------------------------------------------|----------------------------|
| `crates/trifs24_allocator/src/metadata.rs`                    | Créer     | FNODE et attributs metadata              | specs/metadata_model.mmd   |
| `crates/trifs24_allocator/src/vector_index.rs`                | Créer     | Index vectoriel IA                       | specs/indexing_model.mmd   |
| `crates/trifs24_allocator/src/journal.rs`                     | Créer     | Journalisation des opérations            | specs/journal_model.mmd    |
| `crates/trifs24_allocator/src/snapshot.rs`                    | Créer     | Gestion des snapshots/versionning        | specs/snapshot_model.mmd   |
| `crates/trifs24_allocator/src/lib.rs`                         | Modifier  | Déclarer et exporter les modules         | –                          |
| `crates/trifs24_allocator/tests/features/metadata.feature`    | Créer     | Scénarios BDD Metadata                   | metadata.feature           |
| `crates/trifs24_allocator/tests/features/indexing.feature`    | Créer     | Scénarios BDD Index vectoriel            | indexing.feature           |
| `crates/trifs24_allocator/tests/features/journal.feature`     | Créer     | Scénarios BDD Journal                    | journal.feature            |
| `crates/trifs24_allocator/tests/features/snapshot.feature`    | Créer     | Scénarios BDD Snapshot                   | snapshot.feature           |
| `specs/metadata_model.mmd`                                    | Créer     | Diagramme modèle FNODE                   | metadata_model.mmd         |
| `specs/indexing_model.mmd`                                    | Créer     | Diagramme modèle Index vectoriel         | indexing_model.mmd         |
| `specs/journal_model.mmd`                                     | Créer     | Diagramme modèle Journal                 | journal_model.mmd          |
| `specs/snapshot_model.mmd`                                    | Créer     | Diagramme modèle Snapshot                | snapshot_model.mmd         |

## User Stories & Tâches

| US    | User Story                                                                  | Tâches à réaliser                                    |
|:-----:|------------------------------------------------------------------------------|------------------------------------------------------|
| US7   | En tant que dev, je veux gérer les métadonnées (FNODE, attributs)            | Implémenter `metadata.rs` et ses tests               |
| US8   | En tant que dev, je veux indexer des embeddings IA                           | Implémenter `vector_index.rs` et ses tests           |
| US9   | En tant que dev, je veux journaliser les opérations                          | Implémenter `journal.rs` et ses tests                |
| US10  | En tant que dev, je veux gérer les snapshots et versionner l’état            | Implémenter `snapshot.rs` et ses tests               |
| US11  | En tant que QA, je veux des scénarios BDD pour metadata, index, journal, snapshot | Créer les fichiers `.feature` correspondants    |
| US12  | En tant que PO, je veux un Blueprint documenté pour le sprint                | Rédiger `docs/blueprints/BP-10-TRI.md`               |

## Diagrammes & BDD

- **specs/metadata_model.mmd**  
- **specs/indexing_model.mmd**  
- **specs/journal_model.mmd**  
- **specs/snapshot_model.mmd**  
- **tests/features/metadata.feature**  
- **tests/features/indexing.feature**  
- **tests/features/journal.feature**  
- **tests/features/snapshot.feature**
