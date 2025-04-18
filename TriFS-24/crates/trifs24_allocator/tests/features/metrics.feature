Feature: Metrics
  Scenario: Compteur d'allocations
    Given un compteur remis à zéro
    When j'appelle `allocate()` trois fois
    Then la métrique `allocator_alloc_total` vaut 3
