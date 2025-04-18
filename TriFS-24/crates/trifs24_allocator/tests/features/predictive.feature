Feature: Allocation prédictive IA
  Scenario: Allocation basée sur l'historique d'accès
    Given un PredictiveAllocator initialisé
    When j'appelle predictive_alloc()
    Then il retourne 0

  Scenario: Allocation successive
    Given un PredictiveAllocator initialisé
    When j'appelle predictive_alloc() deux fois
    Then il retourne 1 à la deuxième itération
