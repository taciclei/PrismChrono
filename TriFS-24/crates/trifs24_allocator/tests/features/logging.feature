Feature: Logging
  Scenario: Niveau DEBUG
    Given un module initialisé
    When j'appelle `predictive_alloc()`
    Then on logge un message DEBUG contenant "predictive_alloc"
