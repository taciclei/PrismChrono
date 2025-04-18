Feature: Journalisation
  Scenario: Journal de transaction
    Given un Journal initialisé
    When j'exécute la transaction "t1"
    Then le dernier événement journal contient "t1"
