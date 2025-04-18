Feature: Snapshot
  Scenario: Snapshot & restauration
    Given un SnapshotManager initialisé
    When j'exécute create_snapshot "v1"
    Then restore_snapshot "v1" renvoie true
