Feature: Gestion d'erreurs
  Scenario: Erreur d'allocation
    Given un Allocator initialisé avec 0 tricluster
    When j'appelle allocate()
    Then la méthode retourne une erreur "OutOfSpace"

  Scenario: Erreur de libération invalide
    Given un Allocator initialisé avec 1 tricluster
    When j'appelle free(1)
    Then la méthode retourne une erreur "InvalidIndex"
