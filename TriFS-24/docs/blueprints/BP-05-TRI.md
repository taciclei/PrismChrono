# Blueprint BP-05-TRI : Sécurité avancée & snapshots

**Sprint** : 5  
**Date** : 2025-04-17  
**Objectif global** : Implémenter checksums, snapshots & chiffrement stub.

## Cartographie des fichiers

| Chemin                                                          | Statut   | Responsabilité                     | Artefact lié               |
|-----------------------------------------------------------------|:--------:|------------------------------------|----------------------------|
| `crates/trifs24_allocator/src/checksum.rs`                     | Créer    | Module checksum                    | specs/checksum_model.mmd   |
| `crates/trifs24_allocator/src/snapshot.rs`                     | Créer    | Module snapshot/versioning         | specs/snapshot_model.mmd   |
| `crates/trifs24_allocator/src/crypto.rs`                       | Créer    | Stub chiffrement bloc par bloc     | specs/crypto_model.mmd     |
| `crates/trifs24_allocator/src/lib.rs`                          | Modifier | `mod checksum; snapshot; crypto; pub use ...` | –           |
| `specs/checksum_model.mmd`                                     | Créer    | Diagramme modèle Checksum          | checksum_model.mmd         |
| `specs/snapshot_model.mmd`                                     | Créer    | Diagramme modèle SnapshotManager   | snapshot_model.mmd         |
| `specs/crypto_model.mmd`                                       | Créer    | Diagramme modèle Crypto            | crypto_model.mmd           |
| `crates/trifs24_allocator/tests/features/checksum.feature`     | Créer    | Scénarios BDD checksum             | checksum.feature           |
| `crates/trifs24_allocator/tests/features/snapshot.feature`     | Créer    | Scénarios BDD snapshot             | snapshot.feature           |
| `crates/trifs24_allocator/tests/features/crypto.feature`       | Créer    | Scénarios BDD chiffrement          | crypto.feature             |

## User Stories & Tâches

| US   | User Story                                                       | Tâches à réaliser                               |
|:----:|------------------------------------------------------------------|--------------------------------------------------|
| US1  | Calcul et vérification de checksum ternaire                      | Implémenter `compute_checksum` et `verify_checksum` |
| US2  | Création et restauration de snapshots                            | Implémenter `SnapshotManager`                     |
| US3  | Chiffrement/déchiffrement bloc par bloc stub                     | Implémenter `encrypt_block` et `decrypt_block`     |
| US4  | Scénarios BDD pour checksum et snapshots                         | Créer `checksum.feature` et `snapshot.feature`     |
| US5  | Scénarios BDD pour chiffrement                                   | Créer `crypto.feature`                            |
| US6  | Blueprint documenté                                              | Ce fichier                                       |

## Diagrammes & BDD

- **specs/checksum_model.mmd**  
- **specs/snapshot_model.mmd**  
- **specs/crypto_model.mmd**    
- **tests/features/checksum.feature**  
- **tests/features/snapshot.feature**  
- **tests/features/crypto.feature**
