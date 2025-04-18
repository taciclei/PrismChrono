Feature: Cache IA
  Scenario: Mise en cache des prédictions IA
    Given un Cache IA initialisé
    When j'appelle get_or_compute([0.1,0.2], 3)
    Then le résultat est mis en cache
    And un second appel renvoie le même résultat sans recomputation
