Feature: Optimisation de l’allocateur prédictif
  Scenario: Application d’une optimisation
    Given un PredictiveAllocator initialisé
    When j’appelle optimize_predictive(10)
    Then il renvoie true
