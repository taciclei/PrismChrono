Feature: Profiling de l’allocation prédictive
  Scenario: Mesure du temps d’allocation prédictive
    Given un PredictiveAllocator initialisé
    When j’exécute profile_predictive(10)
    Then le profiler renvoie un temps en millisecondes (>= 0)
